USE HealthcareForm
GO

DECLARE @DefaultDate DATETIME = GETDATE();

INSERT INTO Auth.Roles (RoleId, RoleName, Description, IsActive, CreatedDate, CreatedBy)
SELECT NEWID(), V.RoleName, V.Description, 1, @DefaultDate, 'SYSTEM'
FROM (
    VALUES
        ('ADMIN', 'System Administrator - Full system access'),
        ('DOCTOR', 'Medical Doctor - Patient care and clinical decision making'),
        ('NURSE', 'Registered Nurse - Patient care and monitoring'),
        ('RECEPTIONIST', 'Receptionist - Appointment scheduling and patient check-in'),
        ('PATIENT', 'Patient - Access own health records and appointment booking'),
        ('BILLING', 'Billing Administrator - Invoice and payment management'),
        ('PHARMACIST', 'Pharmacist - Medication management and dispensing')
) V(RoleName, Description)
WHERE NOT EXISTS (
    SELECT 1 FROM Auth.Roles R WHERE R.RoleName = V.RoleName
);
GO

PRINT 'Auth roles inserted/verified successfully';
GO
