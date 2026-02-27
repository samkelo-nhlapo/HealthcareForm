USE HealthcareForm
GO

CREATE OR ALTER TRIGGER [Contacts].[tr_NormalizeAndValidatePhoneNumber]
ON [Contacts].[Phones]
AFTER INSERT, UPDATE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    SET NOCOUNT ON;

    DECLARE @Normalized TABLE
    (
        PhoneId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        FormattedPhone VARCHAR(12) NULL
    );

    INSERT INTO @Normalized (PhoneId, FormattedPhone)
    SELECT
        I.PhoneId,
        [Contacts].[FormatPhoneNumber](I.PhoneNumber)
    FROM inserted I;

    IF EXISTS
    (
        SELECT 1
        FROM @Normalized N
        WHERE N.FormattedPhone IS NULL
    )
    BEGIN
        RAISERROR('Invalid phone number format. Use a 10-digit phone number.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    UPDATE P
    SET
        P.PhoneNumber = N.FormattedPhone,
        P.UpdateDate = GETDATE(),
        P.UpdatedBy = SYSTEM_USER
    FROM Contacts.Phones P
    INNER JOIN @Normalized N ON N.PhoneId = P.PhoneId
    WHERE ISNULL(P.PhoneNumber, '') <> ISNULL(N.FormattedPhone, '');
END
GO
