USE HealthcareForm
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[Profile].[Clients]', N'U') IS NULL
BEGIN
    CREATE TABLE [Profile].[Clients](
        [ClientId] [uniqueidentifier] NOT NULL,
        [PatientIdFK] [uniqueidentifier] NULL,
        [ClientClinicCategoryIDFK] [int] NULL,
        [ClientCode] [varchar](50) NOT NULL,
        [FirstName] [varchar](250) NOT NULL,
        [LastName] [varchar](250) NOT NULL,
        [DateOfBirth] [datetime] NULL,
        [ID_Number] [varchar](250) NULL,
        [Email] [varchar](250) NULL,
        [PhoneNumber] [varchar](25) NULL,
        [AddressIDFK] [uniqueidentifier] NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT DF_Clients_IsActive DEFAULT 1,
        [IsDeleted] [bit] NOT NULL CONSTRAINT DF_Clients_IsDeleted DEFAULT 0,
        [CreatedDate] [datetime] NOT NULL CONSTRAINT DF_Clients_CreatedDate DEFAULT GETDATE(),
        [CreatedBy] [varchar](250) NULL,
        [UpdatedDate] [datetime] NOT NULL CONSTRAINT DF_Clients_UpdatedDate DEFAULT GETDATE(),
        [UpdatedBy] [varchar](250) NULL,
        CONSTRAINT PK_Clients PRIMARY KEY CLUSTERED ([ClientId] ASC),
        CONSTRAINT UQ_Clients_ClientCode UNIQUE ([ClientCode])
    );

    ALTER TABLE [Profile].[Clients]
    ADD CONSTRAINT DF_Clients_ClientId DEFAULT (NEWID()) FOR [ClientId];
END
GO

IF OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE parent_object_id = OBJECT_ID(N'[Profile].[Clients]')
      AND name = N'FK_Clients_Patient'
)
BEGIN
    ALTER TABLE [Profile].[Clients] WITH CHECK
    ADD CONSTRAINT FK_Clients_Patient FOREIGN KEY([PatientIdFK])
    REFERENCES [Profile].[Patient]([PatientId]);
END
GO

IF OBJECT_ID(N'[Profile].[ClientClinicCategories]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE parent_object_id = OBJECT_ID(N'[Profile].[Clients]')
      AND name = N'FK_Clients_ClinicCategory'
)
BEGIN
    ALTER TABLE [Profile].[Clients] WITH CHECK
    ADD CONSTRAINT FK_Clients_ClinicCategory FOREIGN KEY([ClientClinicCategoryIDFK])
    REFERENCES [Profile].[ClientClinicCategories]([ClientClinicCategoryId]);
END
GO

IF OBJECT_ID(N'[Location].[Address]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE parent_object_id = OBJECT_ID(N'[Profile].[Clients]')
      AND name = N'FK_Clients_Address'
)
BEGIN
    ALTER TABLE [Profile].[Clients] WITH CHECK
    ADD CONSTRAINT FK_Clients_Address FOREIGN KEY([AddressIDFK])
    REFERENCES [Location].[Address]([AddressId]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Clients]') AND name = N'UX_Clients_PatientIdFK')
BEGIN
    CREATE UNIQUE INDEX UX_Clients_PatientIdFK
    ON [Profile].[Clients]([PatientIdFK])
    WHERE [PatientIdFK] IS NOT NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Clients]') AND name = N'IX_Clients_ClientCode')
BEGIN
    CREATE INDEX IX_Clients_ClientCode ON [Profile].[Clients]([ClientCode]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Clients]') AND name = N'IX_Clients_ClientClinicCategoryIDFK')
BEGIN
    CREATE INDEX IX_Clients_ClientClinicCategoryIDFK ON [Profile].[Clients]([ClientClinicCategoryIDFK]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Clients]') AND name = N'IX_Clients_LastName')
BEGIN
    CREATE INDEX IX_Clients_LastName ON [Profile].[Clients]([LastName]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Clients]') AND name = N'IX_Clients_IsDeleted')
BEGIN
    CREATE INDEX IX_Clients_IsDeleted ON [Profile].[Clients]([IsDeleted]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Clients]') AND name = N'IX_Clients_IsActive')
BEGIN
    CREATE INDEX IX_Clients_IsActive ON [Profile].[Clients]([IsActive]);
END
GO
