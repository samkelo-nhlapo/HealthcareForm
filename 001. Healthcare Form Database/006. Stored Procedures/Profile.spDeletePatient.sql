USE PatientEnrollment
GO

CREATE PROC Profile.spDeletePatient
(
	@IDNumber VARCHAR(250),
	@FirstName VARCHAR(250) OUTPUT,
	@LastName VARCHAR(250) OUTPUT,
	@ID_Number VARCHAR(250) OUTPUT,
	@DateOfBirth DATETIME OUTPUT,
	@GenderIDFK INT OUTPUT,
	
	@PhoneNumber VARCHAR(250) OUTPUT,
	@Email VARCHAR(250) OUTPUT,
	@Line1 VARCHAR(250) OUTPUT,
	@Line2 VARCHAR(250) OUTPUT,
	@CityIDFK INT OUTPUT,
	
	@ProvinceIDFK INT OUTPUT,
	@CountryIDFK INT OUTPUT,
	@MaritalStatusIDFK VARCHAR(250) OUTPUT,
	@MedicationList VARCHAR(MAX) OUTPUT,
	@EmergencyName VARCHAR(250) OUTPUT,
	
	@EmergencyLastName VARCHAR(250) OUTPUT,
	@EmergencyPhoneNumber varchar(250) OUTPUT,
	@Relationship VARCHAR(250) OUTPUT,
	@EmergancyDateOfBirth DATETIME OUTPUT,
	
	@Message VARCHAR(250) OUTPUT
)
AS
BEGIN

	DECLARE @UserName VARCHAR(200),
			@ErrorSchema VARCHAR(200),
			@ErrorProc VARCHAR(200),
			@ErrorNumber INT,
			@ErrorState INT,
			@ErrorSeverity INT,
			@ErrorLine INT,
			@ErrorMessage VARCHAR(200),
			@ErrorDateTime DATETIME

	SET NOCOUNT ON

	BEGIN TRY

		IF EXISTS(SELECT 1 FROM Profile.Patient WHERE ID_Number = @IDNumber)
		BEGIN
			
			

			--SELECT  @FirstName = PP.FirstName,
			--		@LastName = PP.LastName,
			--		@ID_Number = PP.ID_Number,
			--		@DateOfBirth = pp.DateOfBirth,
			--		@GenderIDFK = PG.GenderId,
			--		@PhoneNumber = CP.PhoneNumber,
			--		@Email = CE.Email, 
			--		@Line1 = LA.Line1,
			--		@Line2 = LA.Line2,
			--		@CityIDFK = LC.CityId,
			--		@ProvinceIDFK = LP.ProvinceId,
			--		@CountryIDFK = LCO.CountryId,
			--		@MaritalStatusIDFK = PM.MaritalStatusId,
			--		@MedicationList = pp.MedicationList,
			--		@EmergencyName = CEC.FirstName,
			--		@EmergencyLastName = CEC.LastName,
			--		@EmergencyPhoneNumber = CEC.PhoneNumber,
			--		@Relationship = CEC.Relationship,
			--		@EmergancyDateOfBirth = CEC.DateOfBirth
			--FROM Profile.Patient AS PP 
			--INNER JOIN Profile.Gender AS PG ON PP.GenderIDFK = PG.GenderId
			--	INNER JOIN Contacts.Phones AS CP ON PP.PhoneIDFK = CP.PhoneId
			--		INNER JOIN Contacts.Emails AS CE ON PP.EmailIDFK = CE.EmailId
			--			INNER JOIN Location.Address AS LA ON PP.AddressIDFK = LA.AddressId
			--				INNER JOIN Location.Cities AS LC ON LA.CityIDFK = LC.CityId
			--					INNER JOIN Location.Provinces AS LP ON LC.ProvinceIDFK = LP.ProvinceId
			--						INNER JOIN Location.Countries AS LCO ON LP.CountryIDFK = LCO.CountryId
			--							INNER JOIN Profile.MaritalStatus AS PM ON PP.MaritalStatusIDFK = PM.MaritalStatusId
			--								INNER JOIN Contacts.EmergencyContacts AS CEC ON PP.EmergencyIDFK = CEC.EmergencyId WHERE ID_Number = @IDNumber

			SET @Message = ''

		END ELSE
		BEGIN

			SET @Message = 'Sorry User ( ' + @IDNumber + ' ) Does not exists Please verify and try again'
			SET @FirstName = ''
			SET @LastName = ''
			SET @ID_Number = ''
			SET @DateOfBirth = GETDATE()
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
			SET @EmergencyPhoneNumber = ''
			SET @Relationship = ''
			SET @EmergancyDateOfBirth = GETDATE()

		END
	END TRY
	BEGIN CATCH

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