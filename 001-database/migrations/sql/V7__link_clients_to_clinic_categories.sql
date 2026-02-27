-- V7__link_clients_to_clinic_categories.sql
-- Adds clinic-category lookup and links Profile.Clients for small/medium private/public clinics.

USE HealthcareForm;
GO

IF OBJECT_ID(N'[Profile].[ClientClinicCategories]', N'U') IS NULL
BEGIN
    CREATE TABLE [Profile].[ClientClinicCategories]
    (
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

IF OBJECT_ID(N'[Profile].[Clients]', N'U') IS NOT NULL
AND COL_LENGTH('Profile.Clients', 'ClientClinicCategoryIDFK') IS NULL
BEGIN
    ALTER TABLE [Profile].[Clients]
    ADD [ClientClinicCategoryIDFK] [int] NULL;
END
GO

IF OBJECT_ID(N'[Profile].[Clients]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[ClientClinicCategories]', N'U') IS NOT NULL
AND OBJECT_ID(N'FK_Clients_ClinicCategory', N'F') IS NULL
BEGIN
    ALTER TABLE [Profile].[Clients] WITH CHECK
    ADD CONSTRAINT FK_Clients_ClinicCategory
    FOREIGN KEY([ClientClinicCategoryIDFK])
    REFERENCES [Profile].[ClientClinicCategories]([ClientClinicCategoryId]);
END
GO

IF OBJECT_ID(N'[Profile].[Clients]', N'U') IS NOT NULL
AND NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[Profile].[Clients]')
      AND name = N'IX_Clients_ClientClinicCategoryIDFK'
)
BEGIN
    CREATE INDEX IX_Clients_ClientClinicCategoryIDFK ON [Profile].[Clients]([ClientClinicCategoryIDFK]);
END
GO

IF OBJECT_ID(N'[Profile].[ClientClinicCategories]', N'U') IS NOT NULL
AND NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[Profile].[ClientClinicCategories]')
      AND name = N'IX_ClientClinicCategories_IsActive'
)
BEGIN
    CREATE INDEX IX_ClientClinicCategories_IsActive ON [Profile].[ClientClinicCategories]([IsActive]);
END
GO

DECLARE @Now DATETIME = GETDATE();

IF OBJECT_ID(N'[Profile].[ClientClinicCategories]', N'U') IS NOT NULL
BEGIN
    INSERT INTO Profile.ClientClinicCategories (CategoryName, ClinicSize, OwnershipType, IsActive, CreatedDate, UpdatedDate)
    SELECT V.CategoryName, V.ClinicSize, V.OwnershipType, 1, @Now, @Now
    FROM
    (
        VALUES
            ('Small Private Clinic', 'Small', 'Private'),
            ('Small Public Clinic', 'Small', 'Public'),
            ('Medium Private Clinic', 'Medium', 'Private'),
            ('Medium Public Clinic', 'Medium', 'Public')
    ) V(CategoryName, ClinicSize, OwnershipType)
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM Profile.ClientClinicCategories C
        WHERE C.CategoryName = V.CategoryName
    );
END
GO
