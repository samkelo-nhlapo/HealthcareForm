USE HealthcareForm
GO

-- Title-cases words after common separators while leaving apostrophe handling predictable.
CREATE OR ALTER FUNCTION [dbo].[CapitalizeFirstLetter]
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

        -- Promote the next character after common separators; skip apostrophes so names like O'Brien stay natural.
        IF @PrevChar IN (' ', ';', ':', '!', '?', ',', '.', '_', '-', '/', '&', '''', '(')
        BEGIN
            IF @PrevChar <> ''''
                SET @OutputString = STUFF(@OutputString, @Index, 1, UPPER(@Char));
        END

        SET @Index = @Index + 1;
    END

    RETURN @OutputString;
END
GO
