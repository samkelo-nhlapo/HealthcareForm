USE HealthcareForm
GO

-- Blocks hard deletes on patients and records the attempted delete in the audit log.
CREATE OR ALTER TRIGGER [Profile].[tr_ADeletePatient]
ON [Profile].[Patient]
INSTEAD OF DELETE
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
        'DeleteBlocked',
        'Profile',
        'Patient',
        D.PatientId,
        J.LogData
    FROM deleted D
    CROSS APPLY
    (
        SELECT LogData =
        (
            SELECT
                D.PatientId,
                D.FirstName,
                D.LastName,
                D.ID_Number,
                D.DateOfBirth,
                D.GenderIDFK,
                D.MedicationList,
                D.AddressIDFK,
                D.MaritalStatusIDFK,
                D.EmergencyIDFK,
                D.IsDeleted,
                D.CreatedDate,
                D.CreatedBy,
                D.UpdatedDate,
                D.UpdatedBy
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    ) J;

    RAISERROR('Hard delete is not allowed on Profile.Patient. Use soft delete (IsDeleted = 1).', 16, 1);
    ROLLBACK TRANSACTION;
    RETURN;
END
GO
