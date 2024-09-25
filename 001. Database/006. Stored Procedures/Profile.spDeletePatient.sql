USE HealthcareForm
GO

CREATE PROC Profile.spDeletePatient
(
	@IDNumber VARCHAR(250) = '',
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
			@ErrorDateTime DATETIME,
			@IsDeleted BIT = 0

	SET NOCOUNT ON

	BEGIN TRY

		IF EXISTS(SELECT 1 FROM Profile.Patient WHERE ID_Number = @IDNumber)
		BEGIN
			
			SET @IsDeleted = 1

			UPDATE Profile.Patient 
			SET IsDeleted = @IsDeleted 
			WHERE ID_Number = @IDNumber

			SET @Message = ''

		END ELSE
		BEGIN

			SET @Message = 'Sorry User ID:( ' + @IDNumber + ' ) Does not exists Please verify and try again'

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

		EXEC [Exceptions].[spErrorHandling] @UserName,@ErrorSchema, @ErrorProc, @ErrorNumber, @ErrorState, @ErrorSeverity, @ErrorLine, @ErrorMessage, @ErrorDateTime

	END CATCH

SET NOCOUNT OFF	

END