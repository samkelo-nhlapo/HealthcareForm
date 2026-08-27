SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'[Profile].[Clients]', N'U') IS NULL
BEGIN
    THROW 53010, 'Profile.Clients must exist before V28 can run.', 1;
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

IF OBJECT_ID(N'[Location].[Cities]', N'U') IS NOT NULL
AND NOT EXISTS
(
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

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[Profile].[Clients]')
      AND name = N'IX_Clients_FacilityCityIDFK'
)
BEGIN
    CREATE INDEX IX_Clients_FacilityCityIDFK
    ON [Profile].[Clients]([FacilityCityIDFK]);
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[Profile].[Clients]')
      AND name = N'IX_Clients_DisplayName'
)
BEGIN
    CREATE INDEX IX_Clients_DisplayName
    ON [Profile].[Clients]([DisplayName]);
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[Profile].[Clients]')
      AND name = N'IX_Clients_OrganizationType'
)
BEGIN
    CREATE INDEX IX_Clients_OrganizationType
    ON [Profile].[Clients]([OrganizationType]);
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[Profile].[Clients]')
      AND name = N'IX_Clients_GroupOperator'
)
BEGIN
    CREATE INDEX IX_Clients_GroupOperator
    ON [Profile].[Clients]([GroupOperator]);
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[Profile].[Clients]')
      AND name = N'IX_Clients_FacilityTownName'
)
BEGIN
    CREATE INDEX IX_Clients_FacilityTownName
    ON [Profile].[Clients]([FacilityTownName]);
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[Profile].[Clients]')
      AND name = N'IX_Clients_FacilityProvinceName'
)
BEGIN
    CREATE INDEX IX_Clients_FacilityProvinceName
    ON [Profile].[Clients]([FacilityProvinceName]);
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[Profile].[Clients]')
      AND name = N'IX_Clients_FacilityCountryName'
)
BEGIN
    CREATE INDEX IX_Clients_FacilityCountryName
    ON [Profile].[Clients]([FacilityCountryName]);
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[Profile].[Clients]')
      AND name = N'UX_Clients_DirectoryExternalKey'
)
BEGIN
    CREATE UNIQUE INDEX UX_Clients_DirectoryExternalKey
    ON [Profile].[Clients]([DirectoryExternalKey])
    WHERE [DirectoryExternalKey] IS NOT NULL;
END
GO

IF EXISTS
(
    SELECT 1
    FROM sys.check_constraints
    WHERE parent_object_id = OBJECT_ID(N'[Profile].[Clients]')
      AND name = N'CK_Clients_OrganizationType'
)
BEGIN
    ALTER TABLE [Profile].[Clients]
    DROP CONSTRAINT CK_Clients_OrganizationType;
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.check_constraints
    WHERE parent_object_id = OBJECT_ID(N'[Profile].[Clients]')
      AND name = N'CK_Clients_OrganizationType'
)
BEGIN
    ALTER TABLE [Profile].[Clients]
    ADD CONSTRAINT CK_Clients_OrganizationType
    CHECK ([OrganizationType] IS NULL OR [OrganizationType] IN ('Clinic', 'Hospital', 'Organization', 'Other'));
END
GO
