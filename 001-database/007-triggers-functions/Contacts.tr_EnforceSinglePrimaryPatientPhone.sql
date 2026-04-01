USE HealthcareForm
GO

-- Ensures each patient ends up with exactly one primary phone row.
-- The trigger also self-heals after deletes or conflicting updates by promoting the best remaining row.
CREATE OR ALTER TRIGGER [Contacts].[tr_EnforceSinglePrimaryPatientPhone]
ON [Contacts].[PatientPhones]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    SET NOCOUNT ON;

    ;WITH AffectedPatients AS
    (
        SELECT DISTINCT PatientIdFK FROM inserted
        UNION
        SELECT DISTINCT PatientIdFK FROM deleted
    ),
    PrimaryRows AS
    (
        -- Rank the preferred survivor first so the final update can collapse multiple edge cases in one pass.
        SELECT
            PP.PatientPhoneId,
            PP.PatientIdFK,
            ROW_NUMBER() OVER
            (
                PARTITION BY PP.PatientIdFK
                ORDER BY
                    CASE WHEN PP.IsPrimary = 1 THEN 0 ELSE 1 END,
                    ISNULL(PP.UpdatedDate, PP.CreatedDate) DESC,
                    PP.PatientPhoneId DESC
            ) AS RN,
            SUM(CASE WHEN PP.IsPrimary = 1 THEN 1 ELSE 0 END)
                OVER (PARTITION BY PP.PatientIdFK) AS PrimaryCount
        FROM Contacts.PatientPhones PP
        INNER JOIN AffectedPatients AP ON AP.PatientIdFK = PP.PatientIdFK
    )
    UPDATE PP
    SET
        IsPrimary = CASE WHEN PR.RN = 1 THEN 1 ELSE 0 END,
        UpdatedDate = GETDATE(),
        UpdatedBy = SYSTEM_USER
    FROM Contacts.PatientPhones PP
    INNER JOIN PrimaryRows PR ON PR.PatientPhoneId = PP.PatientPhoneId
    WHERE
        (PR.PrimaryCount = 0 OR PR.PrimaryCount > 1)
        OR (PR.RN = 1 AND PP.IsPrimary = 0)
        OR (PR.RN > 1 AND PP.IsPrimary = 1);
END
GO
