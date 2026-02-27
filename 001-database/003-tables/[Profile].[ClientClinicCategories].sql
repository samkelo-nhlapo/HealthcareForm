USE HealthcareForm
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[Profile].[ClientClinicCategories]', N'U') IS NULL
BEGIN
    CREATE TABLE [Profile].[ClientClinicCategories](
        [ClientClinicCategoryId] [int] IDENTITY(1,1) NOT NULL,
        [CategoryName] [varchar](100) NOT NULL,
        [ClinicSize] [varchar](20) NOT NULL,
        [OwnershipType] [varchar](20) NOT NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT DF_ClientClinicCategories_IsActive DEFAULT 1,
        [CreatedDate] [datetime] NOT NULL CONSTRAINT DF_ClientClinicCategories_CreatedDate DEFAULT GETDATE(),
        [UpdatedDate] [datetime] NOT NULL CONSTRAINT DF_ClientClinicCategories_UpdatedDate DEFAULT GETDATE(),
        CONSTRAINT PK_ClientClinicCategories PRIMARY KEY CLUSTERED ([ClientClinicCategoryId] ASC),
        CONSTRAINT UQ_ClientClinicCategories_CategoryName UNIQUE ([CategoryName])
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ClientClinicCategories_ClinicSize')
BEGIN
    ALTER TABLE [Profile].[ClientClinicCategories]
    ADD CONSTRAINT CK_ClientClinicCategories_ClinicSize CHECK ([ClinicSize] IN ('Small', 'Medium'));
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ClientClinicCategories_OwnershipType')
BEGIN
    ALTER TABLE [Profile].[ClientClinicCategories]
    ADD CONSTRAINT CK_ClientClinicCategories_OwnershipType CHECK ([OwnershipType] IN ('Private', 'Public'));
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[Profile].[ClientClinicCategories]')
      AND name = N'IX_ClientClinicCategories_IsActive'
)
BEGIN
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientClinicCategories]') AND name = 'IX_ClientClinicCategories_IsActive')
BEGIN
    CREATE INDEX IX_ClientClinicCategories_IsActive ON [Profile].[ClientClinicCategories]([IsActive]);
END
END
GO
