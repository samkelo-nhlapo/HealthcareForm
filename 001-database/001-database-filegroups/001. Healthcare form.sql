USE master;
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Create HealthcareForm database with proper filegroups for production use
--	TFS Task:		Database initialization - production standards
--================================================================================================

/*
DATABASE CONFIGURATION NOTES (LINUX):
- PRIMARY filegroup: 500MB initial, 5GB MAX (system & audit data)
- PatientDataGroup filegroup: 1GB initial per file, 10GB MAX (patient & transaction tables)
- LOG file: 500MB initial, 5GB MAX (separate mount recommended for I/O performance)
- Growth: 100MB (automatic, avoids excessive fragmentation)

RECOMMENDED DIRECTORY STRUCTURE:
- Data files: /var/lib/mssql/data/
- Log files:  /var/lib/mssql/log/
- Backups:   /var/lib/mssql/backup/
*/

CREATE DATABASE HealthcareForm
ON PRIMARY
  ( NAME='HealthcareForm_Primary',
    FILENAME='/var/lib/mssql/data/healthcare-form-primary.mdf',
    SIZE=500MB,
    MAXSIZE=5GB,
    FILEGROWTH=100MB),
FILEGROUP PatientDataGroup
  ( NAME = 'PatientData_File1',
    FILENAME='/var/lib/mssql/data/healthcare-form-patient-data-1.ndf',
    SIZE=1GB,
    MAXSIZE=10GB,
    FILEGROWTH=100MB),
  ( NAME = 'PatientData_File2',
    FILENAME='/var/lib/mssql/data/healthcare-form-patient-data-2.ndf',
    SIZE=1GB,
    MAXSIZE=10GB,
    FILEGROWTH=100MB)
LOG ON
  ( NAME='HealthcareForm_Log',
    FILENAME='/var/lib/mssql/log/healthcare-form.ldf',
    SIZE=500MB,
    MAXSIZE=5GB,
    FILEGROWTH=100MB);
GO

--================================================================================================
-- Configure database options for healthcare production use
--================================================================================================

ALTER DATABASE HealthcareForm 
  MODIFY FILEGROUP PatientDataGroup DEFAULT;
GO

-- Recovery model: FULL (required for complete transaction log backups)
ALTER DATABASE HealthcareForm SET RECOVERY FULL;
GO

-- Enable automatic statistics update
ALTER DATABASE HealthcareForm SET AUTO_UPDATE_STATISTICS ON;
GO

-- Prevent shrinking to avoid index fragmentation
ALTER DATABASE HealthcareForm SET AUTO_SHRINK OFF;
GO

-- Set page verification to CHECKSUM for data integrity
ALTER DATABASE HealthcareForm SET PAGE_VERIFY CHECKSUM;
GO

--================================================================================================
-- Filegroup usage specification
--================================================================================================
/*
PRIMARY Filegroup:
  - System tables
  - Audit and compliance tables (Auth schema)
  - Lookup tables (Gender, MaritalStatus, etc.)

PatientDataGroup Filegroup (Default):
  - Patient and profile data (Profile schema)
  - Contact information (Contacts schema)
  - Location data (Location schema)
  - Exceptions (Exceptions schema)

Log File:
  - Transaction log on separate physical drive (E:) for performance
  - Prevents I/O contention with data files
*/

--================================================================================================
-- Next Steps
--================================================================================================
/*
1. Run schema creation script (002. Schema/001. Schema's Script.sql)
2. Run table creation scripts (003. Tables/)
3. Run function/trigger scripts (007. Triggers & Functions/)
4. Run stored procedure scripts (006. Stored Procedures/)
5. Run insert scripts (005. Table Inserts/)

BACKUP CONFIGURATION (Recommended):
- Full backup: Daily at 02:00 UTC
- Differential backup: Every 6 hours
- Transaction log backup: Every 15 minutes
- Retain full backups for 30 days
- Store backups on separate drive/server

MAINTENANCE SCHEDULE:
- Index rebuild: Weekly (fragmentation > 30%)
- Index reorganize: Daily (fragmentation 10-30%)
- Update statistics: Daily
- DBCC CHECKDB: Weekly
*/

USE HealthcareForm;
GO