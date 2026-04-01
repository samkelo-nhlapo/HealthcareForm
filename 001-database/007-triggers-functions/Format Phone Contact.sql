USE HealthcareForm
GO

-- Normalizes local 10-digit phone numbers into the shared xxx-xxx-xxxx format.
-- Returning NULL lets callers and triggers fail fast on invalid input.
CREATE OR ALTER FUNCTION [Contacts].[FormatPhoneNumber]
(
    @PhoneNumber VARCHAR(25)
)
RETURNS VARCHAR(12)
AS
BEGIN
    DECLARE @Normalized VARCHAR(25);

    IF @PhoneNumber IS NULL
        RETURN NULL;

    SET @Normalized = LTRIM(RTRIM(@PhoneNumber));
    SET @Normalized = REPLACE(@Normalized, '-', '');
    SET @Normalized = REPLACE(@Normalized, ' ', '');
    SET @Normalized = REPLACE(@Normalized, '+', '');
    SET @Normalized = REPLACE(@Normalized, '(', '');
    SET @Normalized = REPLACE(@Normalized, ')', '');

    IF LEN(@Normalized) <> 10 OR @Normalized LIKE '%[^0-9]%'
        RETURN NULL;

    RETURN SUBSTRING(@Normalized, 1, 3) + '-' +
           SUBSTRING(@Normalized, 4, 3) + '-' +
           SUBSTRING(@Normalized, 7, 4);
END
GO
