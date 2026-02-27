USE HealthcareForm
GO

CREATE OR ALTER FUNCTION [dbo].[CapitalizeFirstLetterBody]
(
    @InputString VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
AS
BEGIN
    IF @InputString IS NULL
        RETURN NULL;

    DECLARE @Index INT,
            @Char CHAR(1),
            @PrevChar CHAR(1),
            @OutputString VARCHAR(MAX);

    SET @OutputString = LOWER(@InputString);
    SET @Index = 1;

    WHILE @Index <= LEN(@InputString)
    BEGIN
        SET @Char = SUBSTRING(@InputString, @Index, 1);
        SET @PrevChar = CASE WHEN @Index = 1 THEN ' '
                             ELSE SUBSTRING(@InputString, @Index - 1, 1)
                        END;

        IF @PrevChar IN (';', ':', '!', '?', ',', '.', '_', '-', '/', '&', '''', '(')
        BEGIN
            IF @PrevChar <> ''''
                SET @OutputString = STUFF(@OutputString, @Index, 1, UPPER(@Char));
        END

        SET @Index = @Index + 1;
    END

    RETURN @OutputString;
END
GO
