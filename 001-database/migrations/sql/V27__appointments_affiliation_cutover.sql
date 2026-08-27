USE HealthcareForm;
GO

IF OBJECT_ID(N'[Profile].[ClientProviderAffiliations]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[Profile].[ClientProviderAffiliations]')
      AND name = N'UX_ClientProviderAffiliations_Id_Client_Provider'
)
BEGIN
    CREATE UNIQUE INDEX UX_ClientProviderAffiliations_Id_Client_Provider
        ON [Profile].[ClientProviderAffiliations] ([ClientProviderAffiliationId], [ClientIdFK], [ProviderIdFK]);
END
GO

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND COL_LENGTH(N'[Profile].[Appointments]', N'ClientProviderAffiliationIdFK') IS NULL
BEGIN
    ALTER TABLE [Profile].[Appointments] ADD [ClientProviderAffiliationIdFK] UNIQUEIDENTIFIER NULL;
END
GO

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND COL_LENGTH(N'[Profile].[Appointments]', N'ClientStaffIdFK') IS NOT NULL
AND EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[Profile].[Appointments]')
      AND name = N'ClientStaffIdFK'
      AND is_nullable = 0
)
BEGIN
    ALTER TABLE [Profile].[Appointments] ALTER COLUMN [ClientStaffIdFK] UNIQUEIDENTIFIER NULL;
END
GO

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[ClientProviderAffiliations]', N'U') IS NOT NULL
BEGIN
    UPDATE A
    SET
        A.ClientProviderAffiliationIdFK = Resolved.ClientProviderAffiliationId,
        A.ClientStaffIdFK = COALESCE(A.ClientStaffIdFK, Resolved.ClientStaffIdFK),
        A.ClientIdFK = COALESCE(A.ClientIdFK, Resolved.ClientIdFK),
        A.ProviderIdFK = COALESCE(A.ProviderIdFK, Resolved.ProviderIdFK)
    FROM Profile.Appointments A
    OUTER APPLY
    (
        SELECT TOP 1
            CPA.ClientProviderAffiliationId,
            CPA.ClientStaffIdFK,
            CPA.ClientIdFK,
            CPA.ProviderIdFK
        FROM Profile.ClientProviderAffiliations CPA
        WHERE CPA.ProviderIdFK = A.ProviderIdFK
          AND
          (
              A.ClientIdFK IS NULL
              OR CPA.ClientIdFK = A.ClientIdFK
          )
        ORDER BY
            CASE
                WHEN A.ClientIdFK IS NOT NULL AND CPA.ClientIdFK = A.ClientIdFK THEN 0
                ELSE 1
            END,
            CASE
                WHEN CPA.IsActive = 1 THEN 0
                ELSE 1
            END,
            CASE
                WHEN CPA.EndDate IS NULL THEN 0
                ELSE 1
            END,
            CASE
                WHEN CPA.ClientStaffIdFK IS NOT NULL THEN 0
                ELSE 1
            END,
            COALESCE(CPA.UpdatedDate, CPA.CreatedDate) DESC,
            CPA.ClientProviderAffiliationId DESC
    ) Resolved
    WHERE A.ClientProviderAffiliationIdFK IS NULL
      AND Resolved.ClientProviderAffiliationId IS NOT NULL;

    UPDATE A
    SET A.ClientStaffIdFK = Resolved.ClientStaffIdFK
    FROM Profile.Appointments A
    INNER JOIN Profile.ClientProviderAffiliations Resolved
        ON Resolved.ClientProviderAffiliationId = A.ClientProviderAffiliationIdFK
    WHERE A.ClientStaffIdFK IS NULL
      AND Resolved.ClientStaffIdFK IS NOT NULL;

    IF EXISTS
    (
        SELECT 1
        FROM Profile.Appointments
        WHERE ClientProviderAffiliationIdFK IS NULL
    )
    BEGIN
        THROW 52003, 'Unable to backfill Appointments.ClientProviderAffiliationIdFK for all existing rows.', 1;
    END
END
GO

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND COL_LENGTH(N'[Profile].[Appointments]', N'ClientProviderAffiliationIdFK') IS NOT NULL
AND EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[Profile].[Appointments]')
      AND name = N'ClientProviderAffiliationIdFK'
      AND is_nullable = 1
)
AND NOT EXISTS (
    SELECT 1
    FROM [Profile].[Appointments]
    WHERE [ClientProviderAffiliationIdFK] IS NULL
)
BEGIN
    ALTER TABLE [Profile].[Appointments] ALTER COLUMN [ClientProviderAffiliationIdFK] UNIQUEIDENTIFIER NOT NULL;
END
GO

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND COL_LENGTH(N'[Profile].[Appointments]', N'ClientProviderAffiliationIdFK') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[Profile].[Appointments]')
      AND name = N'IX_Appointments_ClientProviderAffiliationIdFK'
)
BEGIN
    CREATE INDEX IX_Appointments_ClientProviderAffiliationIdFK
        ON [Profile].[Appointments] ([ClientProviderAffiliationIdFK]);
END
GO

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[ClientProviderAffiliations]', N'U') IS NOT NULL
AND COL_LENGTH(N'[Profile].[Appointments]', N'ClientProviderAffiliationIdFK') IS NOT NULL
AND COL_LENGTH(N'[Profile].[Appointments]', N'ClientIdFK') IS NOT NULL
AND COL_LENGTH(N'[Profile].[Appointments]', N'ProviderIdFK') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = N'FK_Appointments_ClientProviderAffiliations_Id_Client_Provider'
)
BEGIN
    ALTER TABLE [Profile].[Appointments] WITH CHECK
    ADD CONSTRAINT [FK_Appointments_ClientProviderAffiliations_Id_Client_Provider]
    FOREIGN KEY([ClientProviderAffiliationIdFK], [ClientIdFK], [ProviderIdFK])
    REFERENCES [Profile].[ClientProviderAffiliations] ([ClientProviderAffiliationId], [ClientIdFK], [ProviderIdFK]);
END
GO
