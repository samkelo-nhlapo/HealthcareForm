USE HealthcareForm
GO

IF OBJECT_ID('Profile.ClientClinicCategories', 'U') IS NULL
    THROW 50000, 'Profile.ClientClinicCategories table is missing. Run DDL deployment first.', 1;
GO

DECLARE @Now DATETIME = GETDATE();

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
GO
