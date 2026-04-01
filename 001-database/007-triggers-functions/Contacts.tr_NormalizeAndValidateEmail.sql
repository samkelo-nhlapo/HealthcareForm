USE HealthcareForm
GO

-- Keeps stored email values trimmed and lower-cased, and rejects malformed input early.
CREATE OR ALTER TRIGGER [Contacts].[tr_NormalizeAndValidateEmail]
ON [Contacts].[Emails]
AFTER INSERT, UPDATE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    SET NOCOUNT ON;

    -- Normalize once into a table variable so validation and the final update read from the same values.
    DECLARE @Normalized TABLE
    (
        EmailId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        NormalizedEmail VARCHAR(250) NOT NULL
    );

    INSERT INTO @Normalized (EmailId, NormalizedEmail)
    SELECT
        I.EmailId,
        LTRIM(RTRIM(LOWER(I.Email)))
    FROM inserted I;

    IF EXISTS
    (
        SELECT 1
        FROM @Normalized N
        WHERE N.NormalizedEmail = ''
           OR N.NormalizedEmail LIKE '% %'
           OR N.NormalizedEmail NOT LIKE '%_@_%._%'
    )
    BEGIN
        RAISERROR('Invalid email address format.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    UPDATE E
    SET
        E.Email = N.NormalizedEmail,
        E.UpdateDate = GETDATE(),
        E.UpdatedBy = SYSTEM_USER
    FROM Contacts.Emails E
    INNER JOIN @Normalized N ON N.EmailId = E.EmailId
    WHERE ISNULL(E.Email, '') <> ISNULL(N.NormalizedEmail, '');
END
GO
