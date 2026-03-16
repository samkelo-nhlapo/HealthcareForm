# Complete Healthcare Database Schema - Implementation Guide

## Overview
This document describes the core patient-centric tables and workflows for the Healthcare Form database.
For the full, authoritative list of tables and deployment order, see `001-database/003-tables/`
and `001-database/000_MODULAR_MASTER_DEPLOYMENT.sql`.

## Database Schema Summary

### Total Tables: 45 (see table scripts for the full list)

**Foundational Tables (subset):**
- Profile.Patient, Gender, MaritalStatus
- Contacts: Phones, Emails, EmergencyContacts, PatientPhones, PatientEmails
- Location: Countries, Provinces, Cities, Address
- Auth: AuditLog, DB_Errors
- Exceptions: Errors

**Key Domain Tables (24):**

### 1. MEDICAL/HEALTH RECORDS (5 tables)
```
Profile.MedicalHistory       - Chronic conditions, past medical events
Profile.Allergies            - Drug, food, environmental allergies
Profile.Medications          - Current prescriptions and medications
Profile.Vaccinations         - Immunization records
Profile.LabResults           - Lab tests and diagnostic results
```

### 2. FORMS & SUBMISSIONS (4 tables)
```
Contacts.FormTemplates       - Form definitions for different types
Contacts.FormSubmissions     - Patient form submission tracking
Contacts.FormFieldValues     - Individual form field answers
Contacts.FormAttachments     - Supporting documents and files
```

### 3. HEALTHCARE SERVICES (5 tables)
```
Profile.HealthcareProviders  - Doctors and healthcare staff
Profile.Appointments         - Appointment scheduling
Profile.ConsultationNotes    - Doctor visit notes and diagnosis
Profile.Referrals            - Specialist referrals
(Prescriptions functionality integrated in Medications table)
```

### 4. INSURANCE & BILLING (4 tables)
```
Profile.InsuranceProviders   - Insurance company information
Profile.PatientInsurance     - Patient insurance policies
Profile.BillingCodes         - ICD-10, CPT, HCPCS codes
Profile.Invoices             - Patient billing and invoices
```

### 5. SECURITY & ACCESS CONTROL (6 tables)
```
Auth.Users                   - System user accounts
Auth.Roles                   - Role definitions (ADMIN, DOCTOR, NURSE, etc.)
Auth.UserRoles               - User-to-Role assignments
Auth.Permissions             - Fine-grained permissions
Auth.RolePermissions         - Role-to-Permission assignments
Auth.UserActivityAudit       - Login/logout and activity tracking
```

---

## Deployment Order (Core Subset)

Follow this sequence to avoid foreign key constraint violations for the core tables.
For the complete deployment order (all tables and dependencies), use the master scripts in
`001-database/000_MODULAR_MASTER_DEPLOYMENT.sql` and `001-database/003-tables/000. MASTER_DEPLOYMENT_SCRIPT.sql`.

### Phase 1: Core Infrastructure (If not already done)
```
1. 001. Database & FileGroups/001. Healthcare form.sql
2. 002. Schema/001. Schema's Script.sql
3. 007. Triggers & Functions/dbo.CapitalizeFirstLetter.sql
4. 007. Triggers & Functions/Contacts.FormatPhoneNumber.sql
5. 007. Triggers & Functions/dbo.ValidateEmail.sql
```

### Phase 2: Existing Tables (If not already done)
```
6. 003. Tables/[Profile].[Gender].sql
7. 003. Tables/[Profile].[MaritalStatus].sql
8. 003. Tables/[Location].[Countries].sql
9. 003. Tables/[Location].[Provinces].sql
10. 003. Tables/[Location].[Cities].sql
11. 003. Tables/[Location].[Address].sql
12. 003. Tables/[Contacts].[Phones].sql
13. 003. Tables/[Contacts].[Emails].sql
14. 003. Tables/[Contacts].[EmergencyContacts].sql
15. 003. Tables/[Profile].[Patient].sql
16. 003. Tables/[Contacts].[PatientPhones].sql
17. 003. Tables/[Contacts].[PatientEmails].sql
18. 003. Tables/[Auth].[AuditLog].sql
19. 003. Tables/[Exceptions].[Errors].sql
```

### Phase 3: NEW Medical/Health Tables
```
20. 003. Tables/[Profile].[MedicalHistory].sql
21. 003. Tables/[Profile].[Allergies].sql
22. 003. Tables/[Profile].[Medications].sql
23. 003. Tables/[Profile].[Vaccinations].sql
24. 003. Tables/[Profile].[LabResults].sql
```

### Phase 4: NEW Forms Tables
```
25. 003. Tables/[Contacts].[FormTemplates].sql
26. 003. Tables/[Contacts].[FormSubmissions].sql
27. 003. Tables/[Contacts].[FormFieldValues].sql
28. 003. Tables/[Contacts].[FormAttachments].sql
```

### Phase 5: NEW Healthcare Services Tables
```
29. 003. Tables/[Profile].[HealthcareProviders].sql
30. 003. Tables/[Profile].[Appointments].sql
31. 003. Tables/[Profile].[ConsultationNotes].sql
32. 003. Tables/[Profile].[Referrals].sql
```

### Phase 6: NEW Insurance & Billing Tables
```
33. 003. Tables/[Profile].[InsuranceProviders].sql
34. 003. Tables/[Profile].[PatientInsurance].sql
35. 003. Tables/[Profile].[BillingCodes].sql
36. 003. Tables/[Profile].[Invoices].sql
```

### Phase 7: NEW Security & Access Tables
```
37. 003. Tables/[Auth].[Users].sql
38. 003. Tables/[Auth].[Roles].sql
39. 003. Tables/[Auth].[Permissions].sql
40. 003. Tables/[Auth].[UserRoles].sql
41. 003. Tables/[Auth].[RolePermissions].sql
42. 003. Tables/[Auth].[UserActivityAudit].sql
```

### Phase 8: Initialize Default Data
```
43. Create default roles (ADMIN, DOCTOR, NURSE, RECEPTIONIST, PATIENT, BILLING, PHARMACIST)
44. Create default permissions
45. Create initial admin user
```

### Phase 9: Create Stored Procedures & Triggers
```
46. Update/create stored procedures for new tables
47. Create audit triggers for data modification
```

---

## Key Relationships & Constraints

### Patient-Centric Hub
```
Patient (center)
├── MedicalHistory
├── Allergies
├── Medications
├── Vaccinations
├── LabResults
├── Appointments → HealthcareProviders
├── ConsultationNotes → HealthcareProviders
├── PatientInsurance → InsuranceProviders
├── Invoices → HealthcareProviders, BillingCodes
└── Referrals → HealthcareProviders
```

### Form Processing Workflow
```
FormTemplates
└── FormSubmissions (instance of template)
    ├── FormFieldValues (answers)
    └── FormAttachments (supporting docs)
```

### Access Control Hierarchy
```
Users
├── UserRoles → Roles
│   └── RolePermissions → Permissions
└── UserActivityAudit (logging)
```

---

## Common Queries

### Get Patient's Active Allergies
```sql
SELECT a.AllergyId, a.AllergenName, a.Reaction, a.Severity
FROM Profile.Allergies a
WHERE a.PatientIdFK = @PatientId AND a.IsActive = 1
ORDER BY a.Severity DESC;
```

### Get Patient's Current Medications
```sql
SELECT m.MedicationName, m.Dosage, m.Frequency, m.Status
FROM Profile.Medications m
WHERE m.PatientIdFK = @PatientId AND m.Status = 'Active'
ORDER BY m.StartDate DESC;
```

### Get Patient's Upcoming Appointments
```sql
SELECT a.AppointmentDateTime, p.FirstName, p.LastName, a.AppointmentType, a.Status
FROM Profile.Appointments a
INNER JOIN Profile.HealthcareProviders p ON a.ProviderIdFK = p.ProviderId
WHERE a.PatientIdFK = @PatientId 
  AND a.AppointmentDateTime >= GETDATE()
  AND a.Status IN ('Scheduled', 'In Progress')
ORDER BY a.AppointmentDateTime;
```

### Get Patient's Insurance Status
```sql
SELECT pi.PolicyNumber, pi.CoveragePlan, ip.ProviderName, pi.ExpiryDate, pi.Status
FROM Profile.PatientInsurance pi
INNER JOIN Profile.InsuranceProviders ip ON pi.InsuranceProviderIdFK = ip.InsuranceProviderId
WHERE pi.PatientIdFK = @PatientId AND pi.Status = 'Active';
```

### Get Form Submission Status
```sql
SELECT fs.FormName, fs.Status, fs.SubmissionDate, fs.CompletionDate
FROM Contacts.FormSubmissions fs
INNER JOIN Contacts.FormTemplates ft ON fs.FormTemplateIdFK = ft.FormTemplateId
WHERE fs.PatientIdFK = @PatientId
ORDER BY fs.SubmissionDate DESC;
```

### User Login Activity Report
```sql
SELECT u.Username, uaa.ActivityDateTime, uaa.ActivityType, uaa.Status, uaa.IPAddress
FROM Auth.UserActivityAudit uaa
INNER JOIN Auth.Users u ON uaa.UserIdFK = u.UserId
WHERE uaa.ActivityType = 'Login'
ORDER BY uaa.ActivityDateTime DESC;
```

---

## Initial Data Setup

### Step 1: Create Standard Roles
```sql
INSERT INTO Auth.Roles (RoleName, Description) VALUES
('ADMIN', 'System administrator with full access'),
('DOCTOR', 'Healthcare provider - can view/manage patient records'),
('NURSE', 'Nursing staff - limited patient record access'),
('RECEPTIONIST', 'Front desk - appointment and contact management'),
('PATIENT', 'Patient - read-only access to own records'),
('BILLING', 'Billing department - invoice and insurance management'),
('PHARMACIST', 'Pharmacy - medication verification and tracking');
```

### Step 2: Create Sample Permissions
```sql
INSERT INTO Auth.Permissions (PermissionName, Category, Module, ActionType, Description) VALUES
('Patient_Create', 'Patient', 'PatientManagement', 'Create', 'Create new patient'),
('Patient_Read', 'Patient', 'PatientManagement', 'Read', 'View patient records'),
('Patient_Update', 'Patient', 'PatientManagement', 'Update', 'Update patient info'),
('Patient_Delete', 'Patient', 'PatientManagement', 'Delete', 'Delete patient record'),
('Medication_Read', 'Medication', 'MedicationManagement', 'Read', 'View medications'),
('Appointment_Schedule', 'Appointment', 'AppointmentMgmt', 'Create', 'Schedule appointments'),
('Invoice_Approve', 'Billing', 'BillingMgmt', 'Approve', 'Approve invoices for payment'),
('Form_Submit', 'Forms', 'FormMgmt', 'Create', 'Submit healthcare forms');
```

### Step 3: Create Initial Admin User
```sql
DECLARE @AdminId UNIQUEIDENTIFIER = NEWID();
INSERT INTO Auth.Users 
(UserId, Username, Email, PasswordHash, FirstName, LastName, IsSuperAdmin, IsActive)
VALUES
(@AdminId, 'admin', 'admin@healthcareform.local', 'HASH_OF_PASSWORD', 'System', 'Administrator', 1, 1);

-- Assign ADMIN role
INSERT INTO Auth.UserRoles (UserIdFK, RoleIdFK, AssignedBy)
VALUES (@AdminId, (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'ADMIN'), 'SYSTEM');
```

---

## Performance Optimization

All tables include:
- ✓ Clustered primary key indexes
- ✓ Non-clustered indexes on foreign keys
- ✓ Non-clustered indexes on frequently queried columns
- ✓ Proper statistics tracking

### Query Performance Tips
1. Always filter by PatientId when accessing patient-related data
2. Use FormSubmission status filters to find pending forms
3. Check UserActivityAudit for compliance reporting
4. Maintain indexes on Date columns for range queries

---

## Backup & Recovery Strategy

### Daily Backup Schedule
- **Full Backup**: 02:00 UTC (daily)
- **Differential Backup**: Every 6 hours
- **Transaction Log Backup**: Every 15 minutes (FULL recovery model required)

### Retention Policy
- Full backups: 30 days
- Differential backups: 7 days
- Transaction logs: 30 days
- Archive old patient records quarterly

### Disaster Recovery
- Backup location: Separate physical drive/server
- Test restore procedures monthly
- Document RTO/RPO requirements (typically 1 hour for healthcare)

---

## Compliance & Security

### HIPAA Compliance Checklist
- ✓ Audit trails (UserActivityAudit, AuditLog)
- ✓ Access control (Roles, Permissions)
- ✓ User authentication (Users, password hashing)
- ✓ Form signatures and dates tracked
- ✓ Medical record retention and deletion policies
- ⚠ Implement field-level encryption for sensitive data (TODO)
- ⚠ Implement data anonymization for testing (TODO)

### Security Recommendations
1. Hash all passwords using bcrypt/PBKDF2
2. Encrypt sensitive columns: SSN, insurance policy, phone numbers
3. Implement row-level security (RLS) for patients
4. Audit all data access, not just modifications
5. Implement session timeouts and account lockouts
6. Regular security patches for SQL Server

---

## Migration from Old Schema

If migrating from existing database:

```sql
-- Migrate existing appointment data if applicable
-- Migrate existing lab results if available
-- Preserve audit history by updating CreatedDate and CreatedBy

-- Update audit columns on existing Patient records
UPDATE Profile.Patient
SET CreatedDate = GETDATE(),
    CreatedBy = 'MIGRATION',
    UpdatedDate = GETDATE(),
    UpdatedBy = 'MIGRATION'
WHERE CreatedDate IS NULL;
```

---

## Support & Troubleshooting

### Common Issues

**FK Constraint Violation**: Ensure parent records exist before inserting child records
**Permission Denied**: Check UserRoles and RolePermissions for current user
**Slow Queries**: Check index fragmentation, update statistics, review execution plans
**Form Submission Failures**: Validate all required FormFieldValues present

### Maintenance Tasks

```sql
-- Update statistics (daily)
EXEC sp_updatestats;

-- Check index fragmentation (weekly)
SELECT * FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED')
WHERE avg_fragmentation_in_percent > 10;

-- Rebuild fragmented indexes (monthly)
ALTER INDEX ALL ON [Table_Name] REBUILD;

-- DBCC Check integrity (weekly)
DBCC CHECKDB (HealthcareForm, REPAIR_ALLOW_DATA_LOSS);
```

---

## Documentation Version
- **Version**: 1.0
- **Date**: February 14, 2026
- **Author**: Samkelo Nhlapo
- **Status**: Production Ready
