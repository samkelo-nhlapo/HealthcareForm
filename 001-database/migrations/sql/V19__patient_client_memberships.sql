USE HealthcareForm;
GO

IF OBJECT_ID(N'[Profile].[PatientClients]', N'U') IS NULL
BEGIN
    CREATE TABLE [Profile].[PatientClients]
    (
        [PatientClientId] [uniqueidentifier] NOT NULL
            CONSTRAINT DF_PatientClients_PatientClientId DEFAULT (NEWID()),
        [PatientIdFK] [uniqueidentifier] NOT NULL,
        [ClientIdFK] [uniqueidentifier] NOT NULL,
        [IsPrimary] [bit] NOT NULL CONSTRAINT DF_PatientClients_IsPrimary DEFAULT 0,
        [CreatedDate] [datetime] NOT NULL CONSTRAINT DF_PatientClients_CreatedDate DEFAULT GETDATE(),
        [CreatedBy] [varchar](250) NULL,
        [UpdatedDate] [datetime] NOT NULL CONSTRAINT DF_PatientClients_UpdatedDate DEFAULT GETDATE(),
        [UpdatedBy] [varchar](250) NULL,
        CONSTRAINT PK_PatientClients PRIMARY KEY CLUSTERED ([PatientClientId] ASC)
    );
END
GO

IF OBJECT_ID(N'[Profile].[PatientClients]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_PatientClients_Patient')
BEGIN
    ALTER TABLE [Profile].[PatientClients] WITH CHECK
    ADD CONSTRAINT FK_PatientClients_Patient FOREIGN KEY([PatientIdFK]) REFERENCES [Profile].[Patient]([PatientId]);
END
GO

IF OBJECT_ID(N'[Profile].[PatientClients]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[Clients]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_PatientClients_Client')
BEGIN
    ALTER TABLE [Profile].[PatientClients] WITH CHECK
    ADD CONSTRAINT FK_PatientClients_Client FOREIGN KEY([ClientIdFK]) REFERENCES [Profile].[Clients]([ClientId]);
END
GO

IF OBJECT_ID(N'[Profile].[PatientClients]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[PatientClients]') AND name = N'UX_PatientClients_PatientClient')
BEGIN
    CREATE UNIQUE INDEX UX_PatientClients_PatientClient
    ON [Profile].[PatientClients]([PatientIdFK], [ClientIdFK]);
END
GO

IF OBJECT_ID(N'[Profile].[PatientClients]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[PatientClients]') AND name = N'UX_PatientClients_PrimaryPerPatient')
BEGIN
    CREATE UNIQUE INDEX UX_PatientClients_PrimaryPerPatient
    ON [Profile].[PatientClients]([PatientIdFK])
    WHERE [IsPrimary] = 1;
END
GO

IF OBJECT_ID(N'[Profile].[PatientClients]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[PatientClients]') AND name = N'IX_PatientClients_ClientIdFK')
BEGIN
    CREATE INDEX IX_PatientClients_ClientIdFK ON [Profile].[PatientClients]([ClientIdFK]);
END
GO

IF OBJECT_ID(N'[Profile].[PatientClients]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[PatientClients]') AND name = N'IX_PatientClients_PatientIdFK')
BEGIN
    CREATE INDEX IX_PatientClients_PatientIdFK ON [Profile].[PatientClients]([PatientIdFK]);
END
GO

IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[Profile].[Clients]')
      AND name = N'UX_Clients_PatientIdFK'
)
BEGIN
    DROP INDEX UX_Clients_PatientIdFK ON [Profile].[Clients];
END
GO

IF OBJECT_ID(N'[Profile].[PatientClients]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
BEGIN
    INSERT INTO [Profile].[PatientClients]
    (
        [PatientClientId],
        [PatientIdFK],
        [ClientIdFK],
        [IsPrimary],
        [CreatedDate],
        [CreatedBy],
        [UpdatedDate],
        [UpdatedBy]
    )
    SELECT
        NEWID(),
        P.PatientId,
        P.ClientIdFK,
        1,
        ISNULL(P.CreatedDate, GETDATE()),
        P.CreatedBy,
        ISNULL(P.UpdatedDate, GETDATE()),
        P.UpdatedBy
    FROM [Profile].[Patient] P
    WHERE P.ClientIdFK IS NOT NULL
      AND NOT EXISTS
      (
          SELECT 1
          FROM [Profile].[PatientClients] PC
          WHERE PC.PatientIdFK = P.PatientId
            AND PC.ClientIdFK = P.ClientIdFK
      );
END
GO

IF OBJECT_ID(N'[Profile].[PatientClients]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
BEGIN
    UPDATE PC
    SET PC.IsPrimary = CASE WHEN P.ClientIdFK = PC.ClientIdFK THEN 1 ELSE 0 END,
        PC.UpdatedDate = GETDATE()
    FROM [Profile].[PatientClients] PC
    INNER JOIN [Profile].[Patient] P ON P.PatientId = PC.PatientIdFK
    WHERE P.ClientIdFK IS NOT NULL;
END
GO
