USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	22/01/2022
--	Description:	Phone number formatting function - formats to XXX-XXX-XXXX pattern
--	TFS Task:		Ensure Phone number format has - between numbers
--================================================================================================

CREATE OR ALTER FUNCTION Contacts.FormatPhoneNumber
(
	@PhoneNumber VARCHAR(15)
)
RETURNS VARCHAR(15)
AS
BEGIN
	DECLARE @Cleaned VARCHAR(15) = '',
			@i INT = 1
	
	-- Remove any non-numeric characters
	WHILE @i <= LEN(@PhoneNumber)
	BEGIN
		IF SUBSTRING(@PhoneNumber, @i, 1) LIKE '[0-9]'
			SET @Cleaned = @Cleaned + SUBSTRING(@PhoneNumber, @i, 1)
		SET @i = @i + 1
	END
	
	-- Format as South African number if 10 digits (0XX XXX XXXX format)
	IF LEN(@Cleaned) = 10
		RETURN SUBSTRING(@Cleaned, 1, 3) + '-' + SUBSTRING(@Cleaned, 4, 3) + '-' + SUBSTRING(@Cleaned, 7, 4)
	
	-- If 11 digits with leading 27, strip and format
	IF LEN(@Cleaned) = 11 AND LEFT(@Cleaned, 2) = '27'
		RETURN SUBSTRING(@Cleaned, 3, 3) + '-' + SUBSTRING(@Cleaned, 6, 3) + '-' + SUBSTRING(@Cleaned, 9, 4)
	
	-- Return cleaned number if cannot format to standard
	RETURN SUBSTRING(@Cleaned, 1, 15)
END
