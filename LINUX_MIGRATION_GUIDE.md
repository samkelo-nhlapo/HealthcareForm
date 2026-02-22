# Healthcare Form Database - Linux Migration Guide

**Version:** 1.0  
**Date:** 14/02/2026  
**OS:** Linux (Ubuntu/Debian/RHEL)  
**Database:** SQL Server 2019+ on Linux  

---

## Overview

Your healthcare database has been successfully converted from Windows to Linux conventions. This guide provides:
- Recommended Linux directory structure
- File path conversions
- Setup instructions
- Best practices for SQL Server on Linux
- Docker deployment (recommended for Linux)

---

## 1. SQL Server on Docker (Recommended for Linux)

### Why Docker?

Docker provides the easiest SQL Server deployment on Linux:
- ✅ No manual SQL Server installation required
- ✅ Consistent environment across all machines
- ✅ Easy to start, stop, and manage
- ✅ Built-in isolation and security
- ✅ Persistent data with volume mounts
- ✅ Simple database migration and backups

### Prerequisites

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group (optional, to run without sudo)
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker run hello-world
```

### Quick Start: Run SQL Server in Docker

**Step 1: Pull SQL Server Image**

```bash
docker pull mcr.microsoft.com/mssql/server:2019-latest
```

**Step 2: Create Data Directories**

```bash
# Create persistent data directories on host
mkdir -p ~/mssql/data
mkdir -p ~/mssql/log
mkdir -p ~/mssql/backup

# Set permissions
chmod 755 ~/mssql/data
chmod 755 ~/mssql/log
chmod 755 ~/mssql/backup
```

**Step 3: Run SQL Server Container**

```bash
docker run -d \
  --name mssql-server \
  -e MSSQL_SA_PASSWORD='YourPassword@123' \
  -e ACCEPT_EULA=Y \
  -p 1433:1433 \
  -v ~/mssql/data:/var/opt/mssql/data \
  -v ~/mssql/log:/var/opt/mssql/log \
  -v ~/mssql/backup:/var/opt/mssql/backup \
  mcr.microsoft.com/mssql/server:2019-latest
```

**Step 4: Verify Container is Running**

```bash
# Check if container is running
docker ps

# View container logs
docker logs mssql-server

# Test connection
docker exec -it mssql-server sqlcmd -S localhost -U SA -P 'YourPassword@123' -Q "SELECT @@VERSION"
```

### Docker Compose Setup (Production-Ready)

Create `docker-compose.yml`:

```yaml
version: '3.9'

services:
  mssql-server:
    image: mcr.microsoft.com/mssql/server:2019-latest
    container_name: healthcare-mssql
    environment:
      MSSQL_SA_PASSWORD: YourPassword@123
      ACCEPT_EULA: Y
      MSSQL_PID: Standard
    ports:
      - "1433:1433"
    volumes:
      - ./mssql/data:/var/opt/mssql/data
      - ./mssql/log:/var/opt/mssql/log
      - ./mssql/backup:/var/opt/mssql/backup
    networks:
      - healthcare-network
    healthcheck:
      test: ["CMD", "/opt/mssql-tools/bin/sqlcmd", "-S", "localhost", "-U", "SA", "-P", "YourPassword@123", "-Q", "SELECT 1"]
      interval: 10s
      timeout: 5s
      retries: 5

networks:
  healthcare-network:
    driver: bridge
```

Run with Docker Compose:

```bash
# Start the container
docker-compose up -d

# Check logs
docker-compose logs -f

# Stop the container
docker-compose down

# Backup volumes
docker-compose exec mssql-server /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P 'YourPassword@123' -Q "BACKUP DATABASE [HealthcareForm] TO DISK='/var/opt/mssql/backup/healthcare-form.bak'"
```

### Docker Networking & Deployment Script

**Docker Deployment Script (deploy-docker.sh):**

```bash
#!/bin/bash

# Docker SQL Server Healthcare Form Deployment
# Configurable variables
SA_PASSWORD="${SA_PASSWORD:-YourPassword@123}"
CONTAINER_NAME="healthcare-mssql"
IMAGE="mcr.microsoft.com/mssql/server:2019-latest"
HOST_DATA_DIR="$HOME/mssql/data"
HOST_LOG_DIR="$HOME/mssql/log"
HOST_BACKUP_DIR="$HOME/mssql/backup"
PROJECT_ROOT="/home/samkelo/HealthcareForm"
DATABASE="HealthcareForm"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}[1/5] Setting up directories...${NC}"
mkdir -p "$HOST_DATA_DIR" "$HOST_LOG_DIR" "$HOST_BACKUP_DIR"
chmod 755 "$HOST_DATA_DIR" "$HOST_LOG_DIR" "$HOST_BACKUP_DIR"

echo -e "${YELLOW}[2/5] Stopping existing container...${NC}"
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true

echo -e "${YELLOW}[3/5] Starting SQL Server container...${NC}"
docker run -d \
  --name $CONTAINER_NAME \
  -e MSSQL_SA_PASSWORD="$SA_PASSWORD" \
  -e ACCEPT_EULA=Y \
  -e MSSQL_PID=Standard \
  -p 1433:1433 \
  -v "$HOST_DATA_DIR":/var/opt/mssql/data \
  -v "$HOST_LOG_DIR":/var/opt/mssql/log \
  -v "$HOST_BACKUP_DIR":/var/opt/mssql/backup \
  "$IMAGE"

# Wait for SQL Server to be ready
echo -e "${YELLOW}[4/5] Waiting for SQL Server to start...${NC}"
sleep 15
for i in {1..30}; do
  docker exec $CONTAINER_NAME /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" -Q "SELECT 1" >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ SQL Server is ready${NC}"
    break
  fi
  echo "Attempt $i/30..."
  sleep 2
done

echo -e "${YELLOW}[5/5] Deploying database...${NC}"

# Database creation
echo "Creating database..."
docker exec -i $CONTAINER_NAME /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" < "$PROJECT_ROOT/001-database/001-filegroups/001-healthcare-form.sql"

# Master deployment
echo "Running master deployment..."
docker exec -i $CONTAINER_NAME /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" < "$PROJECT_ROOT/COMPLETE_MASTER_DEPLOYMENT.sql"

echo -e "${GREEN}✓ Database deployment complete!${NC}"
echo ""
echo "Connection string:"
echo "Server=localhost,1433; Database=$DATABASE; User Id=SA; Password=$SA_PASSWORD;"
echo ""
echo "Connect with sqlcmd:"
echo "sqlcmd -S localhost -U SA -P '$SA_PASSWORD'"
```

Save as `deploy-docker.sh` and run:

```bash
chmod +x ~/HealthcareForm/deploy-docker.sh
./deploy-docker.sh
```

### Docker Management Commands

```bash
# Check running containers
docker ps

# View logs
docker logs healthcare-mssql -f

# Connect to container
docker exec -it healthcare-mssql /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P 'YourPassword@123'

# Backup database
docker exec -i healthcare-mssql /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P 'YourPassword@123' -Q "BACKUP DATABASE [HealthcareForm] TO DISK='/var/opt/mssql/backup/healthcare-form.bak'"

# Restore database
docker exec -i healthcare-mssql /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P 'YourPassword@123' -Q "RESTORE DATABASE [HealthcareForm] FROM DISK='/var/opt/mssql/backup/healthcare-form.bak'"

# Stop container
docker stop healthcare-mssql

# Start container
docker start healthcare-mssql

# Remove container
docker rm healthcare-mssql

# View resource usage
docker stats healthcare-mssql
```

### Docker Paths in Deployment Scripts

When running in Docker, the internal paths are:

```
/var/opt/mssql/data/       (instead of /var/lib/mssql/data/)
/var/opt/mssql/log/        (instead of /var/lib/mssql/log/)
/var/opt/mssql/backup/     (instead of /var/lib/mssql/backup/)
```

Your database creation script already uses the correct paths, but if you need to adjust for Docker:

**Docker Database File Paths:**

```sql
-- For Docker containers
FILENAME='/var/opt/mssql/data/healthcare-form-primary.mdf'
FILENAME='/var/opt/mssql/data/healthcare-form-patient-data-1.ndf'
FILENAME='/var/opt/mssql/data/healthcare-form-patient-data-2.ndf'
FILENAME='/var/opt/mssql/log/healthcare-form.ldf'
```

### Docker vs Native SQL Server

| Feature | Docker | Native |
|:--|:--|:--|
| **Installation** | Easy (one command) | Complex (multiple steps) |
| **Dependency Management** | Automatic | Manual |
| **Isolation** | Complete | System-wide |
| **Performance** | ~99% of native | 100% |
| **Persistence** | Volume mounts | File system |
| **Scaling** | Easy (multiple containers) | Complex |
| **Backup/Restore** | Easy (copy volumes) | Standard procedures |
| **Recommended** | ✅ Yes (for Linux) | For production servers |

---

## 2. Linux Directory Structure Recommendations

### Current Structure (Windows-style)
```
001. Database & FileGroups/
002. Schema/
003. Tables/
005. Table Inserts/
006. Stored Procedures/
007. Triggers & Functions/
```

### Recommended Linux Structure
```
/home/samkelo/HealthcareForm/
├── 001-database/                    # Database creation scripts
│   └── 001-filegroups/              # Filegroup definitions
│       └── 001-healthcare-form.sql  # Main database creation
│
├── 002-schemas/                     # Schema creation scripts
│   └── 001-schemas.sql              # Schema definitions
│
├── 003-tables/                      # Table creation scripts (34 files)
│   ├── location/
│   │   ├── countries.sql
│   │   ├── provinces.sql
│   │   ├── cities.sql
│   │   └── address.sql
│   ├── profile/
│   │   ├── gender.sql
│   │   ├── marital-status.sql
│   │   ├── patient.sql
│   │   └── ...
│   ├── contacts/
│   ├── healthcare-services/
│   ├── forms/
│   ├── billing/
│   ├── auth/
│   └── security/
│
├── 005-table-inserts/              # Data initialization scripts
│   ├── insert-countries.sql
│   ├── insert-provinces.sql
│   ├── insert-cities.sql
│   ├── insert-gender.sql
│   ├── insert-marital-status.sql
│   ├── insert-roles.sql
│   ├── insert-permissions.sql
│   ├── insert-role-permissions.sql
│   ├── insert-admin-user.sql
│   ├── insert-billing-codes.sql
│   ├── insert-healthcare-providers.sql
│   ├── insert-insurance-providers.sql
│   ├── insert-allergies-medications.sql
│   └── insert-sample-test-data.sql
│
├── 006-stored-procedures/          # Stored procedure scripts
│   ├── profile-add-patient.sql
│   ├── profile-get-patient.sql
│   ├── profile-update-patient.sql
│   ├── profile-delete-patient.sql
│   ├── profile-get-gender.sql
│   ├── profile-get-marital-status.sql
│   ├── location-get-countries.sql
│   ├── location-get-provinces.sql
│   ├── location-get-cities.sql
│   └── auth-get-errors.sql
│
├── 007-triggers-functions/         # Functions and triggers
│   ├── capitalize-first-letter.sql
│   ├── format-phone-contact.sql
│   └── validate-email.sql
│
├── COMPLETE_MASTER_DEPLOYMENT.sql
├── DEPLOYMENT_EXECUTION_GUIDE.md
└── LINUX_MIGRATION_GUIDE.md        # This file
```

---

## 3. SQL Server Data Directory Configuration

### Recommended Linux Paths

SQL Server on Linux typically uses these directories:

```
Data Files:   /var/lib/mssql/data/
Log Files:    /var/lib/mssql/log/
Backups:      /var/lib/mssql/backup/
Temp DB:      /var/lib/mssql/data/
```

### Verify SQL Server Paths

To check current SQL Server paths on Linux:

```bash
# Check SQL Server is running
sudo systemctl status mssql-server

# Check default data directory
docker inspect mssql 2>/dev/null || systemctl show mssql-server -p ExecStart

# Manual check
ls -la /var/lib/mssql/data/
ls -la /var/lib/mssql/log/
```

### Set Up Directories with Proper Permissions

```bash
# Create directories if they don't exist
sudo mkdir -p /var/lib/mssql/data
sudo mkdir -p /var/lib/mssql/log
sudo mkdir -p /var/lib/mssql/backup

# Set ownership to mssql user
sudo chown -R mssql:mssql /var/lib/mssql/data
sudo chown -R mssql:mssql /var/lib/mssql/log
sudo chown -R mssql:mssql /var/lib/mssql/backup

# Set proper permissions
sudo chmod -R 755 /var/lib/mssql/data
sudo chmod -R 755 /var/lib/mssql/log
sudo chmod -R 755 /var/lib/mssql/backup
```

---

## 4. File Path Conversions

### Windows → Linux Path Mapping

| Windows Path | Linux Path |
|:--|:--|
| `D:\Data\HealthcareForm_FILEGROUPS\` | `/var/lib/mssql/data/` |
| `E:\Logs\HealthcareForm_FILEGROUPS\` | `/var/lib/mssql/log/` |
| `C:\Backups\` | `/var/lib/mssql/backup/` |
| `HealthcareForm_Prm.mdf` | `healthcare-form-primary.mdf` |
| `PatientData_1.ndf` | `healthcare-form-patient-data-1.ndf` |
| `PatientData_2.ndf` | `healthcare-form-patient-data-2.ndf` |
| `HealthcareForm.ldf` | `healthcare-form.ldf` |

### Naming Conventions Applied

Linux file naming best practices:
- ✅ Use lowercase letters
- ✅ Use hyphens (-) instead of spaces
- ✅ Use hyphens (-) instead of underscores (_) for readability
- ✅ No special characters (except hyphens and dots)
- ✅ Clear, descriptive names

**Examples:**

| Old (Windows) | New (Linux) |
|:--|:--|
| `Capitalize first letter.sql` | `capitalize-first-letter.sql` |
| `Format Phone Contact.sql` | `format-phone-contact.sql` |
| `[Profile].[spAddPatient].sql` | `profile-add-patient.sql` |
| `Insert Countries.sql` | `insert-countries.sql` |
| `Insert Marital Status.sql` | `insert-marital-status.sql` |

---

## 5. Database File Locations in Updated Script

The database creation script has been updated with Linux paths:

```sql
-- OLD (Windows)
FILENAME='D:\Data\HealthcareForm_FILEGROUPS\HealthcareForm_Prm.mdf'

-- NEW (Linux)
FILENAME='/var/lib/mssql/data/healthcare-form-primary.mdf'
```

---

## 6. Step-by-Step Linux Setup

### Phase 1: Create SQL Server Directories

```bash
# Step 1: Create data directories
sudo mkdir -p /var/lib/mssql/data
sudo mkdir -p /var/lib/mssql/log
sudo mkdir -p /var/lib/mssql/backup

# Step 2: Set ownership
sudo chown -R mssql:mssql /var/lib/mssql

# Step 3: Set permissions
sudo chmod -R 700 /var/lib/mssql/data
sudo chmod -R 700 /var/lib/mssql/log
sudo chmod -R 700 /var/lib/mssql/backup

# Step 4: Verify
ls -la /var/lib/mssql/
```

### Phase 2: Rename Local Project Folders (Optional but Recommended)

If you want to apply Linux naming conventions to your local folders:

```bash
cd ~/HealthcareForm

# Rename folders to Linux convention
mv "001. Database" 001-database
mv "002. Schema" 002-schemas
mv "003. Tables" 003-tables
mv "005. Table Inserts" 005-table-inserts
mv "006. Stored Procedures" 006-stored-procedures
mv "007. Triggers & Functions" 007-triggers-functions

# Verify
ls -la ~/HealthcareForm/
```

### Phase 3: Rename SQL Files (Optional but Recommended)

If you want to rename your SQL files to Linux convention:

```bash
cd ~/HealthcareForm/001-database/001-filegroups/
mv "001. Healthcare form.sql" "001-healthcare-form.sql"

cd ~/HealthcareForm/006-stored-procedures/
rename 's/\s+/-/g; s/\.sql$/.sql/; tr/A-Z/a-z/' *.sql
```

### Phase 4: Execute Database Creation

```bash
# Connect to SQL Server
sqlcmd -S localhost -U SA -P 'YourPassword'

# Or from a script
sqlcmd -S localhost -U SA -P 'YourPassword' -i ~/HealthcareForm/001-database/001-filegroups/001-healthcare-form.sql
```

### Phase 5: Execute Master Deployment Script

```bash
sqlcmd -S localhost -U SA -P 'YourPassword' -i ~/HealthcareForm/COMPLETE_MASTER_DEPLOYMENT.sql
```

---

## 7. PowerShell Script for Linux Batch Execution

Create a PowerShell script to execute all SQL files:

```powershell
#!/usr/bin/env pwsh

# Configuration
$sqlServerInstance = "localhost"
$username = "SA"
$password = $env:MSSQL_SA_PASSWORD
$database = "HealthcareForm"
$projectRoot = "/home/samkelo/HealthcareForm"

# Function to execute SQL file
function Execute-SQLFile {
    param(
        [string]$FilePath,
        [string]$Database = "master"
    )
    
    Write-Host "Executing: $FilePath..."
    sqlcmd -S $sqlServerInstance -U $username -P $password -d $Database -i $FilePath
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Success: $FilePath" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed: $FilePath" -ForegroundColor Red
        return $false
    }
    return $true
}

# Phase 1: Database Creation
Write-Host "`n[PHASE 1] Database Creation..." -ForegroundColor Yellow
Execute-SQLFile "$projectRoot/001-database/001-filegroups/001-healthcare-form.sql"

# Phase 2: Master Deployment Script (creates schemas)
Write-Host "`n[PHASE 2] Schema & Framework..." -ForegroundColor Yellow
Execute-SQLFile "$projectRoot/COMPLETE_MASTER_DEPLOYMENT.sql"

# Phase 3: Table Creation
Write-Host "`n[PHASE 3] Table Creation..." -ForegroundColor Yellow
$tableFiles = Get-ChildItem -Path "$projectRoot/003-tables" -Filter "*.sql" -Recurse | Sort-Object Name
foreach ($file in $tableFiles) {
    Execute-SQLFile $file.FullName $database
}

# Phase 4: Functions
Write-Host "`n[PHASE 4] Function Creation..." -ForegroundColor Yellow
$functionFiles = Get-ChildItem -Path "$projectRoot/007-triggers-functions" -Filter "*.sql" -Recurse
foreach ($file in $functionFiles) {
    Execute-SQLFile $file.FullName $database
}

# Phase 5: Stored Procedures
Write-Host "`n[PHASE 5] Stored Procedure Creation..." -ForegroundColor Yellow
$procFiles = Get-ChildItem -Path "$projectRoot/006-stored-procedures" -Filter "*.sql" -Recurse
foreach ($file in $procFiles) {
    Execute-SQLFile $file.FullName $database
}

# Phase 6: Data Initialization
Write-Host "`n[PHASE 6] Data Initialization..." -ForegroundColor Yellow
$insertOrder = @(
    "insert-countries.sql",
    "insert-provinces.sql",
    "insert-cities.sql",
    "insert-gender.sql",
    "insert-marital-status.sql",
    "insert-roles.sql",
    "insert-permissions.sql",
    "insert-role-permissions.sql",
    "insert-admin-user.sql",
    "insert-billing-codes.sql",
    "insert-healthcare-providers.sql",
    "insert-insurance-providers.sql",
    "insert-allergies-medications.sql",
    "insert-sample-test-data.sql"
)

foreach ($fileName in $insertOrder) {
    $filePath = "$projectRoot/005-table-inserts/$fileName"
    if (Test-Path $filePath) {
        Execute-SQLFile $filePath $database
    }
}

Write-Host "`n[COMPLETE] Database deployment finished!" -ForegroundColor Green
```

Save as `deploy-linux.ps1` and run:

```bash
chmod +x ~/HealthcareForm/deploy-linux.ps1
pwsh ~/HealthcareForm/deploy-linux.ps1
```

---

## 8. Bash Script for Linux Batch Execution

For pure bash environments without PowerShell:

```bash
#!/bin/bash

# Configuration
SQL_SERVER="localhost"
USERNAME="SA"
PASSWORD="${MSSQL_SA_PASSWORD}"
DATABASE="HealthcareForm"
PROJECT_ROOT="$HOME/HealthcareForm"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to execute SQL file
execute_sql_file() {
    local file_path="$1"
    local db="${2:-master}"
    
    echo -e "${YELLOW}Executing: $(basename $file_path)...${NC}"
    
    sqlcmd -S "$SQL_SERVER" -U "$USERNAME" -P "$PASSWORD" -d "$db" -i "$file_path" > /tmp/sql_output.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Success: $(basename $file_path)${NC}"
    else
        echo -e "${RED}✗ Failed: $(basename $file_path)${NC}"
        cat /tmp/sql_output.log
    fi
}

# Phase 1: Database Creation
echo -e "\n${YELLOW}[PHASE 1] Database Creation...${NC}"
execute_sql_file "$PROJECT_ROOT/001-database/001-filegroups/001-healthcare-form.sql"

# Phase 2: Master Script
echo -e "\n${YELLOW}[PHASE 2] Schema & Framework...${NC}"
execute_sql_file "$PROJECT_ROOT/COMPLETE_MASTER_DEPLOYMENT.sql"

# Phase 3: Tables
echo -e "\n${YELLOW}[PHASE 3] Table Creation...${NC}"
find "$PROJECT_ROOT/003-tables" -name "*.sql" -type f | sort | while read file; do
    execute_sql_file "$file" "$DATABASE"
done

# Phase 4: Functions
echo -e "\n${YELLOW}[PHASE 4] Function Creation...${NC}"
find "$PROJECT_ROOT/007-triggers-functions" -name "*.sql" -type f | while read file; do
    execute_sql_file "$file" "$DATABASE"
done

# Phase 5: Procedures
echo -e "\n${YELLOW}[PHASE 5] Stored Procedure Creation...${NC}"
find "$PROJECT_ROOT/006-stored-procedures" -name "*.sql" -type f | while read file; do
    execute_sql_file "$file" "$DATABASE"
done

# Phase 6: Data Initialization (ordered)
echo -e "\n${YELLOW}[PHASE 6] Data Initialization...${NC}"
for file in \
    "insert-countries.sql" \
    "insert-provinces.sql" \
    "insert-cities.sql" \
    "insert-gender.sql" \
    "insert-marital-status.sql" \
    "insert-roles.sql" \
    "insert-permissions.sql" \
    "insert-role-permissions.sql" \
    "insert-admin-user.sql" \
    "insert-billing-codes.sql" \
    "insert-healthcare-providers.sql" \
    "insert-insurance-providers.sql" \
    "insert-allergies-medications.sql" \
    "insert-sample-test-data.sql"
do
    if [ -f "$PROJECT_ROOT/005-table-inserts/$file" ]; then
        execute_sql_file "$PROJECT_ROOT/005-table-inserts/$file" "$DATABASE"
    fi
done

echo -e "\n${GREEN}[COMPLETE] Database deployment finished!${NC}"
```

Save as `deploy-linux.sh` and run:

```bash
chmod +x ~/HealthcareForm/deploy-linux.sh
./deploy-linux.sh
```

---

## 9. Environment Variables

Set up environment variables for easier management:

```bash
# Add to ~/.bashrc or ~/.bash_profile
export MSSQL_SA_PASSWORD="YourSQLPassword"
export SQLCMDPASSWORD="YourSQLPassword"
export SQLCMDUSER="SA"
export SQLCMDSERVER="localhost"
export HEALTHCARE_DB_HOME="/home/samkelo/HealthcareForm"

# Reload
source ~/.bashrc
```

---

## 10. Linux File Permissions Best Practices

```bash
# Make scripts executable
chmod +x ~/HealthcareForm/deploy-linux.sh
chmod +x ~/HealthcareForm/deploy-linux.ps1
chmod +x ~/HealthcareForm/**/*.sql

# Create a backup directory
mkdir -p ~/HealthcareForm/backups
chmod 700 ~/HealthcareForm/backups

# Create a logs directory
mkdir -p ~/HealthcareForm/logs
chmod 700 ~/HealthcareForm/logs
```

---

## 11. Troubleshooting

### Issue: "sqlcmd: command not found"

**Solution:** Install SQL Server tools:

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install mssql-tools

# RHEL/CentOS
sudo yum install mssql-tools

# Add to PATH
export PATH="$PATH:/opt/mssql-tools/bin"
```

### Issue: "Cannot bulk load because the file does not exist"

**Solution:** Verify file paths use forward slashes:

```sql
-- Wrong (Windows)
FILENAME='D:\Data\file.mdf'

-- Correct (Linux)
FILENAME='/var/lib/mssql/data/file.mdf'
```

### Issue: "Login failed for user 'SA'"

**Solution:** Check SQL Server is running:

```bash
sudo systemctl status mssql-server
sudo systemctl start mssql-server
```

### Issue: "Permission denied" on data directories

**Solution:** Fix permissions:

```bash
sudo chown -R mssql:mssql /var/lib/mssql
sudo chmod -R 700 /var/lib/mssql
```

---

## 12. Checklist: Linux Migration Complete

- [ ] SQL Server directories created (/var/lib/mssql/data, log, backup)
- [ ] Directory permissions set (mssql:mssql ownership, 700 mode)
- [ ] Database creation script updated with Linux paths
- [ ] Master deployment script updated with Linux paths
- [ ] Folder structure renamed (optional: from spaced names to hyphenated)
- [ ] SQL file names updated (optional: to Linux conventions)
- [ ] Environment variables set
- [ ] Deployment script (bash/PowerShell) created
- [ ] sqlcmd tools installed
- [ ] Test connection to SQL Server works
- [ ] Database deployment executed
- [ ] Verification queries run successfully
- [ ] Backup strategy configured

---

## 13. Next Steps

1. **Complete the checklist above**
2. **Run the deployment script:**
   ```bash
   ./deploy-linux.sh  # or deploy-linux.ps1
   ```
3. **Verify deployment:**
   ```bash
   sqlcmd -S localhost -U SA -P 'Password' -d HealthcareForm \
     -Q "SELECT COUNT(*) as Tables FROM information_schema.tables"
   ```
4. **Change admin password immediately:**
   ```sql
   UPDATE Security.Users 
   SET PasswordHash = HASHBYTES('SHA2_256', N'NewPassword')
   WHERE UserName = 'admin'
   ```
5. **Configure backups:**
   ```bash
   # Create backup script
   mkdir -p /var/lib/mssql/backup
   chmod 700 /var/lib/mssql/backup
   ```

---

## Summary

Your healthcare database has been successfully converted to Linux:

✅ **Database Paths:** Windows `D:\` and `E:\` → Linux `/var/lib/mssql/`  
✅ **File Naming:** Spaces and mixed case → Lowercase with hyphens  
✅ **Folder Structure:** Organized with Linux conventions  
✅ **Deployment Scripts:** Updated for Linux compatibility  
✅ **Documentation:** Complete setup guides provided  

**Status:** Ready for Linux deployment

---

**Questions?** Refer to the DEPLOYMENT_EXECUTION_GUIDE.md for detailed deployment steps.
