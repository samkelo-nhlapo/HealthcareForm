USE HealthcareForm
GO

-- Writes old/new patient snapshots to the audit log whenever tracked patient values change.
CREATE OR ALTER TRIGGER [Profile].[tr_AUpdatePatient]
ON [Profile].[Patient]
AFTER UPDATE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    SET NOCOUNT ON;

    ;WITH ChangedRows AS
    (
        -- Filter out rows where nothing we care about actually changed so the audit log stays useful.
        SELECT I.*, D.PatientId AS DPatientId,
               D.FirstName AS DFirstName,
               D.LastName AS DLastName,
               D.ID_Number AS DID_Number,
               D.DateOfBirth AS DDateOfBirth,
               D.GenderIDFK AS DGenderIDFK,
               D.MedicationList AS DMedicationList,
               D.AddressIDFK AS DAddressIDFK,
               D.MaritalStatusIDFK AS DMaritalStatusIDFK,
               D.EmergencyIDFK AS DEmergencyIDFK,
               D.IsDeleted AS DIsDeleted,
               D.CreatedDate AS DCreatedDate,
               D.CreatedBy AS DCreatedBy,
               D.UpdatedDate AS DUpdatedDate,
               D.UpdatedBy AS DUpdatedBy
        FROM inserted I
        INNER JOIN deleted D ON D.PatientId = I.PatientId
        WHERE
            ISNULL(D.FirstName, '') <> ISNULL(I.FirstName, '') OR
            ISNULL(D.LastName, '') <> ISNULL(I.LastName, '') OR
            ISNULL(D.ID_Number, '') <> ISNULL(I.ID_Number, '') OR
            ISNULL(CONVERT(VARCHAR(30), D.DateOfBirth, 126), '') <> ISNULL(CONVERT(VARCHAR(30), I.DateOfBirth, 126), '') OR
            ISNULL(D.GenderIDFK, -1) <> ISNULL(I.GenderIDFK, -1) OR
            ISNULL(D.MedicationList, '') <> ISNULL(I.MedicationList, '') OR
            ISNULL(CONVERT(VARCHAR(36), D.AddressIDFK), '') <> ISNULL(CONVERT(VARCHAR(36), I.AddressIDFK), '') OR
            ISNULL(D.MaritalStatusIDFK, -1) <> ISNULL(I.MaritalStatusIDFK, -1) OR
            ISNULL(CONVERT(VARCHAR(36), D.EmergencyIDFK), '') <> ISNULL(CONVERT(VARCHAR(36), I.EmergencyIDFK), '') OR
            ISNULL(D.IsDeleted, 0) <> ISNULL(I.IsDeleted, 0) OR
            ISNULL(CONVERT(VARCHAR(30), D.CreatedDate, 126), '') <> ISNULL(CONVERT(VARCHAR(30), I.CreatedDate, 126), '') OR
            ISNULL(D.CreatedBy, '') <> ISNULL(I.CreatedBy, '') OR
            ISNULL(CONVERT(VARCHAR(30), D.UpdatedDate, 126), '') <> ISNULL(CONVERT(VARCHAR(30), I.UpdatedDate, 126), '') OR
            ISNULL(D.UpdatedBy, '') <> ISNULL(I.UpdatedBy, '')
    )
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
        'Updated',
        'Profile',
        'Patient',
        C.PatientId,
        J.LogData
    FROM ChangedRows C
    CROSS APPLY
    (
        SELECT LogData =
        (
            SELECT
                [Old] =
                (
                    SELECT
                        C.DPatientId AS PatientId,
                        C.DFirstName AS FirstName,
                        C.DLastName AS LastName,
                        C.DID_Number AS ID_Number,
                        C.DDateOfBirth AS DateOfBirth,
                        C.DGenderIDFK AS GenderIDFK,
                        C.DMedicationList AS MedicationList,
                        C.DAddressIDFK AS AddressIDFK,
                        C.DMaritalStatusIDFK AS MaritalStatusIDFK,
                        C.DEmergencyIDFK AS EmergencyIDFK,
                        C.DIsDeleted AS IsDeleted,
                        C.DCreatedDate AS CreatedDate,
                        C.DCreatedBy AS CreatedBy,
                        C.DUpdatedDate AS UpdatedDate,
                        C.DUpdatedBy AS UpdatedBy
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ),
                [New] =
                (
                    SELECT
                        C.PatientId,
                        C.FirstName,
                        C.LastName,
                        C.ID_Number,
                        C.DateOfBirth,
                        C.GenderIDFK,
                        C.MedicationList,
                        C.AddressIDFK,
                        C.MaritalStatusIDFK,
                        C.EmergencyIDFK,
                        C.IsDeleted,
                        C.CreatedDate,
                        C.CreatedBy,
                        C.UpdatedDate,
                        C.UpdatedBy
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                )
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    ) J;
END
GO
