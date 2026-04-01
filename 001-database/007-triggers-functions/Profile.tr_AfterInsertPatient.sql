USE [HealthcareForm]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Writes a patient snapshot to the audit log whenever a patient row is inserted.
CREATE OR ALTER TRIGGER [Profile].[tr_AfterInsertPatient]
ON [Profile].[Patient]
AFTER INSERT
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    SET NOCOUNT ON;

    INSERT INTO Auth.AuditLog
    (
        ModifiedTime,
        ModifiedBy,
        Operation,
        SchemaName,
        TableName,
        TableID,
        LogData
    )
    SELECT
        GETDATE(),
        SYSTEM_USER,
        'Inserted',
        'Profile',
        'Patient',
        I.PatientId,
        J.LogData
    FROM inserted I
    CROSS APPLY
    (
        SELECT LogData =
        (
            SELECT
                I.PatientId,
                I.FirstName,
                I.LastName,
                I.ID_Number,
                I.DateOfBirth,
                I.GenderIDFK,
                I.MedicationList,
                I.AddressIDFK,
                I.MaritalStatusIDFK,
                I.EmergencyIDFK,
                I.IsDeleted,
                I.CreatedDate,
                I.CreatedBy,
                I.UpdatedDate,
                I.UpdatedBy
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    ) J;
END
GO
