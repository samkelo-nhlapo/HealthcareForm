USE HealthcareForm
GO

DECLARE @DefaultDate DATETIME = GETDATE();

INSERT INTO Profile.HealthcareProviders
(
    ProviderId,
    FirstName,
    LastName,
    Title,
    Specialization,
    LicenseNumber,
    RegistrationBody,
    ProviderType,
    Qualifications,
    YearsOfExperience,
    OfficeAddressIdFK,
    IsActive,
    CreatedDate,
    CreatedBy
)
SELECT
    NEWID(),
    V.FirstName,
    V.LastName,
    V.Title,
    V.Specialization,
    V.LicenseNumber,
    V.RegistrationBody,
    V.ProviderType,
    V.Qualifications,
    V.YearsOfExperience,
    V.OfficeAddressIdFK,
    1,
    @DefaultDate,
    'SYSTEM'
FROM (
    VALUES
        ('Dr. Thabo Mthembu', '', CAST(NULL AS VARCHAR(50)), 'GP', 'ZA-MP-0012345', 'N/A', 'GENERAL_PRACTITIONER', CAST(NULL AS VARCHAR(MAX)), CAST(NULL AS INT), CAST(NULL AS UNIQUEIDENTIFIER)),
        ('Dr. Naledi Johnson', '', CAST(NULL AS VARCHAR(50)), 'CARDIOLOGY', 'ZA-MP-0054321', 'N/A', 'CARDIOLOGIST', CAST(NULL AS VARCHAR(MAX)), CAST(NULL AS INT), CAST(NULL AS UNIQUEIDENTIFIER)),
        ('Dr. Amira Hassan', '', CAST(NULL AS VARCHAR(50)), 'NEUROLOGY', 'ZA-MP-0098765', 'N/A', 'NEUROLOGIST', CAST(NULL AS VARCHAR(MAX)), CAST(NULL AS INT), CAST(NULL AS UNIQUEIDENTIFIER)),
        ('Dr. Kevin Smith', '', CAST(NULL AS VARCHAR(50)), 'ORTHOPEDICS', 'ZA-MP-0011111', 'N/A', 'ORTHOPEDIC_SURGEON', CAST(NULL AS VARCHAR(MAX)), CAST(NULL AS INT), CAST(NULL AS UNIQUEIDENTIFIER)),
        ('Dr. Patricia Ndlovu', '', CAST(NULL AS VARCHAR(50)), 'PEDIATRICS', 'ZA-MP-0022222', 'N/A', 'PEDIATRICIAN', CAST(NULL AS VARCHAR(MAX)), CAST(NULL AS INT), CAST(NULL AS UNIQUEIDENTIFIER)),
        ('Dr. Michael Chen', '', CAST(NULL AS VARCHAR(50)), 'PSYCHIATRY', 'ZA-MP-0033333', 'N/A', 'PSYCHIATRIST', CAST(NULL AS VARCHAR(MAX)), CAST(NULL AS INT), CAST(NULL AS UNIQUEIDENTIFIER)),
        ('Dr. Sarah Botha', '', CAST(NULL AS VARCHAR(50)), 'ENDOCRINOLOGY', 'ZA-MP-0044444', 'N/A', 'ENDOCRINOLOGIST', CAST(NULL AS VARCHAR(MAX)), CAST(NULL AS INT), CAST(NULL AS UNIQUEIDENTIFIER)),
        ('Dr. James Okafor', '', CAST(NULL AS VARCHAR(50)), 'PULMONOLOGY', 'ZA-MP-0055555', 'N/A', 'PULMONOLOGIST', CAST(NULL AS VARCHAR(MAX)), CAST(NULL AS INT), CAST(NULL AS UNIQUEIDENTIFIER)),
        ('Dr. Kavya Patel', '', CAST(NULL AS VARCHAR(50)), 'GASTROENTEROLOGY', 'ZA-MP-0066666', 'N/A', 'GASTROENTEROLOGIST', CAST(NULL AS VARCHAR(MAX)), CAST(NULL AS INT), CAST(NULL AS UNIQUEIDENTIFIER)),
        ('Dr. Robert Mendes', '', CAST(NULL AS VARCHAR(50)), 'UROLOGY', 'ZA-MP-0077777', 'N/A', 'UROLOGIST', CAST(NULL AS VARCHAR(MAX)), CAST(NULL AS INT), CAST(NULL AS UNIQUEIDENTIFIER))
) V(FirstName, LastName, Title, Specialization, LicenseNumber, RegistrationBody, ProviderType, Qualifications, YearsOfExperience, OfficeAddressIdFK)
WHERE NOT EXISTS
(
    SELECT 1
    FROM Profile.HealthcareProviders HP
    WHERE HP.LicenseNumber = V.LicenseNumber
);
GO

PRINT 'Healthcare providers inserted successfully'
GO
