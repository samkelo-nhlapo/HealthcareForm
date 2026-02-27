USE HealthcareForm
GO

SET NOCOUNT ON;

PRINT '================================================================================================';
PRINT 'HealthcareForm - Master Data Initialization';
PRINT 'Started: ' + CONVERT(VARCHAR(25), GETDATE(), 121);
PRINT '================================================================================================';

IF OBJECT_ID('Auth.Roles', 'U') IS NULL
    THROW 50000, 'Auth.Roles table is missing. Run DDL deployment first.', 1;
IF OBJECT_ID('Auth.Permissions', 'U') IS NULL
    THROW 50000, 'Auth.Permissions table is missing. Run DDL deployment first.', 1;
IF OBJECT_ID('Auth.RolePermissions', 'U') IS NULL
    THROW 50000, 'Auth.RolePermissions table is missing. Run DDL deployment first.', 1;
IF OBJECT_ID('Auth.Users', 'U') IS NULL
    THROW 50000, 'Auth.Users table is missing. Run DDL deployment first.', 1;
IF OBJECT_ID('Auth.UserRoles', 'U') IS NULL
    THROW 50000, 'Auth.UserRoles table is missing. Run DDL deployment first.', 1;
IF OBJECT_ID('Exceptions.Errors', 'U') IS NULL
    PRINT 'Warning: Exceptions.Errors table is missing. Error logging procedures may fail until DDL deployment is complete.';
IF OBJECT_ID('Exceptions.spErrorHandling', 'P') IS NULL
    PRINT 'Warning: Exceptions.spErrorHandling is missing. Deploy 006-stored-procedures/[Exceptions].[spErrorHandling].sql.';
IF OBJECT_ID('[Contacts].[tr_NormalizeAndValidateEmail]', 'TR') IS NULL
    PRINT 'Warning: Required triggers are missing. Deploy 007-triggers-functions/000. MASTER_DEPLOYMENT_SCRIPT.sql.';
GO

PRINT '[1/4] Seeding roles...';
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

PRINT '[2/4] Seeding permissions...';
DECLARE @DefaultDate DATETIME = GETDATE();

INSERT INTO Auth.Permissions
(
    PermissionId, PermissionName, Description, Category, Module, ActionType,
    IsActive, CreatedDate, CreatedBy
)
SELECT NEWID(), V.PermissionName, V.Description, V.Category, V.Module, V.ActionType, 1, @DefaultDate, 'SYSTEM'
FROM (
    VALUES
        ('Patient_Create', 'Create new patient record', 'CLINICAL', 'PATIENT', 'CREATE'),
        ('Patient_Read', 'View patient information', 'CLINICAL', 'PATIENT', 'READ'),
        ('Patient_Update', 'Modify patient information', 'CLINICAL', 'PATIENT', 'UPDATE'),
        ('Patient_Delete', 'Delete patient record', 'CLINICAL', 'PATIENT', 'DELETE'),
        ('Patient_ViewAll', 'View all patients in system', 'CLINICAL', 'PATIENT', 'READ'),
        ('MedicalHistory_Create', 'Add medical history entry', 'CLINICAL', 'MEDICAL_HISTORY', 'CREATE'),
        ('MedicalHistory_Read', 'View medical history', 'CLINICAL', 'MEDICAL_HISTORY', 'READ'),
        ('MedicalHistory_Update', 'Modify medical history', 'CLINICAL', 'MEDICAL_HISTORY', 'UPDATE'),
        ('MedicalHistory_Delete', 'Delete medical history entry', 'CLINICAL', 'MEDICAL_HISTORY', 'DELETE'),
        ('Appointment_Create', 'Create appointment', 'CLINICAL', 'APPOINTMENT', 'CREATE'),
        ('Appointment_Read', 'View appointments', 'CLINICAL', 'APPOINTMENT', 'READ'),
        ('Appointment_Update', 'Modify appointment', 'CLINICAL', 'APPOINTMENT', 'UPDATE'),
        ('Appointment_Cancel', 'Cancel appointment', 'CLINICAL', 'APPOINTMENT', 'CANCEL'),
        ('Appointment_ViewAll', 'View all appointments', 'CLINICAL', 'APPOINTMENT', 'READ'),
        ('Medication_Create', 'Add medication record', 'CLINICAL', 'MEDICATION', 'CREATE'),
        ('Medication_Read', 'View medication history', 'CLINICAL', 'MEDICATION', 'READ'),
        ('Medication_Update', 'Modify medication record', 'CLINICAL', 'MEDICATION', 'UPDATE'),
        ('Medication_Delete', 'Remove medication record', 'CLINICAL', 'MEDICATION', 'DELETE'),
        ('Medication_Manage', 'Manage all medications in system', 'CLINICAL', 'MEDICATION', 'MANAGE'),
        ('ConsultationNotes_Create', 'Create consultation notes', 'CLINICAL', 'CONSULTATION_NOTES', 'CREATE'),
        ('ConsultationNotes_Read', 'View consultation notes', 'CLINICAL', 'CONSULTATION_NOTES', 'READ'),
        ('ConsultationNotes_Update', 'Modify consultation notes', 'CLINICAL', 'CONSULTATION_NOTES', 'UPDATE'),
        ('ConsultationNotes_Delete', 'Delete consultation notes', 'CLINICAL', 'CONSULTATION_NOTES', 'DELETE'),
        ('Form_Create', 'Create form template', 'OPERATIONS', 'FORM', 'CREATE'),
        ('Form_Read', 'View forms', 'OPERATIONS', 'FORM', 'READ'),
        ('Form_Update', 'Modify form template', 'OPERATIONS', 'FORM', 'UPDATE'),
        ('Form_Delete', 'Delete form', 'OPERATIONS', 'FORM', 'DELETE'),
        ('Form_Submit', 'Submit form', 'OPERATIONS', 'FORM', 'SUBMIT'),
        ('Form_Review', 'Review submitted forms', 'OPERATIONS', 'FORM', 'REVIEW'),
        ('Invoice_Create', 'Create invoice', 'FINANCE', 'INVOICE', 'CREATE'),
        ('Invoice_Read', 'View invoices', 'FINANCE', 'INVOICE', 'READ'),
        ('Invoice_Update', 'Modify invoice', 'FINANCE', 'INVOICE', 'UPDATE'),
        ('Invoice_Delete', 'Delete invoice', 'FINANCE', 'INVOICE', 'DELETE'),
        ('Payment_Process', 'Process payment', 'FINANCE', 'PAYMENT', 'PROCESS'),
        ('Payment_View', 'View payment history', 'FINANCE', 'PAYMENT', 'READ'),
        ('Insurance_Create', 'Create insurance record', 'FINANCE', 'INSURANCE', 'CREATE'),
        ('Insurance_Read', 'View insurance information', 'FINANCE', 'INSURANCE', 'READ'),
        ('Insurance_Update', 'Modify insurance record', 'FINANCE', 'INSURANCE', 'UPDATE'),
        ('Insurance_Delete', 'Delete insurance record', 'FINANCE', 'INSURANCE', 'DELETE'),
        ('Allergy_Create', 'Add allergy record', 'CLINICAL', 'ALLERGY', 'CREATE'),
        ('Allergy_Read', 'View allergy information', 'CLINICAL', 'ALLERGY', 'READ'),
        ('Allergy_Update', 'Modify allergy record', 'CLINICAL', 'ALLERGY', 'UPDATE'),
        ('Allergy_Delete', 'Delete allergy record', 'CLINICAL', 'ALLERGY', 'DELETE'),
        ('LabResults_Create', 'Create lab results', 'CLINICAL', 'LAB_RESULTS', 'CREATE'),
        ('LabResults_Read', 'View lab results', 'CLINICAL', 'LAB_RESULTS', 'READ'),
        ('LabResults_Update', 'Modify lab results', 'CLINICAL', 'LAB_RESULTS', 'UPDATE'),
        ('LabResults_Delete', 'Delete lab results', 'CLINICAL', 'LAB_RESULTS', 'DELETE'),
        ('SystemAdmin_User', 'Manage users and roles', 'ADMIN', 'SYSTEM', 'MANAGE'),
        ('SystemAdmin_Audit', 'View audit logs', 'ADMIN', 'SYSTEM', 'READ'),
        ('SystemAdmin_Reports', 'Generate system reports', 'ADMIN', 'SYSTEM', 'EXECUTE'),
        ('SystemAdmin_Settings', 'Modify system settings', 'ADMIN', 'SYSTEM', 'UPDATE'),
        ('SystemAdmin_Database', 'Database administration', 'ADMIN', 'SYSTEM', 'ADMIN'),
        ('Referral_Create', 'Create referral', 'CLINICAL', 'REFERRAL', 'CREATE'),
        ('Referral_Read', 'View referrals', 'CLINICAL', 'REFERRAL', 'READ'),
        ('Referral_Update', 'Update referral status', 'CLINICAL', 'REFERRAL', 'UPDATE'),
        ('Referral_Delete', 'Delete referral', 'CLINICAL', 'REFERRAL', 'DELETE')
) V(PermissionName, Description, Category, Module, ActionType)
WHERE NOT EXISTS (SELECT 1 FROM Auth.Permissions P WHERE P.PermissionName = V.PermissionName);
GO

PRINT '[3/4] Mapping role permissions...';
DECLARE @DefaultDate DATETIME = GETDATE(),
        @RoleId_ADMIN UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'ADMIN'),
        @RoleId_DOCTOR UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'DOCTOR'),
        @RoleId_NURSE UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'NURSE'),
        @RoleId_RECEPTIONIST UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'RECEPTIONIST'),
        @RoleId_PATIENT UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'PATIENT'),
        @RoleId_BILLING UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'BILLING'),
        @RoleId_PHARMACIST UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'PHARMACIST');

;WITH RolePermissionSource AS
(
    SELECT @RoleId_ADMIN AS RoleId, P.PermissionId FROM Auth.Permissions P
    UNION ALL
    SELECT @RoleId_DOCTOR, P.PermissionId FROM Auth.Permissions P WHERE P.PermissionName IN ('Patient_Create','Patient_Read','Patient_Update','Patient_ViewAll','MedicalHistory_Create','MedicalHistory_Read','MedicalHistory_Update','MedicalHistory_Delete','Appointment_Create','Appointment_Read','Appointment_Update','Appointment_Cancel','Appointment_ViewAll','Medication_Create','Medication_Read','Medication_Update','Medication_Delete','Medication_Manage','ConsultationNotes_Create','ConsultationNotes_Read','ConsultationNotes_Update','ConsultationNotes_Delete','Allergy_Create','Allergy_Read','Allergy_Update','Allergy_Delete','LabResults_Create','LabResults_Read','LabResults_Update','Referral_Create','Referral_Read','Referral_Update','Insurance_Read','Payment_View')
    UNION ALL
    SELECT @RoleId_NURSE, P.PermissionId FROM Auth.Permissions P WHERE P.PermissionName IN ('Patient_Read','Patient_Update','Patient_ViewAll','MedicalHistory_Create','MedicalHistory_Read','MedicalHistory_Update','Appointment_Read','Appointment_ViewAll','Medication_Read','Medication_Update','ConsultationNotes_Create','ConsultationNotes_Read','ConsultationNotes_Update','Allergy_Create','Allergy_Read','Allergy_Update','Allergy_Delete','LabResults_Create','LabResults_Read','LabResults_Update','Form_Read','Form_Submit','Form_Review','Payment_View')
    UNION ALL
    SELECT @RoleId_RECEPTIONIST, P.PermissionId FROM Auth.Permissions P WHERE P.PermissionName IN ('Patient_Create','Patient_Read','Patient_Update','Patient_ViewAll','Appointment_Create','Appointment_Read','Appointment_Update','Appointment_Cancel','Appointment_ViewAll','Form_Read','Form_Submit','Payment_View')
    UNION ALL
    SELECT @RoleId_PATIENT, P.PermissionId FROM Auth.Permissions P WHERE P.PermissionName IN ('Patient_Read','Patient_Update','MedicalHistory_Read','Appointment_Create','Appointment_Read','Appointment_Cancel','Medication_Read','ConsultationNotes_Read','Allergy_Read','LabResults_Read','Form_Read','Form_Submit','Insurance_Read','Payment_View')
    UNION ALL
    SELECT @RoleId_BILLING, P.PermissionId FROM Auth.Permissions P WHERE P.PermissionName IN ('Patient_Read','Patient_ViewAll','Appointment_Read','Appointment_ViewAll','Invoice_Create','Invoice_Read','Invoice_Update','Invoice_Delete','Payment_Process','Payment_View','Insurance_Create','Insurance_Read','Insurance_Update','Insurance_Delete')
    UNION ALL
    SELECT @RoleId_PHARMACIST, P.PermissionId FROM Auth.Permissions P WHERE P.PermissionName IN ('Patient_Read','Patient_ViewAll','Medication_Create','Medication_Read','Medication_Update','Medication_Delete','Medication_Manage','Allergy_Read')
)
INSERT INTO Auth.RolePermissions (RolePermissionId, RoleIdFK, PermissionIdFK, CreatedDate, CreatedBy)
SELECT NEWID(), S.RoleId, S.PermissionId, @DefaultDate, 'SYSTEM'
FROM RolePermissionSource S
WHERE S.RoleId IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1 FROM Auth.RolePermissions RP
      WHERE RP.RoleIdFK = S.RoleId
        AND RP.PermissionIdFK = S.PermissionId
  );
GO

PRINT '[4/4] Creating/validating admin user...';
DECLARE @DefaultDate DATETIME = GETDATE(),
        @AdminRoleId UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'ADMIN'),
        @AdminUserId UNIQUEIDENTIFIER;

-- Provide this securely at execution time:
--   sqlcmd -v ADMIN_PASSWORD_HASH="<bcrypt hash>"
-- If not provided and admin does not already exist, this script will fail.
DECLARE @AdminPasswordHash VARCHAR(MAX) = '$(ADMIN_PASSWORD_HASH)',
        @AdminPasswordHashPlaceholder VARCHAR(64) = CHAR(36) + '(ADMIN_PASSWORD_HASH)';

SELECT @AdminUserId = UserId FROM Auth.Users WHERE Username = 'admin';

IF @AdminUserId IS NULL
BEGIN
    IF NULLIF(LTRIM(RTRIM(ISNULL(@AdminPasswordHash, ''))), '') IS NULL
       OR @AdminPasswordHash = @AdminPasswordHashPlaceholder
        THROW 50001, 'ADMIN_PASSWORD_HASH is required to create admin user.', 1;

    SET @AdminUserId = NEWID();
    INSERT INTO Auth.Users (UserId, Username, Email, PasswordHash, FirstName, LastName, IsActive, LastLoginDate, CreatedDate, CreatedBy)
    VALUES (@AdminUserId, 'admin', 'admin@healthcareform.local', @AdminPasswordHash, 'System', 'Administrator', 1, NULL, @DefaultDate, 'SYSTEM');
END

IF NOT EXISTS (
    SELECT 1
    FROM Auth.UserRoles UR
    WHERE UR.UserIdFK = @AdminUserId
      AND UR.RoleIdFK = @AdminRoleId
)
BEGIN
    INSERT INTO Auth.UserRoles (UserRoleId, UserIdFK, RoleIdFK, CreatedDate, CreatedBy)
    VALUES (NEWID(), @AdminUserId, @AdminRoleId, @DefaultDate, 'SYSTEM');
END
GO

PRINT '================================================================================================';
PRINT 'Master data initialization complete: ' + CONVERT(VARCHAR(25), GETDATE(), 121);
PRINT 'Use ''005-table-inserts/014. Insert Allergies_Medications.sql'' to seed lookup allergies/medications.';
PRINT 'If triggers are missing, run ''007-triggers-functions/000. MASTER_DEPLOYMENT_SCRIPT.sql''.';
PRINT '================================================================================================';
GO
