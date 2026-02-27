USE HealthcareForm
GO

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
