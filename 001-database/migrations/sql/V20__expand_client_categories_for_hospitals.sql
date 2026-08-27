-- V20__expand_client_categories_for_hospitals.sql
-- Expands organisation categories so client records can represent both clinics and hospitals.

USE HealthcareForm;
GO

IF OBJECT_ID(N'[Profile].[ClientClinicCategories]', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.check_constraints
        WHERE name = N'CK_ClientClinicCategories_ClinicSize'
          AND parent_object_id = OBJECT_ID(N'[Profile].[ClientClinicCategories]')
    )
    BEGIN
        ALTER TABLE [Profile].[ClientClinicCategories]
        DROP CONSTRAINT [CK_ClientClinicCategories_ClinicSize];
    END

    ALTER TABLE [Profile].[ClientClinicCategories]
    ADD CONSTRAINT [CK_ClientClinicCategories_ClinicSize]
    CHECK ([ClinicSize] IN ('Small', 'Medium', 'Large'));
END
GO

DECLARE @Now DATETIME = GETDATE();

IF OBJECT_ID(N'[Profile].[ClientClinicCategories]', N'U') IS NOT NULL
BEGIN
    INSERT INTO [Profile].[ClientClinicCategories]
    (
        [CategoryName],
        [ClinicSize],
        [OwnershipType],
        [IsActive],
        [CreatedDate],
        [UpdatedDate]
    )
    SELECT
        V.[CategoryName],
        V.[ClinicSize],
        V.[OwnershipType],
        1,
        @Now,
        @Now
    FROM
    (
        VALUES
            ('Medium Private Hospital', 'Medium', 'Private'),
            ('Medium Public Hospital', 'Medium', 'Public'),
            ('Large Private Hospital', 'Large', 'Private'),
            ('Large Public Hospital', 'Large', 'Public')
    ) V([CategoryName], [ClinicSize], [OwnershipType])
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM [Profile].[ClientClinicCategories] C
        WHERE C.[CategoryName] = V.[CategoryName]
    );
END
GO
