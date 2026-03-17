# Healthcare Form Database - Complete Master Deployment Guide

**Version**: 1.0  
**Date**: 14/02/2026  
**Status**: Production-Ready

---

## 📋 Overview

The **COMPLETE_MASTER_DEPLOYMENT.sql** script is a comprehensive, end-to-end database deployment orchestration tool that:

- Deploys the entire healthcare database from scratch
- Creates database, filegroups, schemas, all 45 tables, triggers/functions, stored procedures, and initializes all data
- Handles all dependencies in the correct execution order
- Provides real-time progress tracking and completion reporting
- Validates installation with record counts and schema verification
- Takes approximately **15-20 minutes** for complete deployment

---

## 🎯 What Gets Deployed

### Phase 1: Database & Filegroups (1 file)
- Creates `HealthcareForm` database
- Configures 3 filegroups:
  - PRIMARY: 500 MB initial / 5 GB max
  - PatientDataGroup: 1 GB initial / 10 GB max
  - Each with 100 MB auto-growth

### Phase 2: Schemas (1 file)
Creates 6 physical database schemas:
- **Location** - Geographic data (countries, provinces, cities, addresses)
- **Profile** - Patient demographics, clinical records, billing, operations
- **Contacts** - Phones, emails, emergency contacts, forms
- **Auth** - Users, roles, permissions, audit logs
- **Exceptions** - Error handling
- **Lookup** - Reference data

Note: Domain areas like billing, forms, and healthcare services are represented as tables under the
physical schemas above.

### Phase 3: Tables (45 tables)
The authoritative table list lives in `001-database/003-tables/` (45 scripts). Core domains include:
- Patient demographics and clinical records (Profile)
- Contacts, forms, and attachments (Contacts)
- Geography/address data (Location)
- Auth, roles, permissions, audit logs (Auth)
- Error tracking (Exceptions)
- Reference lookups (Lookup)

### Phase 4: Triggers/Functions (12 objects)
- `dbo.CapitalizeFirstLetter`, `dbo.CapitalizeFirstLetterBody`
- `Contacts.FormatPhoneNumber`
- Contact validation and enforcement triggers
Full list in `001-database/007-triggers-functions/`.

### Phase 5: Stored Procedures (50 procedures)
- Patient CRUD and lookups
- Operations and scheduling snapshots
- Revenue claims and admin dashboards
Full list in `001-database/006-stored-procedures/`.

### Phase 6: Data Initialization (20 insert scripts)

| # | Script | Records | Purpose |
|---|--------|---------|---------|
| 1 | Countries | 20 | Geographic locations |
| 2 | Provinces | 9 | SA provinces |
| 3 | Cities | 38 | SA cities |
| 4 | Gender | 4 | Patient demographics |
| 5 | Marital Status | 6 | Patient demographics |
| 6 | Roles | 7 | RBAC setup |
| 7 | Permissions | 52 | RBAC setup |
| 8 | RolePermissions | 210+ | RBAC mapping |
| 9 | Admin User | 1 | System bootstrap |
| 10 | Billing Codes | 50 | ICD-10, CPT, HCPCS |
| 11 | Healthcare Providers | 10 | Doctor reference data |
| 12 | Insurance Providers | 8 | SA insurance companies |
| 13 | Allergies/Medications | 30 | Medical reference |
| 14 | Sample Patient | 1+ | Test data for UAT |
| 15 | Additional inserts | (varies) | See full list in 005-table-inserts |

Full list: `001-database/005-table-inserts/` (20 scripts total).

**Total Records Inserted**: 500+

---

## 🚀 Quick Start

### Prerequisites
- SQL Server 2019 or newer
- SQL Server Management Studio (SSMS)
- System Administrator (SA) or equivalent permissions
- 5 GB free disk space
- All source files in correct folder structure (see folder layout below)

### Execution Steps

#### Step 1: Verify Folder Structure
```
/home/samkelo/HealthcareForm/
├── COMPLETE_MASTER_DEPLOYMENT.sql          ← EXECUTE THIS FILE
│
├── 001. Database & FileGroups/
│   └── 001. Healthcare form.sql
│
├── 002. Schema/
│   └── 001. Schema's Script.sql
│
├── 003. Tables/
│   └── [45 table scripts]
│
├── 005. Table Inserts/
│   └── [20 insert scripts]
│
├── 006. Stored Procedures/
│   └── [50 stored procedure scripts]
│
└── 007. Triggers & Functions/
    └── [12 trigger/function scripts]
```

#### Step 2: Update File Paths (IMPORTANT!)
If deploying from Linux/different path, the master script uses relative paths. The `:r` directive works from the location where the script is run. 

**Option A: Run from root folder**
```bash
cd /home/samkelo/HealthcareForm/
# Then execute COMPLETE_MASTER_DEPLOYMENT.sql in SSMS
```

**Option B: Update paths in script** (if needed)
Replace all paths like:
```sql
:r "001. Database & FileGroups\001. Healthcare form.sql"
```
With absolute paths:
```sql
:r "C:\Full\Path\To\001. Database & FileGroups\001. Healthcare form.sql"
```

#### Step 3: Execute Master Script
In SQL Server Management Studio:

1. Open `COMPLETE_MASTER_DEPLOYMENT.sql`
2. Verify you're connected to SQL Server (not Azure)
3. Click **Execute** or press **F5**
4. Watch progress output in Messages tab
5. Wait for completion (~15-20 minutes)

#### Step 4: Verify Installation
Script automatically displays:
- Record counts for all major tables
- Schema summary
- Security configuration
- Database filegroups

#### Step 5: Post-Deployment Tasks
See "Next Steps" section below

---

## ⚙️ Detailed Deployment Phases

### Phase 1: Database & Filegroup Creation (1-2 min)
```
[PHASE 1] DATABASE & FILEGROUP CREATION
────────────────────────────────────────
[1/1] Creating HealthcareForm database with filegroups...
```

**What happens**:
- Creates `HealthcareForm` database
- Creates PRIMARY filegroup (500 MB initial)
- Creates PatientDataGroup (1 GB initial)
- Configures auto-growth (100 MB increments)
- Sets recovery model to FULL

**Safety**: If database exists, script skips creation and continues

### Phase 2: Schema Creation (1 min)
```
[PHASE 2] SCHEMA CREATION
────────────────────────
[1/1] Creating database schemas...
Schemas created successfully
```

**What happens**:
- Creates Location, Profile, Contacts, Auth, Exceptions, Lookup schemas
- Establishes logical separation of concerns

### Phase 3: Table Creation (3-5 min)
```
[PHASE 3] TABLE CREATION (45 TABLES)
────────────────────────────────────
[1/45] Creating Location.Countries table...
[2/45] Creating Location.Provinces table...
...
[45/45] Creating Lookup tables...
All 45 tables created successfully
```

**What happens**:
- Creates all 45 normalized tables
- Establishes primary keys (GUID-based)
- Creates foreign key relationships
- Adds unique constraints
- Creates 45+ indexes for performance
- Adds audit columns (CreatedDate, UpdateDate, etc.)

**Dependencies**: All foreign key relationships honored

### Phase 4: Triggers/Functions Creation (1 min)
```
[PHASE 4] TRIGGERS & FUNCTIONS CREATION
──────────────────────────────────────
[1/12] Creating CapitalizeFirstLetter function...
[2/12] Creating CapitalizeFirstLetterBody function...
...
[12/12] Trigger/function deployment complete
All trigger/function objects created successfully
```

**Core objects**:
- `CapitalizeFirstLetter()` - Ensures proper name formatting
- `FormatPhoneNumber()` - Validates and formats phone numbers
- `ValidateEmail()` - Email validation for database-level enforcement

### Phase 5: Stored Procedures Creation (2 min)
```
[PHASE 5] STORED PROCEDURES CREATION
────────────────────────────────────
[1/50] Creating spAddPatient_v2...
[2/50] Creating spGetPatient...
...
[10/50] Creating spDB_Errors...
Core stored procedures created successfully
```

**Key Procedures**:
- **spAddPatient_v2** - Comprehensive patient registration with validation
- **spGetPatient** - Retrieve patient information
- **spUpdatePatient** - Update patient details
- **spDeletePatient** - Delete patient records
- Lookup procedures for Gender, MaritalStatus, Countries, Provinces, Cities

### Phase 6: Data Initialization (5-8 min)
```
[PHASE 6] DATA INITIALIZATION - 20 INSERT SCRIPTS
──────────────────────────────────────────────────
[1/20] Inserting Countries lookup data...
[2/20] Inserting Provinces lookup data...
...
[20/20] Initialization complete
All lookup tables and reference data populated successfully
```

**Data Loaded**:
- 20 countries + 9 provinces + 38 cities
- 4 genders + 6 marital statuses
- 7 security roles + 52 permissions + 210+ mappings
- 1 admin user (bootstrap)
- 50 billing codes
- 10 healthcare providers
- 8 insurance providers
- 15 allergies + 15 medications
- 1 complete sample patient with medical profile

### Phase 7: Verification & Reporting (1 min)
```
[PHASE 7] VERIFICATION & DATA VALIDATION
────────────────────────────────────────

TABLE RECORD COUNTS:
====================
Location.Countries                    20
Location.Provinces                     9
...
Billing.BillingCodes                  50

SCHEMA SUMMARY:
===============
Location              4
Profile              11
Contacts              4
...

DEPLOYMENT COMPLETE!
================================================================================================
```

---

## 🔍 Monitoring Deployment Progress

The script provides real-time progress:

```
COMPLETE_MASTER_DEPLOYMENT: Execution Started
────────────────────────────────────────────────
Start Time: 2026-02-14 10:30:45.123

[PHASE 1] DATABASE & FIREGROUP CREATION
[PHASE 2] SCHEMA CREATION
[PHASE 3] TABLE CREATION (45 TABLES)
[PHASE 4] TRIGGERS & FUNCTIONS CREATION
[PHASE 5] STORED PROCEDURES CREATION
[PHASE 6] DATA INITIALIZATION
[PHASE 7] VERIFICATION & REPORTING

Completion Time: 2026-02-14 10:47:23.456
```

**Typical Timeline**:
- Phase 1: 1-2 min
- Phase 2: 1 min
- Phase 3: 3-5 min
- Phase 4: 1 min
- Phase 5: 2 min
- Phase 6: 5-8 min
- Phase 7: 1 min
- **Total: 15-20 minutes**

---

## ✅ Verification Checklist

After deployment completes, verify:

### Database Exists
```sql
SELECT database_id, name FROM sys.databases WHERE name = 'HealthcareForm'
-- Should return: HealthcareForm with valid database_id
```

### Schemas Created (6)
```sql
SELECT COUNT(*) FROM sys.schemas
-- Should return: 6+ (including dbo, guest, and your 6 custom schemas)
```

### Tables Created (45)
```sql
SELECT COUNT(*) FROM information_schema.tables 
WHERE TABLE_CATALOG = 'HealthcareForm' AND TABLE_TYPE = 'BASE TABLE'
-- Should return: 45
```

### Lookup Data Populated
```sql
SELECT COUNT(*) FROM Location.Countries      -- 20
SELECT COUNT(*) FROM Location.Provinces      -- 9
SELECT COUNT(*) FROM Location.Cities         -- 38
SELECT COUNT(*) FROM Profile.Gender          -- 4
SELECT COUNT(*) FROM Profile.MaritalStatus   -- 6
SELECT COUNT(*) FROM Auth.Roles          -- 7
SELECT COUNT(*) FROM Auth.Permissions    -- 52
SELECT COUNT(*) FROM Auth.Users          -- 1 (admin)
```

### Security Configured
```sql
SELECT RoleName FROM Auth.Roles ORDER BY RoleName
-- Should return: ADMIN, BILLING, DOCTOR, NURSE, PATIENT, PHARMACIST, RECEPTIONIST

SELECT COUNT(*) FROM Auth.RolePermissions
-- Should return: 210+ mappings
```

### Admin User Created
```sql
SELECT UserName, Email, IsActive FROM Auth.Users WHERE UserName = 'admin'
-- Should return: admin, admin@healthcareform.local, 1 (active)
```

---

## 🛠️ Troubleshooting

### Issue: "Cannot open include file"
**Cause**: File paths are incorrect  
**Solution**:
1. Verify all files exist in correct folders
2. Run script from root `HealthcareForm` folder
3. Or update all paths to absolute paths in script

### Issue: "Database already exists"
**Cause**: HealthcareForm database was previously created  
**Solution**:
- Script skips creation and continues (safe)
- Tables may already exist and fail
- **Recommended**: Drop and recreate
  ```sql
  USE master
  GO
  DROP DATABASE HealthcareForm
  GO
  -- Then run master script again
  ```

### Issue: "The CREATE TABLE statement conflicted with FOREIGN KEY constraint"
**Cause**: Table dependencies not in correct order  
**Solution**: This shouldn't happen as master script enforces correct order. If it occurs:
1. Check that parent table exists
2. Verify no circular FK references
3. Re-run master script

### Issue: "Timeout expired"
**Cause**: Script taking too long  
**Solution**:
1. Increase query timeout in SSMS:
   - Tools → Options → Query Execution → Execution Time-out
   - Set to 600 seconds (10 minutes)
2. Or run in smaller phases (not recommended)

### Issue: "Invalid object name" or "Incorrect syntax"
**Cause**: Source file doesn't exist or has syntax errors  
**Solution**:
1. Verify source files exist in correct paths
2. Check file names match exactly (case-sensitive on Linux)
3. Verify SQL syntax in source files

---

## 📊 Post-Deployment Verification Script

Run this after deployment to validate everything:

```sql
USE HealthcareForm
GO

PRINT 'HEALTHCARE FORM DATABASE - POST-DEPLOYMENT VALIDATION'
PRINT '======================================================'
PRINT ''

-- 1. Check database properties
PRINT '1. DATABASE PROPERTIES'
SELECT @db = DB_NAME()
SELECT 'Database Name: ' + @db as [Property], COUNT(*) as [Value]
FROM sys.tables
PRINT ''

-- 2. Count tables by schema
PRINT '2. TABLES BY SCHEMA'
SELECT	SCHEMA_NAME(schema_id) as [Schema],
		COUNT(*) as [Table Count]
FROM	sys.tables
GROUP BY SCHEMA_NAME(schema_id)
ORDER BY [Schema]
PRINT ''

-- 3. Count records in key tables
PRINT '3. KEY TABLE RECORD COUNTS'
SELECT 'Location.Countries' as [Table], COUNT(*) as [Records] FROM Location.Countries
UNION ALL SELECT 'Location.Provinces', COUNT(*) FROM Location.Provinces
UNION ALL SELECT 'Location.Cities', COUNT(*) FROM Location.Cities
UNION ALL SELECT 'Profile.Gender', COUNT(*) FROM Profile.Gender
UNION ALL SELECT 'Profile.MaritalStatus', COUNT(*) FROM Profile.MaritalStatus
UNION ALL SELECT 'Auth.Roles', COUNT(*) FROM Auth.Roles
UNION ALL SELECT 'Auth.Permissions', COUNT(*) FROM Auth.Permissions
UNION ALL SELECT 'Auth.Users', COUNT(*) FROM Auth.Users
ORDER BY [Table]
PRINT ''

-- 4. Verify security configuration
PRINT '4. SECURITY ROLES CONFIGURED'
SELECT '  - ' + RoleName as [Role] FROM Auth.Roles ORDER BY RoleName
PRINT ''

-- 5. Check admin user
PRINT '5. ADMIN USER VERIFICATION'
IF EXISTS (SELECT 1 FROM Auth.Users WHERE UserName = 'admin' AND IsActive = 1)
	PRINT 'Admin user: ✓ Created and Active'
ELSE
	PRINT 'Admin user: ✗ Not found or inactive'
PRINT ''

-- 6. Verify stored procedures
PRINT '6. STORED PROCEDURES CREATED'
SELECT COUNT(*) as [Procedure Count] FROM sys.objects WHERE type = 'P'
PRINT ''

PRINT 'VALIDATION COMPLETE'
PRINT '=================='
GO
```

---

## 📋 Next Steps After Deployment

### Immediate (Day 1)
1. **Verify Admin Bootstrap Credential**
   ```sql
   -- Bootstrap account:
   -- Username: admin
   -- Password hash is injected via ADMIN_PASSWORD_HASH at deployment
   -- Rotate immediately after first login (update Auth.Users.PasswordHash)
   ```

2. **Create Application Users**
   ```sql
   -- Example: Create a doctor user
   INSERT INTO Auth.Users (UserName, Email, PasswordHash, FirstName, LastName, IsActive, CreatedDate, CreatedBy)
   VALUES ('dr.smith', 'dr.smith@healthcareform.local', '[bcrypt_hash]', 'Kevin', 'Smith', 1, GETDATE(), 'admin')
   
   INSERT INTO Auth.UserRoles (UserIdFK, RoleIdFK, CreatedDate, CreatedBy)
   SELECT (SELECT UserID FROM Auth.Users WHERE UserName = 'dr.smith'),
          (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'DOCTOR'),
          GETDATE(), 'admin'
   ```

3. **Test with Sample Patient**
   - Use John Anderson (PatientId from Profile.Patient)
   - Test appointment scheduling
   - Test medical history retrieval
   - Verify audit trail functionality

### Short-term (Week 1)
1. **Configure Backups**
   - Schedule nightly full backups
   - Configure transaction log backups every 15 minutes
   - Test restoration procedure
   - Document backup schedule

2. **Performance Tuning**
   - Review index usage statistics
   - Monitor long-running queries
   - Tune query plans if needed

3. **User Training**
   - Train staff on different roles
   - Demonstrate permission-based access
   - Review audit trail functionality

### Medium-term (Week 2-4)
1. **Security Hardening**
   - Enable SQL Server audit logging
   - Configure access restrictions
   - Review and tighten permissions
   - Implement row-level security if needed

2. **Application Testing**
   - Test patient registration workflow
   - Test appointment scheduling
   - Test form submission and review
   - Test billing and invoice generation
   - Test role-based access control

3. **Documentation**
   - Document customizations made
   - Create operational runbooks
   - Document disaster recovery procedures
   - Create user guides by role

---

## 🔐 Security Best Practices

### Password Management
- **Never** use default password in production
- Use strong passwords (minimum 12 characters, mixed case, numbers, symbols)
- Store passwords in encrypted vault (Azure Key Vault, HashiCorp Vault, etc.)
- Implement password expiration policies
- Rotate service account passwords quarterly

### Access Control
- Assign least privilege principle
- Review role assignments monthly
- Audit user activity regularly
- Disable unused accounts promptly

### Database Security
- Enable SQL Server authentication
- Use Windows authentication where possible
- Enable Transparent Data Encryption (TDE) for sensitive environments
- Configure firewall to restrict access
- Enable audit logging for sensitive operations

### Audit Trail
- All operations logged with CreatedDate, UpdateDate, CreatedBy, UpdatedBy
- Use UserActivityAudit table for user action tracking
- Review audit logs monthly
- Archive audit logs quarterly

---

## 📞 Support & Resources

### Files Included
- `COMPLETE_MASTER_DEPLOYMENT.sql` - Main deployment script
- `COMPLETE_MASTER_DEPLOYMENT_GUIDE.md` - This file
- All source files in appropriate folders

### Documentation
- `001. Database/007. Documentation/` - Complete healthcare schema guide
- `005. Table Inserts/INSERT_SCRIPTS_README.md` - Insert script details
- `005. Table Inserts/EXECUTION_CHECKLIST.sql` - Step-by-step checklist

### Troubleshooting
1. Check file paths match your environment
2. Verify SQL Server version (2019+)
3. Review error messages in SSMS output
4. Check system resources (disk space, memory)
5. Review SQL Server error log

---

## 📈 Performance Expectations

| Operation | Time | Notes |
|-----------|------|-------|
| Database & Filegroup Creation | 1-2 min | Depends on disk speed |
| Schema Creation | 1 min | Quick operation |
| Table Creation (45 tables) | 3-5 min | Includes all indexes |
| Trigger/Function Creation | 1 min | Quick operation |
| Stored Procedure Creation | 2 min | 50 procedures |
| Data Initialization (20 scripts) | 5-8 min | 500+ records inserted |
| Verification & Reporting | 1 min | Query results |
| **TOTAL** | **15-20 min** | Typical deployment time |

---

## 📦 Deliverables Summary

**Complete Database Deployment Package**:
- ✅ 1 master deployment orchestration script
- ✅ 45 production-ready tables
- ✅ 6 logical schemas
- ✅ 12 trigger/function objects
- ✅ 50 stored procedures
- ✅ 20 data initialization scripts
- ✅ 500+ pre-loaded reference records
- ✅ Complete RBAC configuration (7 roles, 52 permissions)
- ✅ Sample test patient for UAT
- ✅ Comprehensive documentation

**Status**: ✅ Production-Ready

---

**Created**: 14/02/2026  
**Version**: 1.0  
**Author**: Samkelo Nhlapo  
**Last Updated**: 14/02/2026
