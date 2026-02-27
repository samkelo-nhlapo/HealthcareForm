USE HealthcareForm
GO

CREATE OR ALTER TRIGGER [Contacts].[tr_EnforceSinglePrimaryPatientEmail]
ON [Contacts].[PatientEmails]
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
        SELECT
            PE.PatientEmailId,
            PE.PatientIdFK,
            ROW_NUMBER() OVER
            (
                PARTITION BY PE.PatientIdFK
                ORDER BY
                    CASE WHEN PE.IsPrimary = 1 THEN 0 ELSE 1 END,
                    ISNULL(PE.UpdatedDate, PE.CreatedDate) DESC,
                    PE.PatientEmailId DESC
            ) AS RN,
            SUM(CASE WHEN PE.IsPrimary = 1 THEN 1 ELSE 0 END)
                OVER (PARTITION BY PE.PatientIdFK) AS PrimaryCount
        FROM Contacts.PatientEmails PE
        INNER JOIN AffectedPatients AP ON AP.PatientIdFK = PE.PatientIdFK
    )
    UPDATE PE
    SET
        IsPrimary = CASE WHEN PR.RN = 1 THEN 1 ELSE 0 END,
        UpdatedDate = GETDATE(),
        UpdatedBy = SYSTEM_USER
    FROM Contacts.PatientEmails PE
    INNER JOIN PrimaryRows PR ON PR.PatientEmailId = PE.PatientEmailId
    WHERE
        (PR.PrimaryCount = 0 OR PR.PrimaryCount > 1)
        OR (PR.RN = 1 AND PE.IsPrimary = 0)
        OR (PR.RN > 1 AND PE.IsPrimary = 1);
END
GO
