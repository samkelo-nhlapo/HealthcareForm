USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [Auth].[Exception]
(
	@UserName VARCHAR(200),
	@ErrorSchema VARCHAR(200),
	@ErrorProc VARCHAR(200),
	@ErrorNumber INT,
	@ErrorState INT,
	@ErrorSeverity INT,
	@ErrorLine INT,
	@ErrorMessage VARCHAR(200),
	@ErrorDateTime DATETIME
)
AS
BEGIN

	INSERT INTO Auth.DB_Errors
	(
		UserName, 
		ErrorSchema, 
		ErrorProcedure, 
		ErrorNumber, 
		ErrorState, 
		ErrorSeverity, 
		ErrorLine, 
		ErrorMessage, 
		ErrorDateTime
	)
	VALUES(@UserName,@ErrorSchema, @ErrorProc, @ErrorNumber, @ErrorState, @ErrorSeverity, @ErrorLine, @ErrorMessage, @ErrorDateTime )

END
GO
