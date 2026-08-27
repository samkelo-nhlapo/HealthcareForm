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
        [FacilityCityIDFK] [int] NULL,
        [ClientCode] [varchar](50) NOT NULL,
        [DisplayName] [varchar](250) NULL,
        [OrganizationType] [varchar](20) NULL,
        [GroupOperator] [varchar](250) NULL,
        [NetworkSources] [varchar](500) NULL,
        [DirectoryExternalKey] [varchar](150) NULL,
        [FacilityTownName] [varchar](250) NULL,
        [FacilityProvinceName] [varchar](250) NULL,
        [FacilityCountryName] [varchar](250) NULL,
        [FacilityAddressText] [varchar](500) NULL,
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

IF COL_LENGTH(N'[Profile].[Clients]', N'FacilityCityIDFK') IS NULL
BEGIN
    ALTER TABLE [Profile].[Clients]
    ADD [FacilityCityIDFK] [int] NULL;
END
GO

IF COL_LENGTH(N'[Profile].[Clients]', N'DisplayName') IS NULL
BEGIN
    ALTER TABLE [Profile].[Clients]
    ADD [DisplayName] [varchar](250) NULL;
END
GO

IF COL_LENGTH(N'[Profile].[Clients]', N'OrganizationType') IS NULL
BEGIN
    ALTER TABLE [Profile].[Clients]
    ADD [OrganizationType] [varchar](20) NULL;
END
GO

IF COL_LENGTH(N'[Profile].[Clients]', N'GroupOperator') IS NULL
BEGIN
    ALTER TABLE [Profile].[Clients]
    ADD [GroupOperator] [varchar](250) NULL;
END
GO

IF COL_LENGTH(N'[Profile].[Clients]', N'NetworkSources') IS NULL
BEGIN
    ALTER TABLE [Profile].[Clients]
    ADD [NetworkSources] [varchar](500) NULL;
END
GO

IF COL_LENGTH(N'[Profile].[Clients]', N'DirectoryExternalKey') IS NULL
BEGIN
    ALTER TABLE [Profile].[Clients]
    ADD [DirectoryExternalKey] [varchar](150) NULL;
END
GO

IF COL_LENGTH(N'[Profile].[Clients]', N'FacilityTownName') IS NULL
BEGIN
    ALTER TABLE [Profile].[Clients]
    ADD [FacilityTownName] [varchar](250) NULL;
END
GO

IF COL_LENGTH(N'[Profile].[Clients]', N'FacilityProvinceName') IS NULL
BEGIN
    ALTER TABLE [Profile].[Clients]
    ADD [FacilityProvinceName] [varchar](250) NULL;
END
GO

IF COL_LENGTH(N'[Profile].[Clients]', N'FacilityCountryName') IS NULL
BEGIN
    ALTER TABLE [Profile].[Clients]
    ADD [FacilityCountryName] [varchar](250) NULL;
END
GO

IF COL_LENGTH(N'[Profile].[Clients]', N'FacilityAddressText') IS NULL
BEGIN
    ALTER TABLE [Profile].[Clients]
    ADD [FacilityAddressText] [varchar](500) NULL;
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

IF OBJECT_ID(N'[Location].[Cities]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE parent_object_id = OBJECT_ID(N'[Profile].[Clients]')
      AND name = N'FK_Clients_FacilityCity'
)
BEGIN
    ALTER TABLE [Profile].[Clients] WITH CHECK
    ADD CONSTRAINT FK_Clients_FacilityCity FOREIGN KEY([FacilityCityIDFK])
    REFERENCES [Location].[Cities]([CityId]);
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

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Clients]') AND name = N'IX_Clients_FacilityCityIDFK')
BEGIN
    CREATE INDEX IX_Clients_FacilityCityIDFK ON [Profile].[Clients]([FacilityCityIDFK]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Clients]') AND name = N'IX_Clients_DisplayName')
BEGIN
    CREATE INDEX IX_Clients_DisplayName ON [Profile].[Clients]([DisplayName]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Clients]') AND name = N'IX_Clients_OrganizationType')
BEGIN
    CREATE INDEX IX_Clients_OrganizationType ON [Profile].[Clients]([OrganizationType]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Clients]') AND name = N'IX_Clients_GroupOperator')
BEGIN
    CREATE INDEX IX_Clients_GroupOperator ON [Profile].[Clients]([GroupOperator]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Clients]') AND name = N'IX_Clients_FacilityTownName')
BEGIN
    CREATE INDEX IX_Clients_FacilityTownName ON [Profile].[Clients]([FacilityTownName]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Clients]') AND name = N'IX_Clients_FacilityProvinceName')
BEGIN
    CREATE INDEX IX_Clients_FacilityProvinceName ON [Profile].[Clients]([FacilityProvinceName]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Clients]') AND name = N'IX_Clients_FacilityCountryName')
BEGIN
    CREATE INDEX IX_Clients_FacilityCountryName ON [Profile].[Clients]([FacilityCountryName]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Clients]') AND name = N'UX_Clients_DirectoryExternalKey')
BEGIN
    CREATE UNIQUE INDEX UX_Clients_DirectoryExternalKey
    ON [Profile].[Clients]([DirectoryExternalKey])
    WHERE [DirectoryExternalKey] IS NOT NULL;
END
GO

IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Clients_OrganizationType')
BEGIN
    ALTER TABLE [Profile].[Clients]
    DROP CONSTRAINT [CK_Clients_OrganizationType];
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Clients_OrganizationType')
BEGIN
    ALTER TABLE [Profile].[Clients]
    ADD CONSTRAINT CK_Clients_OrganizationType
    CHECK ([OrganizationType] IS NULL OR [OrganizationType] IN ('Clinic', 'Hospital', 'Organization', 'Other'));
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
