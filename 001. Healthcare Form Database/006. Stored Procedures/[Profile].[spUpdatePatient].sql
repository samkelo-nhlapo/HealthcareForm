USE HealthcareForm
GO

/****** Object:  StoredProcedure [Profile].[spUpdatePatient]    Script Date: 14-Jun-22 10:58:53 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE OR ALTER PROC [Profile].[spUpdatePatient]
(
	@FirstName VARCHAR(250) = '',
	@LastName VARCHAR(250) = '',
	@ID_Number VARCHAR(250) = '',
	@DateOfBirth DATETIME = '2022-06-03 12:55:33.680',
	@GenderIDFK INT = 0,
	
	@PhoneNumber VARCHAR(250) = '',
	@Email VARCHAR(250) = '',
	@Line1 VARCHAR(250) = '',
	@Line2 VARCHAR(250) = '',
	@CityIDFK INT = 0,
	
	@ProvinceIDFK INT = 0,
	@CountryIDFK INT = 0,
	@MaritalStatusIDFK INT = 0,
	@MedicationList VARCHAR(MAX) = '',
	@EmergencyName VARCHAR(250) = '',
	
	@EmergencyLastName VARCHAR(250) = '',
	@EmergencyPhoneNumber varchar(250) = '',
	@Relationship VARCHAR(250) = '',
	@EmergancyDateOfBirth DATETIME = '2022-06-03 12:55:33.680',

	@Message VARCHAR(250) OUTPUT 
)
AS
BEGIN

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
	BEGIN TRAN	
		BEGIN TRY
	
			--CHECK IF ID NUMBER EXISTS IN THE DATABASE
			IF EXISTS(SELECT 1 FROM Profile.Patient WITH(NOLOCK) WHERE ID_Number = @ID_Number)
			BEGIN
				
				INSERT INTO Contacts.Phones
				(
					PhoneId,
					PhoneNumber,
					IsActive,
					UpdateDate
				)
				VALUES(@PhoneIDFK, @PhoneNumber, @IsActive, @DefaultDate)
	
				INSERT INTO Contacts.Emails
				(
					EmailId,
					Email,
					IsActive,
					UpdateDate
				)
				VALUES(@EmailIDFK, @Email, @IsActive, @DefaultDate)
	
				INSERT INTO Location.Address
				(
					AddressId,
					Line1,
					Line2,
					CityIDFK
				)
				VALUES(@AddressIDFK, @Line1, @Line2, @CityIDFK)
	
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
				VALUES(@EmergencyIDFK, @EmergencyName, @EmergencyLastName, @EmergencyPhoneNumber, @Relationship, @EmergancyDateOfBirth, @IsActive, @DefaultDate)
	
				UPDATE Profile.Patient
				SET FirstName = @FirstName,
					LastName = @LastName,
					DateOfBirth = @DateOfBirth,
					GenderIDFK = @GenderIDFK,
					MedicationList = @MedicationList,
					EmailIDFK = @EmailIDFK,
					PhoneIDFK = @PhoneIDFK,
					AddressIDFK = @AddressIDFK,
					MaritalStatusIDFK = @MaritalStatusIDFK,
					EmergencyIDFK = @EmergencyIDFK
				WHERE ID_Number = @ID_Number
			
			COMMIT TRAN
			END ELSE
			BEGIN
	
				SET @Message = 'Sorry User [' + @ID_Number + '] does not exists, please varify and try again'
				
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
				SET @EmergencyLastName = ''
				SET @Relationship = ''
			
			ROLLBACK TRAN
			
			END
			
		END TRY
		BEGIN CATCH
	
			ROLLBACK TRAN

			SET	@UserName = SUSER_SNAME()
			SET	@ErrorSchema = SCHEMA_NAME()
			SET @ErrorProc = ERROR_PROCEDURE()
			SET @ErrorNumber = ERROR_NUMBER()
			SET @ErrorState = ERROR_STATE()
			SET @ErrorSeverity = ERROR_SEVERITY()
			SET @ErrorLine = ERROR_LINE()
			SET @ErrorMessage = ERROR_MESSAGE()
			SET @ErrorDateTime = GETDATE()
	
			EXEC [Auth].[Exception] @UserName,@ErrorSchema, @ErrorProc, @ErrorNumber, @ErrorState, @ErrorSeverity, @ErrorLine, @ErrorMessage, @ErrorDateTime
	
		END CATCH
	
	SET NOCOUNT OFF
END
GO


