USE HealthcareForm
GO

-- Keeps patient ID numbers immutable after insert because they behave like a business identity key.
CREATE OR ALTER TRIGGER [Profile].[tr_BlockPatientIDNumberUpdate]
ON [Profile].[Patient]
AFTER UPDATE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        INNER JOIN deleted D ON D.PatientId = I.PatientId
        WHERE ISNULL(I.ID_Number, '') <> ISNULL(D.ID_Number, '')
    )
    BEGIN
        RAISERROR('Updating Profile.Patient.ID_Number is not allowed.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO
