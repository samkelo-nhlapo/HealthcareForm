# Windows to Linux Migration - Quick Reference Card

## Database Paths
```
WINDOWS                              LINUX
D:\Data\...                  →  /var/lib/mssql/data/
E:\Logs\...                  →  /var/lib/mssql/log/
C:\Backups\...               →  /var/lib/mssql/backup/
```

## File Names
```
WINDOWS                              LINUX
HealthcareForm_Prm.mdf       →  healthcare-form-primary.mdf
PatientData_1.ndf            →  healthcare-form-patient-data-1.ndf
PatientData_2.ndf            →  healthcare-form-patient-data-2.ndf
HealthcareForm.ldf           →  healthcare-form.ldf
```

## Folder Names
```
WINDOWS                              LINUX
001. Database & FileGroups   →  001-database
002. Schema                  →  002-schemas
003. Tables                  →  003-tables
005. Table Inserts           →  005-table-inserts
006. Stored Procedures       →  006-stored-procedures
007. Triggers & Functions    →  007-triggers-functions
```

## SQL File Names
```
WINDOWS                              LINUX
Capitalize first letter.sql  →  capitalize-first-letter.sql
Format Phone Contact.sql     →  format-phone-contact.sql
[Profile].[spAddPatient]     →  profile-add-patient.sql
Insert Countries.sql         →  insert-countries.sql
Insert Marital Status.sql    →  insert-marital-status.sql
```

## Linux Setup Commands
```bash
# Create directories
sudo mkdir -p /var/lib/mssql/{data,log,backup}

# Set ownership
sudo chown -R mssql:mssql /var/lib/mssql

# Set permissions
sudo chmod -R 700 /var/lib/mssql

# Verify
ls -la /var/lib/mssql/
```

## Quick Deployment
```bash
# Create database
sqlcmd -S localhost -U SA -P 'Password' \
  -i ~/HealthcareForm/001-database/001-filegroups/001-healthcare-form.sql

# Run master script
sqlcmd -S localhost -U SA -P 'Password' \
  -i ~/HealthcareForm/COMPLETE_MASTER_DEPLOYMENT.sql

# Execute bash script
bash ~/HealthcareForm/deploy-linux.sh
```

## Naming Rules
✅ Lowercase only (a-z, 0-9)
✅ Use hyphens (-) for separation
✅ No spaces, no underscores
✅ Clear, descriptive names
✅ Lowercase extensions (.sql, .mdf, .ldf)

## Key Files Updated
✅ 001. Healthcare form.sql
✅ COMPLETE_MASTER_DEPLOYMENT.sql
✅ DEPLOYMENT_EXECUTION_GUIDE.md
✅ LINUX_MIGRATION_GUIDE.md (NEW)

## Post-Deployment
```sql
-- Change admin password
UPDATE Security.Users 
SET PasswordHash = HASHBYTES('SHA2_256', N'NewPassword')
WHERE UserName = 'admin'

-- Verify deployment
SELECT COUNT(*) FROM information_schema.tables
WHERE TABLE_CATALOG = 'HealthcareForm'
```

---
**Status:** ✅ Complete | **Version:** 2.0 | **Date:** 14/02/2026
