# Healthcare Form Database - Deployment Execution Guide (Linux)

**Version:** 2.0  
**Date:** 14/02/2026  
**Status:** ✅ LINUX OPTIMIZED  
**OS:** Linux (Ubuntu/Debian/RHEL/CentOS)  
**Database:** SQL Server 2019+ on Linux  

---

## ⚠️ IMPORTANT: Linux Path Conversion

The original database was created on Windows with paths like:
- `D:\Data\HealthcareForm_FILEGROUPS\` → `/var/lib/mssql/data/`
- `E:\Logs\HealthcareForm_FILEGROUPS\` → `/var/lib/mssql/log/`

**All scripts have been updated to use Linux paths.**

For detailed information on Linux directory structure and naming conventions, see:
📄 [LINUX_MIGRATION_GUIDE.md](LINUX_MIGRATION_GUIDE.md)

---

## 📋 New Execution Process

The corrected script now uses a **guided manual approach** instead of automatic file execution:

### Phase 1: Database & Filegroups (Execute Manually)
```
📁 Location: 001. Database & FileGroups\
📄 File: 001. Healthcare form.sql
⏱️ Time: 1-2 minutes
```

### Phase 2: Schema Creation (Automated in Script)
✅ Automatically creates all 8 schemas when you run this script

### Phase 3: Table Creation (Execute Manually)
```
📁 Location: 003. Tables\
📄 Files: All 34 SQL files (execute in order)
⏱️ Time: 5-8 minutes
```

### Phase 4: Functions (Execute Manually)
```
📁 Location: 007. Triggers & Functions\
📄 Files:
  - Capitalize first letter.sql
  - Format Phone Contact.sql
  - ValidateEmail.sql (if available)
⏱️ Time: 1-2 minutes
```

### Phase 5: Stored Procedures (Execute Manually)
```
📁 Location: 006. Stored Procedures\
📄 Files: 10 core procedure scripts
⏱️ Time: 2-3 minutes
```

### Phase 6: Data Initialization (Execute Manually)
```
📁 Location: 005. Table Inserts\
📄 Files: 15 insert scripts in order
⏱️ Time: 5-10 minutes

Execute in this order:
  1. Insert Countries.sql
  2. Insert Provinces.sql
  3. Insert Cities.sql
  4. Insert Gender.sql
  5. Insert Marital Status.sql
  6. Insert Roles.sql
  7. Insert Permissions.sql
  8. Insert RolePermissions.sql
  9. Insert AdminUser.sql
  10. Insert BillingCodes.sql
  11. Insert HealthcareProviders.sql
  12. Insert InsuranceProviders.sql
  13. Insert Allergies_Medications.sql
  14. Insert SampleTestData.sql
```

### Phase 7: Verification (Automated in Script)
✅ Automatically verifies schemas, tables, and data once everything is created

---

## 🚀 Quick Execution Steps

### Option 1: Interactive Deployment (Recommended for First-Time)

**Step 1:** Open COMPLETE_MASTER_DEPLOYMENT.sql
- File location: `/home/samkelo/HealthcareForm/COMPLETE_MASTER_DEPLOYMENT.sql`

**Step 2:** Execute database creation
- Open: `001. Database & FileGroups/001. Healthcare form.sql`
- Click Execute (F5)
- Wait for completion

**Step 3:** Execute master script
- Go back to `COMPLETE_MASTER_DEPLOYMENT.sql`
- Click Execute (F5)
- This will create all schemas automatically
- It will display instructions for remaining phases

**Step 4:** Execute table creation scripts
- Open each file from `003. Tables/` folder
- Execute in any order (they're independent)
- Or batch execute all at once

**Step 5:** Execute function scripts
- Open each file from `007. Triggers & Functions/` folder
- Execute in any order

**Step 6:** Execute procedure scripts
- Open each file from `006. Stored Procedures/` folder
- Execute in any order

**Step 7:** Execute insert scripts
- Open each file from `005. Table Inserts/` folder
- **Execute in the order listed above** (for dependencies)
- Wait for each to complete before next

**Step 8:** Verify deployment
- Run master script again (Phase 7 will show record counts)

### Option 2: Batch Execution via PowerShell

Create a PowerShell script to batch execute all files:

```powershell
$sqlServerInstance = "localhost"
$database = "HealthcareForm"
$rootPath = "C:\path\to\HealthcareForm"

# Phase 1: Database
$dbFile = "$rootPath\001. Database & FileGroups\001. Healthcare form.sql"
sqlcmd -S $sqlServerInstance -i $dbFile

# Phase 2-3: Master script + schemas + verification
$masterFile = "$rootPath\COMPLETE_MASTER_DEPLOYMENT.sql"
sqlcmd -S $sqlServerInstance -d master -i $masterFile

# Phase 3: Tables (in order)
$tableFiles = Get-ChildItem "$rootPath\003. Tables" -Filter "*.sql" -Recurse
foreach ($file in $tableFiles) {
    sqlcmd -S $sqlServerInstance -d $database -i $file.FullName
}

# Continue for Phases 4-6...
```

---

## ✅ Success Criteria

After completing all phases, you should have:

- ✅ Database created: `HealthcareForm`
- ✅ Schemas created: 6 total (Location, Profile, Contacts, Auth, Exceptions, Lookup)
- ✅ Tables created: 45 total
- ✅ Triggers/functions created: 12 total (3 functions + 9 triggers)
- ✅ Stored procedures created: 50 total
- ✅ Records inserted: 500+ total
- ✅ Security roles: 7 configured
- ✅ Permissions: 52 configured
- ✅ Admin user: Created (default password must be changed)
- ✅ Sample patient: John Anderson with complete profile

---

## ⚠️ Critical Post-Deployment Steps

### 1. Change Admin Password (CRITICAL)
```sql
UPDATE Auth.Users
SET PasswordHash = '<new_bcrypt_hash>',
    UpdatedDate = GETDATE(),
    UpdatedBy = 'ADMIN_ROTATION'
WHERE Username = 'admin'
```

**Bootstrap Credential Source:**
- Username: `admin`
- Password hash supplied at deployment via `ADMIN_PASSWORD_HASH`
- Repository does not define a default password

### 2. Create Application Users
```sql
-- Example: Create a doctor user
INSERT INTO Auth.Users (UserName, PasswordHash, FirstName, LastName, IsActive, CreatedDate)
VALUES ('dr_johnson', HASHBYTES('SHA2_256', N'password'), 'Johnson', 'Smith', 1, GETDATE())

-- Then assign role
INSERT INTO Auth.UserRoles (UserID, RoleID)
VALUES ((SELECT UserID FROM Auth.Users WHERE UserName = 'dr_johnson'),
        (SELECT RoleID FROM Auth.Roles WHERE RoleName = 'DOCTOR'))
```

### 3. Configure Backups
- Schedule nightly FULL backups
- Configure transaction log backups every 15 minutes
- Test restoration procedures

### 4. Enable Audit Logging
- Monitor `Auth.AuditLog` table for all user activities
- Review `Auth.DB_Errors` for any issues

### 5. Performance Tuning
- Review index usage
- Monitor slow queries
- Update statistics

---

## 🔍 Troubleshooting

### Syntax Errors
If you see: `Incorrect syntax near ':'`
- **Cause:** The file contains old `:r` commands
- **Solution:** Use the corrected `COMPLETE_MASTER_DEPLOYMENT.sql` (all `:r` commands removed)

### Foreign Key Constraint Errors
- **Cause:** Tables created out of order or dependencies not met
- **Solution:** Execute table creation scripts in order:
  1. Location (Countries → Provinces → Cities → Address)
  2. Profile (Gender → MaritalStatus → Patient → Others)
  3. Then other schemas

### Missing Table Errors
- **Cause:** Table files not executed
- **Solution:** Check which tables exist:
  ```sql
  USE HealthcareForm
  SELECT * FROM information_schema.tables
  ORDER BY TABLE_SCHEMA, TABLE_NAME
  ```

### Insert Script Failures
- **Cause:** Referenced data doesn't exist
- **Solution:** Execute lookup data first (Countries, Gender, MaritalStatus, etc.)

---

## 📊 File Statistics

**Total Files to Execute:**
- 1 Database creation script
- 1 Master deployment script (automatic)
- 34 Table scripts
- 3 Function scripts
- 10 Stored procedure scripts
- 15 Insert scripts
- **Total: 64 SQL files**

**Estimated Total Time:**
- Database creation: 2 minutes
- Schema creation: 1 minute
- Table creation: 5-8 minutes
- Functions: 1-2 minutes
- Procedures: 2-3 minutes
- Data initialization: 5-10 minutes
- Verification: 2 minutes
- **Total: 20-30 minutes** (fully automated with PowerShell)
- **Total: 40-60 minutes** (manual execution)

---

## 📞 Support

If you encounter issues:

1. Check the error message carefully
2. Verify the file path and folder structure
3. Check that HealthcareForm database exists
4. Review the script's PRINT output for guidance
5. Refer to the COMPLETE_MASTER_DEPLOYMENT_GUIDE.md for detailed information

---

## 📝 Notes

- All scripts use standard T-SQL syntax (no SQLCMD mode required)
- Safe to re-run scripts (they check `IF NOT EXISTS` before creation)
- Safe to execute in any order EXCEPT:
  - Database must exist before other scripts
  - Location tables before Profile tables (foreign keys)
  - Lookups before inserts
- Each script includes detailed comments
- All scripts include error handling and validation

---

**Status:** ✅ Ready for Deployment  
**Last Updated:** 14/02/2026  
**Next Step:** Execute Phase 1 (Database Creation)
