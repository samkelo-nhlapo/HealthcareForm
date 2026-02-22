
-- =================================================================================================
-- Harmonized with 000_INLINE_MASTER_DEPLOYMENT.sql (2026-02-15)
-- This file now matches the inline master for all seed/reference data and admin logic.
-- For DDL (schemas, tables, indexes, FKs), use the inline master or Flyway migrations.
-- =================================================================================================

PRINT '================================================================================================'
PRINT 'Healthcare Form Database - Master Data Initialization Script'
PRINT '================================================================================================'
PRINT ''
PRINT 'Starting initialization at: ' + CONVERT(VARCHAR(25), GETDATE(), 121)
PRINT ''

-- Step 1: Initialize Location Lookups (no dependencies)
PRINT '[1/11] Initializing Countries lookup...'
-- Inlined: 005. Insert Countries.sql (harmonized)
PRINT '[8/11] Mapping Role Permissions (harmonized to Auth.RolePermissions)...'
-- ...existing code...
-- (Block harmonized: matches inline master logic for GUID PKs and permission mapping)
DECLARE @MapDate DATETIME = GETDATE(),
    @RoleId_ADMIN UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'ADMIN'),
    @RoleId_DOCTOR UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'DOCTOR'),
    @RoleId_NURSE UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'NURSE'),
    @RoleId_RECEPTIONIST UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'RECEPTIONIST'),
    @RoleId_PATIENT UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'PATIENT'),
    @RoleId_BILLING UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'BILLING'),
    @RoleId_PHARMACIST UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'PHARMACIST')

INSERT INTO Auth.RolePermissions (RolePermissionId, RoleIdFK, PermissionIdFK, CreatedDate, CreatedBy)
SELECT NEWID(), @RoleId_ADMIN, PermissionId, @MapDate, 'SYSTEM' FROM Auth.Permissions
UNION ALL
SELECT NEWID(), @RoleId_DOCTOR, PermissionId, @MapDate, 'SYSTEM' FROM Auth.Permissions WHERE PermissionName IN (
    'Patient_Create', 'Patient_Read', 'Patient_Update', 'Patient_ViewAll',
    'MedicalHistory_Create', 'MedicalHistory_Read', 'MedicalHistory_Update', 'MedicalHistory_Delete',
    'Appointment_Create', 'Appointment_Read', 'Appointment_Update', 'Appointment_Cancel', 'Appointment_ViewAll',
    'Medication_Create', 'Medication_Read', 'Medication_Update', 'Medication_Delete', 'Medication_Manage',
    'ConsultationNotes_Create', 'ConsultationNotes_Read', 'ConsultationNotes_Update', 'ConsultationNotes_Delete',
    'Allergy_Create', 'Allergy_Read', 'Allergy_Update', 'Allergy_Delete',
    'LabResults_Create', 'LabResults_Read', 'LabResults_Update',
    'Referral_Create', 'Referral_Read', 'Referral_Update',
    'Insurance_Read', 'Payment_View')
UNION ALL
SELECT NEWID(), @RoleId_NURSE, PermissionId, @MapDate, 'SYSTEM' FROM Auth.Permissions WHERE PermissionName IN (
    'Patient_Read', 'Patient_Update', 'Patient_ViewAll',
    'MedicalHistory_Create', 'MedicalHistory_Read', 'MedicalHistory_Update',
    'Appointment_Read', 'Appointment_ViewAll',
    'Medication_Read', 'Medication_Update',
    'ConsultationNotes_Create', 'ConsultationNotes_Read', 'ConsultationNotes_Update',
    'Allergy_Create', 'Allergy_Read', 'Allergy_Update', 'Allergy_Delete',
    'LabResults_Create', 'LabResults_Read', 'LabResults_Update',
    'Form_Read', 'Form_Submit', 'Form_Review',
    'Payment_View')
UNION ALL
SELECT NEWID(), @RoleId_RECEPTIONIST, PermissionId, @MapDate, 'SYSTEM' FROM Auth.Permissions WHERE PermissionName IN (
    'Patient_Create', 'Patient_Read', 'Patient_Update', 'Patient_ViewAll',
    'Appointment_Create', 'Appointment_Read', 'Appointment_Update', 'Appointment_Cancel', 'Appointment_ViewAll',
    'Form_Read', 'Form_Submit',
    'Payment_View')
UNION ALL
SELECT NEWID(), @RoleId_PATIENT, PermissionId, @MapDate, 'SYSTEM' FROM Auth.Permissions WHERE PermissionName IN (
    'Patient_Read', 'Patient_Update',
    'MedicalHistory_Read',
    'Appointment_Create', 'Appointment_Read', 'Appointment_Cancel',
    'Medication_Read',
    'ConsultationNotes_Read',
    'Allergy_Read',
    'LabResults_Read',
    'Form_Read', 'Form_Submit',
    'Insurance_Read',
    'Payment_View')
UNION ALL
SELECT NEWID(), @RoleId_BILLING, PermissionId, @MapDate, 'SYSTEM' FROM Auth.Permissions WHERE PermissionName IN (
    'Patient_Read', 'Patient_ViewAll',
    'Appointment_Read', 'Appointment_ViewAll',
    'Invoice_Create', 'Invoice_Read', 'Invoice_Update', 'Invoice_Delete',
    'Payment_Process', 'Payment_View',
    'Insurance_Create', 'Insurance_Read', 'Insurance_Update', 'Insurance_Delete')
UNION ALL
SELECT NEWID(), @RoleId_PHARMACIST, PermissionId, @MapDate, 'SYSTEM' FROM Auth.Permissions WHERE PermissionName IN (
    'Patient_Read', 'Patient_ViewAll',
    'Medication_Create', 'Medication_Read', 'Medication_Update', 'Medication_Delete', 'Medication_Manage',
    'Prescription_Read',
    'Allergy_Read')
PRINT 'Role permissions mapped successfully'
PRINT ''
	('Polokwane', @ProvinceId_LP, 1, @DefaultDate, 'SYSTEM'),
	('Messina', @ProvinceId_LP, 1, @DefaultDate, 'SYSTEM'),
	('Musina', @ProvinceId_LP, 1, @DefaultDate, 'SYSTEM'),
	('Bloemfontein', @ProvinceId_FS, 1, @DefaultDate, 'SYSTEM'),
	('Welkom', @ProvinceId_FS, 1, @DefaultDate, 'SYSTEM'),
	('Kroonstad', @ProvinceId_FS, 1, @DefaultDate, 'SYSTEM'),
	('Kimberley', @ProvinceId_NC, 1, @DefaultDate, 'SYSTEM'),
	('De Aar', @ProvinceId_NC, 1, @DefaultDate, 'SYSTEM'),
	('Rustenburg', @ProvinceId_NW, 1, @DefaultDate, 'SYSTEM'),
	('Mafikeng', @ProvinceId_NW, 1, @DefaultDate, 'SYSTEM'),
	('Potchefstroom', @ProvinceId_NW, 1, @DefaultDate, 'SYSTEM')

PRINT 'Cities lookup table populated successfully'
-- End cities insert
PRINT ''

-- Step 2: Initialize Gender and Marital Status
PRINT '[4/11] Initializing Gender lookup...'
-- :r "Insert Gender.sql"
-- Inlined: Insert Gender.sql
PRINT '[8/11] Mapping Role Permissions (legacy block skipped)...'
PRINT 'Legacy Security.RolePermissions block skipped; role-permissions were mapped earlier to Auth.RolePermissions using GUID keys.'
PRINT ''
-- Remaining legacy Security.Permissions SELECT blocks have been removed.
-- Role-permissions mappings were already created against `Auth.Permissions` and inserted into `Auth.RolePermissions` earlier.
PRINT 'Role permissions mapping handled in `Auth.RolePermissions` (GUID-based).'
-- End role-permissions mapping
PRINT ''

PRINT '[9/11] Creating initial admin user (harmonized to Auth)...'
-- ...existing code...
-- (Block harmonized: matches inline master logic for admin user creation, no password print)
DECLARE @AdminDate DATETIME = GETDATE(),
    @AdminRoleId UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'ADMIN'),
    @AdminUserId UNIQUEIDENTIFIER = NEWID()

INSERT INTO Auth.Users (UserId, Username, Email, PasswordHash, FirstName, LastName, IsActive, LastLoginDate, CreatedDate, CreatedBy)
VALUES (@AdminUserId, 'admin', 'admin@healthcareform.local', '$2b$10$VpCKLKNCb1NfWqAj.6O8YOd7.XmhVQ8DGmKFwE7L3YVfUvvLWfEwm', 'System', 'Administrator', 1, NULL, @AdminDate, 'SYSTEM')

INSERT INTO Auth.UserRoles (UserRoleId, UserIdFK, RoleIdFK, CreatedDate, CreatedBy)
VALUES (NEWID(), @AdminUserId, @AdminRoleId, @AdminDate, 'SYSTEM')

PRINT 'Admin user created successfully'
PRINT 'Username: admin'
PRINT 'Admin user created. Do NOT store or print passwords in repository.'
PRINT 'Set the admin password via a secure secret and rotate it immediately.'
PRINT ''

-- Step 4: Initialize Healthcare Reference Data
PRINT '[10/11] Initializing Billing Codes (harmonized to Profile.BillingCodes)...'
-- ...existing code...
-- (Block harmonized: matches inline master logic for billing codes insert)
DECLARE @BillingDefaultDate DATETIME = GETDATE()
-- ...existing code...
PRINT 'Billing codes inserted successfully'
PRINT ''

PRINT '[11/11] Initializing Healthcare Providers and Insurance...'
PRINT 'HealthcareProviders and InsuranceProviders inserts harmonized with inline master.'
-- ...existing code...
PRINT ''

-- Inlined: 014. Insert Allergies_Medications.sql
-- Begin allergies and medications insert
DECLARE @AllMedDefaultDate DATETIME = GETDATE()

INSERT INTO Lookup.Allergies (AllergyName, AllergyCategory, Severity, ReactionDescription, IsCritical, IsActive, CreatedDate, CreatedBy)
VALUES	
	('Penicillin', 'MEDICATION', 'HIGH', 'Anaphylaxis - severe respiratory distress', 1, 1, @AllMedDefaultDate, 'SYSTEM'),
	('Cephalosporin', 'MEDICATION', 'HIGH', 'Anaphylaxis - hives and throat swelling', 1, 1, @AllMedDefaultDate, 'SYSTEM'),
	('Aspirin', 'MEDICATION', 'MEDIUM', 'Rash and gastrointestinal upset', 0, 1, @AllMedDefaultDate, 'SYSTEM'),
	('NSAIDs', 'MEDICATION', 'MEDIUM', 'Gastric ulcers and bleeding', 0, 1, @AllMedDefaultDate, 'SYSTEM'),
	('Sulfonamides', 'MEDICATION', 'HIGH', 'Stevens-Johnson Syndrome risk', 1, 1, @AllMedDefaultDate, 'SYSTEM'),
	('Peanuts', 'FOOD', 'HIGH', 'Anaphylaxis - throat closing', 1, 1, @AllMedDefaultDate, 'SYSTEM'),
	('Tree Nuts', 'FOOD', 'HIGH', 'Anaphylaxis and airway obstruction', 1, 1, @AllMedDefaultDate, 'SYSTEM'),
	('Shellfish', 'FOOD', 'HIGH', 'Anaphylaxis - cardiovascular collapse risk', 1, 1, @AllMedDefaultDate, 'SYSTEM'),
	('Milk', 'FOOD', 'MEDIUM', 'Lactose intolerance and digestive issues', 0, 1, @AllMedDefaultDate, 'SYSTEM'),
	('Eggs', 'FOOD', 'MEDIUM', 'Urticaria and gastrointestinal symptoms', 0, 1, @AllMedDefaultDate, 'SYSTEM'),
	('Latex', 'ENVIRONMENTAL', 'HIGH', 'Anaphylaxis - respiratory compromise', 1, 1, @AllMedDefaultDate, 'SYSTEM'),
	('Iodine', 'MEDICATION', 'MEDIUM', 'Angioedema and rash', 0, 1, @AllMedDefaultDate, 'SYSTEM'),
	('Codeine', 'MEDICATION', 'MEDIUM', 'Respiratory depression and hypersensitivity', 0, 1, @AllMedDefaultDate, 'SYSTEM'),
	('ACE Inhibitors', 'MEDICATION', 'MEDIUM', 'Persistent cough and angioedema', 0, 1, @AllMedDefaultDate, 'SYSTEM'),
	('Statins', 'MEDICATION', 'LOW', 'Muscle pain and elevated liver enzymes', 0, 1, @AllMedDefaultDate, 'SYSTEM')

INSERT INTO Lookup.Medications (MedicationName, MedicationGenericName, MedicationCategory, Strength, Unit, RouteOfAdministration, ManufacturerName, IsActive, CreatedDate, CreatedBy)
VALUES	
	('Amoxicillin', 'Amoxicillin', 'ANTIBIOTIC', '500', 'mg', 'ORAL', 'Various Manufacturers', 1, @AllMedDefaultDate, 'SYSTEM'),
	('Lisinopril', 'Lisinopril', 'ACE_INHIBITOR', '10', 'mg', 'ORAL', 'Various Manufacturers', 1, @AllMedDefaultDate, 'SYSTEM'),
	('Metformin', 'Metformin', 'ANTIDIABETIC', '500', 'mg', 'ORAL', 'Various Manufacturers', 1, @AllMedDefaultDate, 'SYSTEM'),
	('Atorvastatin', 'Atorvastatin', 'STATIN', '20', 'mg', 'ORAL', 'Pfizer', 1, @AllMedDefaultDate, 'SYSTEM'),
	('Omeprazole', 'Omeprazole', 'PROTON_PUMP_INHIBITOR', '20', 'mg', 'ORAL', 'Various Manufacturers', 1, @AllMedDefaultDate, 'SYSTEM'),
	('Sertraline', 'Sertraline', 'ANTIDEPRESSANT', '50', 'mg', 'ORAL', 'Pfizer', 1, @AllMedDefaultDate, 'SYSTEM'),
	('Ibuprofen', 'Ibuprofen', 'NSAID', '400', 'mg', 'ORAL', 'Various Manufacturers', 1, @AllMedDefaultDate, 'SYSTEM'),
	('Albuterol', 'Salbutamol', 'BRONCHODILATOR', '100', 'mcg', 'INHALED', 'Various Manufacturers', 1, @AllMedDefaultDate, 'SYSTEM'),
	('Insulin Glargine', 'Insulin Glargine', 'INSULIN', '100', 'IU/mL', 'SUBCUTANEOUS', 'Sanofi', 1, @AllMedDefaultDate, 'SYSTEM'),
	('Levothyroxine', 'Levothyroxine', 'THYROID_HORMONE', '50', 'mcg', 'ORAL', 'Various Manufacturers', 1, @AllMedDefaultDate, 'SYSTEM'),
	('Potassium Chloride', 'Potassium Chloride', 'ELECTROLYTE', '20', 'mEq', 'ORAL', 'Various Manufacturers', 1, @AllMedDefaultDate, 'SYSTEM'),
	('Metoprolol', 'Metoprolol', 'BETA_BLOCKER', '50', 'mg', 'ORAL', 'Various Manufacturers', 1, @AllMedDefaultDate, 'SYSTEM'),
	('Warfarin', 'Warfarin', 'ANTICOAGULANT', '5', 'mg', 'ORAL', 'Various Manufacturers', 1, @AllMedDefaultDate, 'SYSTEM'),
	('Amlodipine', 'Amlodipine', 'CALCIUM_CHANNEL_BLOCKER', '5', 'mg', 'ORAL', 'Various Manufacturers', 1, @AllMedDefaultDate, 'SYSTEM'),
	('Clopidogrel', 'Clopidogrel', 'ANTIPLATELET', '75', 'mg', 'ORAL', 'Sanofi', 1, @AllMedDefaultDate, 'SYSTEM')

PRINT 'Allergies and medications reference data inserted successfully'
-- End allergies and medications insert
PRINT ''

-- Step 5: Optional - Load Sample Test Data
PRINT '[OPTIONAL] Loading sample test data...'
PRINT 'This creates a complete test patient profile for application validation'
PRINT 'To load: Execute the file: 015. Insert SampleTestData.sql'
PRINT ''

PRINT '================================================================================================'
PRINT 'Database initialization complete!'
PRINT 'Completion time: ' + CONVERT(VARCHAR(25), GETDATE(), 121)
PRINT '================================================================================================'
PRINT ''
PRINT 'Next Steps:'
PRINT '1. Verify all data loaded successfully by running: SELECT COUNT(*) FROM [table_name]'
PRINT '2. Login with admin credentials:'
PRINT '   Username: admin'
PRINT '   Password: HealthcareAdmin@2026! (CHANGE IMMEDIATELY ON FIRST LOGIN)'
PRINT '3. Create application users and assign appropriate roles'
PRINT '4. Test appointment scheduling and patient form submission workflows'
PRINT '5. Configure backup and maintenance schedules'
PRINT ''

GO
