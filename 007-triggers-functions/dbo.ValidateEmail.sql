USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Validates email address format using basic pattern matching
--	TFS Task:		Add email validation for patient registration
--================================================================================================

CREATE OR ALTER FUNCTION dbo.ValidateEmail
(
	@Email VARCHAR(250)
)
RETURNS BIT
AS
BEGIN
	DECLARE @Result BIT = 0
	
	-- Validate: contains @, contains dot after @, no spaces, no multiple @, minimum length
	IF @Email LIKE '%@%.%' AND 
	   @Email NOT LIKE '%@%@%' AND
	   CHARINDEX(' ', @Email) = 0 AND
	   LEN(RTRIM(@Email)) >= 5
	BEGIN
		SET @Result = 1
	END
	
	RETURN @Result
END
