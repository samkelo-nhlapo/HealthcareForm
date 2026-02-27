USE HealthcareForm
GO

DECLARE @DefaultDate DATETIME = GETDATE();

INSERT INTO Profile.InsuranceProviders
(
    InsuranceProviderId,
    ProviderName,
    RegistrationNumber,
    ContactPerson,
    AddressIdFK,
    PhoneNumber,
    Email,
    WebsiteUrl,
    BillingCode,
    IsActive,
    Notes,
    CreatedDate,
    CreatedBy
)
SELECT
    NEWID(),
    V.ProviderName,
    V.RegistrationNumber,
    V.ContactPerson,
    V.AddressIdFK,
    V.PhoneNumber,
    V.Email,
    V.WebsiteUrl,
    V.BillingCode,
    1,
    V.Notes,
    @DefaultDate,
    'SYSTEM'
FROM (
    VALUES
        ('Discovery Health', 'REG001', CAST(NULL AS VARCHAR(250)), CAST(NULL AS UNIQUEIDENTIFIER), '+27 11 799 8000', 'inquiry@discovery.co.za', CAST(NULL AS VARCHAR(500)), CAST(NULL AS VARCHAR(50)), CAST(NULL AS VARCHAR(MAX))),
        ('Momentum Health Solutions', 'REG002', CAST(NULL AS VARCHAR(250)), CAST(NULL AS UNIQUEIDENTIFIER), '+27 11 408 6600', 'support@momentum.co.za', CAST(NULL AS VARCHAR(500)), CAST(NULL AS VARCHAR(50)), CAST(NULL AS VARCHAR(MAX))),
        ('Medshelf Medical Scheme', 'REG003', CAST(NULL AS VARCHAR(250)), CAST(NULL AS UNIQUEIDENTIFIER), '+27 10 020 2020', 'membercare@medshelf.co.za', CAST(NULL AS VARCHAR(500)), CAST(NULL AS VARCHAR(50)), CAST(NULL AS VARCHAR(MAX))),
        ('Bonitas', 'REG004', CAST(NULL AS VARCHAR(250)), CAST(NULL AS UNIQUEIDENTIFIER), '+27 11 407 5000', 'support@bonitas.co.za', CAST(NULL AS VARCHAR(500)), CAST(NULL AS VARCHAR(50)), CAST(NULL AS VARCHAR(MAX))),
        ('Polmed', 'REG005', CAST(NULL AS VARCHAR(250)), CAST(NULL AS UNIQUEIDENTIFIER), '+27 11 386 4800', 'info@polmed.co.za', CAST(NULL AS VARCHAR(500)), CAST(NULL AS VARCHAR(50)), CAST(NULL AS VARCHAR(MAX))),
        ('GEMS (Government Employees Medical Scheme)', 'REG006', CAST(NULL AS VARCHAR(250)), CAST(NULL AS UNIQUEIDENTIFIER), '+27 12 307 9000', 'support@gems.gov.za', CAST(NULL AS VARCHAR(500)), CAST(NULL AS VARCHAR(50)), CAST(NULL AS VARCHAR(MAX))),
        ('Sizwe Medical Scheme', 'REG007', CAST(NULL AS VARCHAR(250)), CAST(NULL AS UNIQUEIDENTIFIER), '+27 11 287 8000', 'member@sizwehealth.co.za', CAST(NULL AS VARCHAR(500)), CAST(NULL AS VARCHAR(50)), CAST(NULL AS VARCHAR(MAX))),
        ('Umkhulu Medical Scheme', 'REG008', CAST(NULL AS VARCHAR(250)), CAST(NULL AS UNIQUEIDENTIFIER), '+27 31 328 6000', 'support@umkhulu.co.za', CAST(NULL AS VARCHAR(500)), CAST(NULL AS VARCHAR(50)), CAST(NULL AS VARCHAR(MAX)))
) V(ProviderName, RegistrationNumber, ContactPerson, AddressIdFK, PhoneNumber, Email, WebsiteUrl, BillingCode, Notes)
WHERE NOT EXISTS
(
    SELECT 1
    FROM Profile.InsuranceProviders IP
    WHERE IP.RegistrationNumber = V.RegistrationNumber
       OR IP.ProviderName = V.ProviderName
);
GO

PRINT 'Insurance providers inserted successfully'
GO
