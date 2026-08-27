USE HealthcareForm
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[Profile].[PatientClients]', N'U') IS NULL
BEGIN
    CREATE TABLE [Profile].[PatientClients]
    (
        [PatientClientId] [uniqueidentifier] NOT NULL,
        [PatientIdFK] [uniqueidentifier] NOT NULL,
        [ClientIdFK] [uniqueidentifier] NOT NULL,
        [IsPrimary] [bit] NOT NULL CONSTRAINT DF_PatientClients_IsPrimary DEFAULT 0,
        [CreatedDate] [datetime] NOT NULL CONSTRAINT DF_PatientClients_CreatedDate DEFAULT GETDATE(),
        [CreatedBy] [varchar](250) NULL,
        [UpdatedDate] [datetime] NOT NULL CONSTRAINT DF_PatientClients_UpdatedDate DEFAULT GETDATE(),
        [UpdatedBy] [varchar](250) NULL,
        CONSTRAINT PK_PatientClients PRIMARY KEY CLUSTERED ([PatientClientId] ASC)
    );

    ALTER TABLE [Profile].[PatientClients]
    ADD CONSTRAINT DF_PatientClients_PatientClientId DEFAULT (NEWID()) FOR [PatientClientId];
END
GO

IF OBJECT_ID(N'[Profile].[PatientClients]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE parent_object_id = OBJECT_ID(N'[Profile].[PatientClients]')
      AND name = N'FK_PatientClients_Patient'
)
BEGIN
    ALTER TABLE [Profile].[PatientClients] WITH CHECK
    ADD CONSTRAINT FK_PatientClients_Patient FOREIGN KEY([PatientIdFK])
    REFERENCES [Profile].[Patient]([PatientId]);
END
GO

IF OBJECT_ID(N'[Profile].[PatientClients]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[Clients]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE parent_object_id = OBJECT_ID(N'[Profile].[PatientClients]')
      AND name = N'FK_PatientClients_Client'
)
BEGIN
    ALTER TABLE [Profile].[PatientClients] WITH CHECK
    ADD CONSTRAINT FK_PatientClients_Client FOREIGN KEY([ClientIdFK])
    REFERENCES [Profile].[Clients]([ClientId]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[PatientClients]') AND name = N'UX_PatientClients_PatientClient')
BEGIN
    CREATE UNIQUE INDEX UX_PatientClients_PatientClient
    ON [Profile].[PatientClients]([PatientIdFK], [ClientIdFK]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[PatientClients]') AND name = N'UX_PatientClients_PrimaryPerPatient')
BEGIN
    CREATE UNIQUE INDEX UX_PatientClients_PrimaryPerPatient
    ON [Profile].[PatientClients]([PatientIdFK])
    WHERE [IsPrimary] = 1;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[PatientClients]') AND name = N'IX_PatientClients_ClientIdFK')
BEGIN
    CREATE INDEX IX_PatientClients_ClientIdFK ON [Profile].[PatientClients]([ClientIdFK]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[PatientClients]') AND name = N'IX_PatientClients_PatientIdFK')
BEGIN
    CREATE INDEX IX_PatientClients_PatientIdFK ON [Profile].[PatientClients]([PatientIdFK]);
END
GO
