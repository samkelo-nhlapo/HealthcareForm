USE [HealthcareForm]
GO

/****** Updated StoredProcedure: [Profile].[spAddPatient] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spAddPatient]
(
	@FirstName VARCHAR(250),
	@LastName VARCHAR(250),
	@ID_Number VARCHAR(250),
	@DateOfBirth DATETIME,
	@GenderIDFK INT,
	@PhoneNumber VARCHAR(250),
	@Email VARCHAR(250),
	@Line1 VARCHAR(250),
	@Line2 VARCHAR(250),
	@CityIDFK INT,
	@MaritalStatusIDFK INT,
	@EmergencyName VARCHAR(250),
	@EmergencyLastName VARCHAR(250),
	@EmergencyPhoneNumber VARCHAR(250),
	@Relationship VARCHAR(250),
	@EmergencyDateOfBirth DATETIME,
	@MedicationList VARCHAR(MAX),
	@PatientId UNIQUEIDENTIFIER OUTPUT,
	@Message VARCHAR(500) OUTPUT
)
AS
BEGIN
	
	-- Default variables
	DECLARE @IsActive BIT = 1,
			@DefaultDate DATETIME = GETDATE(),
			@EmailIDFK UNIQUEIDENTIFIER = NEWID(),
			@PhoneIDFK UNIQUEIDENTIFIER = NEWID(),
			@AddressIDFK UNIQUEIDENTIFIER = NEWID(),
			@EmergencyIDFK UNIQUEIDENTIFIER = NEWID(),
			@UserName VARCHAR(200) = SYSTEM_USER,
			@ErrorSchema VARCHAR(200),
			@ErrorProc VARCHAR(200),
			@ErrorNumber INT,
			@ErrorState INT,
			@ErrorSeverity INT,
			@ErrorLine INT,
			@ErrorMessage VARCHAR(500),
			@ErrorDateTime DATETIME;

	SET NOCOUNT ON
	
	/*Summary: Inserts all details into the Patient table and related contact tables*/
	/*ID_Number is the unique identification key for patient authentication*/

	BEGIN TRY
	
		BEGIN TRAN

			-- Validate input data
			IF @FirstName IS NULL OR LEN(RTRIM(@FirstName)) = 0
			BEGIN
				SET @Message = 'First Name is required';
				RAISERROR(@Message, 16, 1);
			END

			IF @LastName IS NULL OR LEN(RTRIM(@LastName)) = 0
			BEGIN
				SET @Message = 'Last Name is required';
				RAISERROR(@Message, 16, 1);
			END

			IF @ID_Number IS NULL OR LEN(RTRIM(@ID_Number)) = 0
			BEGIN
				SET @Message = 'ID Number is required';
				RAISERROR(@Message, 16, 1);
			END

			-- Validate email format
			IF @Email IS NOT NULL AND LEN(RTRIM(@Email)) > 0
			BEGIN
				IF dbo.ValidateEmail(@Email) = 0
				BEGIN
					SET @Message = 'Invalid email format';
					RAISERROR(@Message, 16, 1);
				END
			END

			-- Check if patient with same ID already exists
			IF EXISTS(SELECT 1 FROM Profile.Patient WITH(NOLOCK) WHERE ID_Number = @ID_Number AND IsDeleted = 0) 
			BEGIN
				SET @Message = 'Patient with this ID Number already exists';
				RAISERROR(@Message, 16, 1);
			END

			-- Generate patient ID
			SET @PatientId = NEWID();

			-- INSERT INTO EMAILS TABLE (only if provided)
			IF @Email IS NOT NULL AND LEN(RTRIM(@Email)) > 0
			BEGIN
				INSERT INTO Contacts.Emails
				(
					EmailId,
					Email, 
					IsActive, 
					UpdateDate,
					CreatedDate,
					CreatedBy
				)
				VALUES(@EmailIDFK, @Email, @IsActive, @DefaultDate, @DefaultDate, @UserName);
			END

			-- INSERT INTO PHONES TABLE (only if provided)
			IF @PhoneNumber IS NOT NULL AND LEN(RTRIM(@PhoneNumber)) > 0
			BEGIN
				INSERT INTO Contacts.Phones
				(
					PhoneId,
					PhoneNumber, 
					IsActive, 
					UpdateDate,
					CreatedDate,
					CreatedBy
				)
				VALUES(@PhoneIDFK, Contacts.FormatPhoneNumber(@PhoneNumber), @IsActive, @DefaultDate, @DefaultDate, @UserName);
			END

			-- INSERT INTO ADDRESS TABLE (only if provided)
			IF @Line1 IS NOT NULL AND LEN(RTRIM(@Line1)) > 0
			BEGIN
				INSERT INTO Location.Address
				(
					AddressId,
					Line1, 
					Line2, 
					CityIDFK,
					UpdateDate,
					CreatedDate,
					CreatedBy
				)
				VALUES(@AddressIDFK, @Line1, dbo.CapitalizeFirstLetter(@Line2), @CityIDFK, @DefaultDate, @DefaultDate, @UserName);
			END

			-- INSERT INTO EMERGENCY CONTACTS TABLE (only if provided)
			IF @EmergencyName IS NOT NULL AND LEN(RTRIM(@EmergencyName)) > 0
			BEGIN
				INSERT INTO Contacts.EmergencyContacts
				(
					EmergencyId,
					FirstName,
					LastName,
					PhoneNumber,
					Relationship,
					DateOfBirth,
					CreatedDate,
					CreatedBy
				)
				VALUES(@EmergencyIDFK, @EmergencyName, @EmergencyLastName, Contacts.FormatPhoneNumber(@EmergencyPhoneNumber), @Relationship, @EmergencyDateOfBirth, @DefaultDate, @UserName);
			END

			-- INSERT INTO PATIENT TABLE
			INSERT INTO Profile.Patient
			(
				PatientId,
				FirstName,
				LastName,
				ID_Number,
				DateOfBirth,
				GenderIDFK,
				MedicationList,
				AddressIDFK,
				MaritalStatusIDFK,
				EmergencyIDFK,
				IsDeleted,
				CreatedDate,
				CreatedBy,
				UpdatedDate,
				UpdatedBy
			)
			VALUES(
				@PatientId,
				dbo.CapitalizeFirstLetter(@FirstName),
				dbo.CapitalizeFirstLetter(@LastName),
				@ID_Number,
				@DateOfBirth,
				@GenderIDFK,
				@MedicationList,
				CASE WHEN @AddressIDFK = NEWID() THEN NULL ELSE @AddressIDFK END,
				@MaritalStatusIDFK,
				CASE WHEN @EmergencyIDFK = NEWID() THEN NULL ELSE @EmergencyIDFK END,
				0,
				@DefaultDate,
				@UserName,
				@DefaultDate,
				@UserName
			);

			-- Link email to patient through junction table
			IF @EmailIDFK IS NOT NULL
			BEGIN
				INSERT INTO Contacts.PatientEmails
				(
					PatientIdFK,
					EmailIdFK,
					IsPrimary,
					CreatedDate,
					CreatedBy,
					UpdatedDate,
					UpdatedBy
				)
				VALUES(@PatientId, @EmailIDFK, 1, @DefaultDate, @UserName, @DefaultDate, @UserName);
			END

			-- Link phone to patient through junction table
			IF @PhoneIDFK IS NOT NULL
			BEGIN
				INSERT INTO Contacts.PatientPhones
				(
					PatientIdFK,
					PhoneIdFK,
					IsPrimary,
					CreatedDate,
					CreatedBy,
					UpdatedDate,
					UpdatedBy
				)
				VALUES(@PatientId, @PhoneIDFK, 1, @DefaultDate, @UserName, @DefaultDate, @UserName);
			END

			SET @Message = 'Patient added successfully with ID: ' + CAST(@PatientId AS VARCHAR(50));

		COMMIT TRAN

	END TRY
	BEGIN CATCH

		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;

		SET @ErrorNumber = ERROR_NUMBER();
		SET @ErrorSeverity = ERROR_SEVERITY();
		SET @ErrorState = ERROR_STATE();
		SET @ErrorLine = ERROR_LINE();
		SET @ErrorMessage = ERROR_MESSAGE();
		SET @ErrorSchema = 'Profile';
		SET @ErrorProc = 'spAddPatient';
		SET @ErrorDateTime = GETDATE();

		-- Log error to audit table
		INSERT INTO Auth.DB_Errors
		(
			ErrorNumber,
			ErrorSeverity,
			ErrorState,
			ErrorLine,
			ErrorMessage,
			ErrorSchema,
			ErrorProc,
			ErrorDateTime
		)
		VALUES(@ErrorNumber, @ErrorSeverity, @ErrorState, @ErrorLine, @ErrorMessage, @ErrorSchema, @ErrorProc, @ErrorDateTime);

		SET @Message = 'Error: ' + @ErrorMessage;
		RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

	END CATCH

	SET NOCOUNT OFF

END;
GO
