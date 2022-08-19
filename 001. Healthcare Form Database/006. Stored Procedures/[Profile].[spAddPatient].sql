USE [HealthcareForm]
GO

/****** Object:  StoredProcedure [Profile].[spAddPatient]    Script Date: 18-Aug-22 08:29:11 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO













ALTER       PROC [Profile].[spAddPatient]
(
	@FirstName VARCHAR(250) = '',
	@LastName VARCHAR(250) = '',
	@ID_Number VARCHAR(250) = '',
	@DateOfBirth DATETIME ,
	@GenderIDFK INT = 0,
	@PhoneNumber VARCHAR(250) = '',
	@Email VARCHAR(250) = '',
	@Line1 VARCHAR(250) = '',
	@Line2 VARCHAR(250) = '',
	@CityIDFK INT = 0,
	@ProvinceIDFK INT = 0,
	@CountryIDFK INT = 0,
	@MaritalStatusIDFK INT = 0,
	@EmergencyName VARCHAR(250) = '',
	@EmergencyLastName VARCHAR(250) = '',
	@EmergencyPhoneNumber varchar(250) = '',
	@Relationship VARCHAR(250) = '',
	@EmergancyDateOfBirth DATETIME,
	@MedicationList VARCHAR(MAX) = '',
	@Message VARCHAR(250) OUTPUT
)
AS
BEGIN
	
	-- Default variables
	DECLARE @IsActive BIT = 0,
			@DefaultDate DATETIME = GETDATE(),
			@EmailIDFK UNIQUEIDENTIFIER = NEWID(),
			@PhoneIDFK UNIQUEIDENTIFIER = NEWID(),
			@AddressIDFK UNIQUEIDENTIFIER = NEWID(),
			@EmergencyIDFK UNIQUEIDENTIFIER = NEWID(),
			@UserName VARCHAR(200),
			@ErrorSchema VARCHAR(200),
			@ErrorProc VARCHAR(200),
			@ErrorNumber INT,
			@ErrorState INT,
			@ErrorSeverity INT,
			@ErrorLine INT,
			@ErrorMessage VARCHAR(200),
			@ErrorDateTime DATETIME

SET NOCOUNT ON
	
	/*Summary*/
	/*Inserting all the details into the Patient table */

	/*ID number is the user authantification key */

	BEGIN TRY
	
	BEGIN TRAN

		IF NOT EXISTS(SELECT 1 FROM Profile.Patient WITH(NOLOCK) WHERE ID_Number = @ID_Number AND ID_Number != null) 
		BEGIN
			
			SET @IsActive = 1

			--INSERT INTO EMAILS TABLE 
			INSERT INTO Contacts.Emails
			(
				EmailId,
				Email, 
				IsActive, 
				UpdateDate
			)
			VALUES(@EmailIDFK, @Email, @IsActive, @DefaultDate)

			--INSERT INTO PHONES TABLE
			INSERT INTO Contacts.Phones
			(
				PhoneId,
				PhoneNumber, 
				IsActive, 
				UpdateDate
			)
			VALUES(@PhoneIDFK, Contacts.FormatPhoneNumber(@PhoneNumber), @IsActive, @DefaultDate)

			--INSERT INTO ADDRESS TABLE 
			INSERT INTO Location.Address
			(
				AddressId,
				Line1, 
				Line2, 
				CityIDFK
			)
			VALUES(@AddressIDFK, @Line1, dbo.CapitalizeFirstLetter(@Line2), @CityIDFK) 


			--INSERT INTO EMERGENCY CONTACTS
			INSERT INTO Contacts.EmergencyContacts
			(
				EmergencyId,
				FirstName, 
				LastName, 
				PhoneNumber,
				Relationship, 
				DateOfBirth,
				IsActive, 
				UpdateDate
			)
			VALUES(@EmergencyIDFK, dbo.CapitalizeFirstLetter(@EmergencyName), dbo.CapitalizeFirstLetter(@EmergencyLastName), Contacts.FormatPhoneNumber(@EmergencyPhoneNumber) ,dbo.CapitalizeFirstLetter(@Relationship) , @EmergancyDateOfBirth , @IsActive, @DefaultDate)


			--INSERT PATIENT TABLE
			INSERT INTO Profile.Patient
			(
				FirstName, 
				LastName, 
				ID_Number,
				DateOfBirth, 
				GenderIDFK, 
				MedicationList, 
				EmailIDFK, 
				PhoneIDFK, 
				AddressIDFK, 
				MaritalStatusIDFK, 
				EmergencyIDFK
			)
			VALUES(dbo.CapitalizeFirstLetter(@FirstName), dbo.CapitalizeFirstLetter(@LastName), @ID_Number ,@DateOfBirth, @GenderIDFK, dbo.CapitalizeFirstLetter(@MedicationList), @EmailIDFK, @PhoneIDFK, @AddressIDFK, @MaritalStatusIDFK, @EmergencyIDFK)

			SET @Message = ''

			COMMIT TRAN

		END ELSE 
		BEGIN
			-- Rollback the transaction
			ROLLBACK TRAN

			-- Get error message
			SET @Message = 'Sorry User ID Number: "'+ @ID_Number + '" Already exists, Please validate and try again'

			-- Pass default data into parameters
			SET	@FirstName  = ''
			SET @LastName = ''
			SET @ID_Number = ''
			SET @DateOfBirth = @DefaultDate
			SET @GenderIDFK = 0
			SET @PhoneNumber = ''
			SET @Email = ''
			SET @Line1 = ''
			SET @Line2 = ''
			SET @CityIDFK = 0
			SET @ProvinceIDFK = 0
			SET @CountryIDFK = 0
			SET @MaritalStatusIDFK = 0
			SET @MedicationList = ''
			SET @EmergencyName = ''
			SET @EmergancyDateOfBirth = @DefaultDate
			SET @EmergencyLastName = ''
			SET @Relationship = ''


		END
	END TRY 
	BEGIN CATCH
		
		-- Roll back transaction
		ROLLBACK TRAN
		
		-- Pass error data into the DB_Errors Table 
		SET	@UserName = SUSER_SNAME()
		SET	@ErrorSchema = SCHEMA_NAME()
		SET @ErrorProc = ERROR_PROCEDURE()
		SET @ErrorNumber = ERROR_NUMBER()
		SET @ErrorState = ERROR_STATE()
		SET @ErrorSeverity = ERROR_SEVERITY()
		SET @ErrorLine = ERROR_LINE()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @ErrorDateTime = GETDATE()
		
		EXEC [Auth].[spDB_Errors] @UserName,@ErrorSchema, @ErrorProc, @ErrorNumber, @ErrorState, @ErrorSeverity, @ErrorLine, @ErrorMessage, @ErrorDateTime

	END CATCH

SET NOCOUNT OFF
END
GO


