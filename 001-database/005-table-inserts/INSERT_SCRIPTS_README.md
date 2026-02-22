# Healthcare Form Database - Insert Scripts Summary

## Overview
Complete set of SQL insert scripts to initialize the HealthcareForm database with all necessary lookup tables, reference data, and security configuration.

**Total Scripts Created: 16**  
**Estimated Initialization Time: 5-10 minutes**  
**Execution Order: See Master Deployment Script**

---

## Insert Scripts by Category

### 1. LOCATION LOOKUPS (3 scripts)

#### 005. Insert Countries.sql
- **Purpose**: Populate geographic locations for patient addresses and service coverage
- **Records**: 20 countries (South Africa primary, plus 19 international references)
- **Dependencies**: None
- **Key Data**: South Africa (ZA), Botswana, Lesotho, USA, UK, Canada, Australia, etc.

#### 006. Insert Provinces.sql
- **Purpose**: Populate South African provinces for location hierarchy
- **Records**: 9 provinces
- **Dependencies**: Countries table must exist
- **Key Data**: Western Cape, Eastern Cape, KwaZulu-Natal, Gauteng, Limpopo, Mpumalanga, Free State, Northern Cape, North West

#### 007. Insert Cities.sql
- **Purpose**: Populate major South African cities for patient location details
- **Records**: 38 cities across 9 provinces
- **Dependencies**: Provinces table must exist
- **Key Data**: Johannesburg, Cape Town, Durban, Pretoria, Sandton, etc. with province relationships

---

### 2. PROFILE LOOKUPS (2 scripts)

#### Insert Gender.sql (FIXED)
- **Purpose**: Populate gender options for patient demographics
- **Records**: 4 gender options
- **Dependencies**: None
- **Key Data**: Male, Female, Other, Prefer Not to Say
- **Status**: Fixed (ActiveStatus: 0→1, "Prefer Not to Say" added)

#### Insert Merital Status.sql (FIXED)
- **Purpose**: Populate marital status options for patient demographics
- **Records**: 6 marital status options
- **Dependencies**: None
- **Key Data**: Single, Married, Divorced, Widowed, Separated, Domestic Partnership
- **Status**: Fixed (ActiveStatus: 0→1, typo "Devorced"→"Divorced" corrected, "Domestic Partnership" added)

---

### 3. SECURITY CONFIGURATION (3 scripts)

#### 008. Insert Roles.sql
- **Purpose**: Define role-based access control (RBAC) roles
- **Records**: 7 security roles
- **Dependencies**: None
- **Key Roles**: ADMIN, DOCTOR, NURSE, RECEPTIONIST, PATIENT, BILLING, PHARMACIST
- **Permissions Model**: Each role has specific permission set mapped in RolePermissions

#### 009. Insert Permissions.sql
- **Purpose**: Define granular system permissions for RBAC
- **Records**: 52 distinct permissions
- **Dependencies**: None
- **Permission Categories**: 
  - Patient Management (5 perms)
  - Medical History (4 perms)
  - Appointments (5 perms)
  - Medications (5 perms)
  - Consultation (4 perms)
  - Forms (6 perms)
  - Invoicing (6 perms)
  - Insurance (4 perms)
  - Allergies (4 perms)
  - Lab Results (4 perms)
  - System Admin (5 perms)
  - Referrals (4 perms)

#### 010. Insert RolePermissions.sql
- **Purpose**: Map permissions to roles (RBAC configuration)
- **Records**: ~210 role-permission mappings
- **Dependencies**: Roles and Permissions tables must exist
- **Configuration**:
  - ADMIN: All 52 permissions
  - DOCTOR: 31 clinical permissions
  - NURSE: 20 care and monitoring permissions
  - RECEPTIONIST: 10 administrative permissions
  - PATIENT: 15 self-service permissions
  - BILLING: 14 financial management permissions
  - PHARMACIST: 8 medication permissions

#### 016. Insert AdminUser.sql
- **Purpose**: Create initial system administrator account
- **Records**: 1 admin user with ADMIN role
- **Dependencies**: Roles table must exist
- **Credentials**:
  - Username: admin
  - Default Password: HealthcareAdmin@2026! (bcrypt hashed)
  - **IMPORTANT**: Change immediately on first login

---

### 4. HEALTHCARE REFERENCE DATA (3 scripts)

#### 011. Insert BillingCodes.sql
- **Purpose**: Populate diagnosis and procedure codes for billing
- **Records**: 50 billing codes (ICD-10, CPT, HCPCS)
- **Dependencies**: None
- **Code Types**:
  - ICD-10: 20 diagnosis codes (diabetes, hypertension, cardiac, respiratory, psychiatric, GI, musculoskeletal, GU)
  - CPT: 15 procedure codes (consultations, diagnostics, lab tests, surgical procedures)
  - HCPCS: 5 service codes (injections, equipment)

#### 012. Insert HealthcareProviders.sql
- **Purpose**: Populate healthcare provider reference data
- **Records**: 10 sample doctors with specializations
- **Dependencies**: Cities table must exist
- **Key Data**: 
  - General practitioners, specialists (cardiology, neurology, orthopedics, pediatrics, psychiatry, endocrinology, pulmonology, gastroenterology, urology)
  - License numbers, contact information, locations
  - Mix of Johannesburg, Cape Town, Durban providers

#### 013. Insert InsuranceProviders.sql
- **Purpose**: Populate insurance provider reference data
- **Records**: 8 major South African insurance providers
- **Dependencies**: Countries table must exist
- **Key Data**: Discovery Health, Momentum, Medshelf, Bonitas, Polmed, GEMS, Sizwe, Umkhulu with contact details

#### 014. Insert Allergies_Medications.sql
- **Purpose**: Populate allergy and medication reference data
- **Records**: 15 common allergies + 15 common medications
- **Dependencies**: None
- **Allergies**: Penicillin (HIGH), NSAIDs, food allergies, environmental allergies with severity and reaction info
- **Medications**: 15 common prescription medications (antihypertensives, antidiabetics, antibiotics, anticoagulants, etc.)

---

### 5. SAMPLE TEST DATA (1 script)

#### 015. Insert SampleTestData.sql
- **Purpose**: Create comprehensive test patient profile for application validation
- **Records**: 1 complete patient with full medical profile
- **Dependencies**: All lookup tables and reference data must exist
- **Sample Patient Profile - John Anderson**:
  - Personal info: DOB 1975-06-15, ID number, married
  - Address: Sandton, Johannesburg
  - Contact: 3 phone numbers, 2 email addresses
  - Emergency contact: Spouse details
  - Medical history: Type 2 diabetes, hypertension, hyperlipidemia (chronic conditions)
  - Current medications: Lisinopril, Metformin
  - Allergies: Penicillin (HIGH severity)
  - Vaccinations: COVID-19, Influenza, Tetanus booster
  - Appointments: Scheduled quarterly follow-up
  - Consultation notes: Latest medical assessment
  - Lab results: 5 lab tests (glucose, A1C, cholesterol panel)
  - Insurance: Discovery Health policy with 80% coverage
  - Invoice: Recent invoice with partial payment

**Use Case**: This patient record can be used to:
- Test appointment scheduling workflows
- Validate form submission process
- Test billing and insurance calculations
- Validate access control (different views for different roles)
- Test medical history retrieval and display
- Validate audit trail functionality

---

### 6. DEPLOYMENT & ADMINISTRATION (1 script)

#### 000. MASTER_DEPLOYMENT_SCRIPT.sql
- **Purpose**: Orchestrate all insert scripts in correct dependency order
- **Execution**: Run this script to initialize entire database at once
- **Steps**: 11 sequential insert operations with progress reporting
- **Includes**: Setup instructions and post-deployment verification steps

---

## Dependency Graph

```
None Dependencies:
  ├─ Gender
  ├─ Marital Status
  ├─ Permissions
  ├─ Roles
  ├─ Billing Codes
  ├─ Allergies
  └─ Medications

Countries (no deps) →
  ├─ Provinces
  └─ Insurance Providers

Provinces → Cities

Roles, Permissions →
  └─ RolePermissions

RolePermissions →
  └─ Admin User

Cities, All Lookups →
  ├─ Healthcare Providers
  └─ Sample Test Data

All of the above → Master Deployment Script
```

---

## Pre-Execution Checklist

- [ ] All table creation scripts have been executed (003 Tables folder)
- [ ] Database HealthcareForm exists and is accessible
- [ ] User has appropriate database permissions (INSERT, SELECT)
- [ ] Backup has been taken of empty database (for rollback if needed)
- [ ] You are logged in with appropriate SQL Server credentials
- [ ] Transaction log drive has sufficient space (500MB+ recommended)

---

## Execution Instructions

### Option 1: Master Deployment Script (RECOMMENDED)
```sql
-- Update file paths in 000. MASTER_DEPLOYMENT_SCRIPT.sql
-- Then execute:
:r "C:\Path\To\000. MASTER_DEPLOYMENT_SCRIPT.sql"
```

### Option 2: Execute Individual Scripts in Order
```sql
-- Location lookups
:r "C:\Path\To\005. Insert Countries.sql"
:r "C:\Path\To\006. Insert Provinces.sql"
:r "C:\Path\To\007. Insert Cities.sql"

-- Profile lookups
:r "C:\Path\To\Insert Gender.sql"
:r "C:\Path\To\Insert Merital Status.sql"

-- Security setup
:r "C:\Path\To\008. Insert Roles.sql"
:r "C:\Path\To\009. Insert Permissions.sql"
:r "C:\Path\To\010. Insert RolePermissions.sql"
:r "C:\Path\To\016. Insert AdminUser.sql"

-- Reference data
:r "C:\Path\To\011. Insert BillingCodes.sql"
:r "C:\Path\To\012. Insert HealthcareProviders.sql"
:r "C:\Path\To\013. Insert InsuranceProviders.sql"
:r "C:\Path\To\014. Insert Allergies_Medications.sql"

-- Optional: Sample test data
:r "C:\Path\To\015. Insert SampleTestData.sql"
```

---

## Post-Execution Verification

```sql
-- Verify record counts
SELECT 'Countries' as [Table], COUNT(*) as [Records] FROM Location.Countries
UNION ALL
SELECT 'Provinces', COUNT(*) FROM Location.Provinces
UNION ALL
SELECT 'Cities', COUNT(*) FROM Location.Cities
UNION ALL
SELECT 'Gender', COUNT(*) FROM Profile.Gender
UNION ALL
SELECT 'MaritalStatus', COUNT(*) FROM Profile.MaritalStatus
UNION ALL
SELECT 'Roles', COUNT(*) FROM Security.Roles
UNION ALL
SELECT 'Permissions', COUNT(*) FROM Security.Permissions
UNION ALL
SELECT 'RolePermissions', COUNT(*) FROM Security.RolePermissions
UNION ALL
SELECT 'Users', COUNT(*) FROM Security.Users
UNION ALL
SELECT 'BillingCodes', COUNT(*) FROM Billing.BillingCodes
UNION ALL
SELECT 'HealthcareProviders', COUNT(*) FROM HealthcareServices.HealthcareProviders
UNION ALL
SELECT 'InsuranceProviders', COUNT(*) FROM HealthcareServices.InsuranceProviders
UNION ALL
SELECT 'Allergies', COUNT(*) FROM Profile.Allergies
UNION ALL
SELECT 'Medications', COUNT(*) FROM Profile.Medications
UNION ALL
SELECT 'Patients', COUNT(*) FROM Profile.Patient

-- Expected results:
-- Countries: 20
-- Provinces: 9
-- Cities: 38
-- Gender: 4
-- MaritalStatus: 6
-- Roles: 7
-- Permissions: 52
-- RolePermissions: 210
-- Users: 1 (admin)
-- BillingCodes: 50
-- HealthcareProviders: 10
-- InsuranceProviders: 8
-- Allergies: 15
-- Medications: 15
-- Patients: 1 (John Anderson sample)
```

---

## Important Notes

### Security
- Admin password is hashed with bcrypt (salt rounds: 10)
- Default password: `HealthcareAdmin@2026!`
- **MUST be changed immediately on first login**
- Use strong password for production

### Audit Trail
- All records include:
  - CreatedDate (GETDATE() at insertion time)
  - CreatedBy = 'SYSTEM'
  - UpdateDate tracking (added during table creation)
  - UpdatedBy tracking (added during table creation)

### Data Integrity
- All foreign key relationships validated
- Active flag set to 1 for all initial data
- No null values in required fields
- Unique constraints on critical fields (phone numbers, emails, ID numbers, etc.)

### South African Localization
- All 9 provinces included
- Major cities represented across all provinces
- Major SA insurance providers configured
- Sample doctors with realistic license numbers

### Testing
- John Anderson test patient includes:
  - Complete medical history (3 chronic conditions)
  - Current medications (2 active prescriptions)
  - Vaccination records (3 vaccines)
  - Lab results (5 tests)
  - Appointment scheduled for next week
  - Insurance coverage configured
  - Recent invoice with partial payment

Use this patient to test:
- Patient search and retrieval
- Medical history display
- Appointment scheduling
- Billing calculations
- Role-based access (different users see different data)
- Audit trail functionality

---

## Troubleshooting

### Issue: "Cannot insert duplicate value" on Roles/Permissions
**Solution**: Roles and Permissions were already inserted. Delete and re-insert:
```sql
DELETE FROM Security.RolePermissions
DELETE FROM Security.Users
DELETE FROM Security.UserRoles
DELETE FROM Security.Roles
DELETE FROM Security.Permissions
-- Then re-run insert scripts
```

### Issue: "Invalid column name" or "Table doesn't exist"
**Solution**: Ensure all table creation scripts (003 Tables folder) executed successfully before running inserts

### Issue: Foreign key constraint violation
**Solution**: Ensure insert scripts executed in correct order. Use Master Deployment Script which handles ordering

### Issue: Timeout during execution
**Solution**: Increase query timeout in SQL Server Management Studio:
- Tools → Options → Query Execution → Execution Time-out (set to 300 seconds)

---

## Next Steps After Initialization

1. **Create Application Users**
   ```sql
   -- Sample: Create a doctor user
   INSERT INTO Security.Users (UserName, Email, PasswordHash, FirstName, LastName, IsActive, CreatedDate, CreatedBy)
   VALUES ('dr.smith', 'dr.smith@healthcareform.local', '[bcrypt_hash]', 'Kevin', 'Smith', 1, GETDATE(), 'admin')
   
   INSERT INTO Security.UserRoles (UserIdFK, RoleIdFK, CreatedDate, CreatedBy)
   SELECT UserID FROM Security.Users WHERE UserName = 'dr.smith', RoleId FROM Security.Roles WHERE RoleName = 'DOCTOR'
   ```

2. **Configure Backup Strategy**
   - Schedule nightly full backups
   - Implement transaction log backups every 15 minutes
   - Test backup restoration weekly

3. **Set Up Monitoring**
   - Monitor free disk space
   - Alert on failed backup jobs
   - Track long-running queries

4. **Test Application Workflows**
   - Patient registration
   - Appointment scheduling
   - Form submission
   - Billing calculation
   - Report generation

5. **User Training**
   - Document role-specific workflows
   - Create quick-reference guides
   - Conduct user acceptance testing (UAT)

---

## File Locations

All insert scripts are located in:
`/home/samkelo/HealthcareForm/001. Database/005. Table Inserts/`

Naming Convention:
- `000. MASTER_DEPLOYMENT_SCRIPT.sql` - Master orchestration script
- `005-007. Insert [Location Data].sql` - Location lookups
- `008-010. Insert [Security].sql` - Security configuration
- `011. Insert BillingCodes.sql` - Billing reference data
- `012-014. Insert [Healthcare Data].sql` - Healthcare reference data
- `015. Insert SampleTestData.sql` - Test patient profile
- `016. Insert AdminUser.sql` - Admin bootstrap user

---

**Last Updated**: 14/02/2026  
**Version**: 1.0  
**Status**: Production-Ready
