-- V1__baseline.sql
-- Baseline migration: full inline master deployment
-- This file was generated from `000_INLINE_MASTER_DEPLOYMENT.sql` to bootstrap Flyway migrations.
-- IMPORTANT: review and split into smaller migrations where appropriate before applying to production.

-- Begin inline master content

-- 000_INLINE_MASTER_DEPLOYMENT.sql
-- Inline master deployment for the HealthcareForm database
-- This file is safe to run in plain SSMS / T-SQL (no SQLCMD directives).
-- Run as a login with permission to CREATE DATABASE and CREATE objects.
-- Recommended: Connect to master and execute this file (SSMS) or run via sqlcmd.

-- =================================================================================================
-- 1) Create database if not exists (filegroups included)
-- =================================================================================================
IF DB_ID('HealthcareForm') IS NULL
BEGIN
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
END
GO

-- =================================================================================================
-- 2) Database options (apply only if DB exists)
-- =================================================================================================
IF DB_ID('HealthcareForm') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM HealthcareForm.sys.filegroups
        WHERE name = 'PatientDataGroup'
          AND is_default = 0
    )
        ALTER DATABASE HealthcareForm MODIFY FILEGROUP PatientDataGroup DEFAULT;
    ALTER DATABASE HealthcareForm SET RECOVERY FULL;
    ALTER DATABASE HealthcareForm SET AUTO_UPDATE_STATISTICS ON;
    ALTER DATABASE HealthcareForm SET AUTO_SHRINK OFF;
    ALTER DATABASE HealthcareForm SET PAGE_VERIFY CHECKSUM;
END
GO

-- Switch context to the target database
USE HealthcareForm;
GO

-- =================================================================================================
-- 3) Create Schemas
-- =================================================================================================
-- From: 002-schema/001. Schema's Script.sql (stripped USE/GO)
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Location Schema: Geographic and address information
CREATE SCHEMA Location
GO

-- Profile Schema: Patient demographic and personal information
CREATE SCHEMA Profile
GO

-- Contacts Schema: Communication contact details (phone, email, emergency contacts)
CREATE SCHEMA Contacts
GO

-- Auth Schema: Authentication, authorization, and error logging
CREATE SCHEMA Auth
GO

-- Exceptions Schema: Exception and error tracking
CREATE SCHEMA Exceptions
GO

-- =================================================================================================
-- 4) Create Tables (inlined from 003-tables). Each section had its own SETs/GO as required.
-- NOTE: original per-file "USE HealthcareForm" lines were removed.
-- =================================================================================================

-- Auth.AuditLog
IF OBJECT_ID(N'[Auth].[AuditLog]', N'U') IS NULL
BEGIN
CREATE TABLE Auth.AuditLog
(
	AuditLogID INT NOT NULL PRIMARY KEY IDENTITY (1,1),
	ModifiedTime DATETIME NOT NULL,
	ModifiedBy VARCHAR(250) NOT NULL,
	Operation VARCHAR(250) NOT NULL,
	SchemaName VARCHAR(250) NOT NULL,
	TableName VARCHAR(250) NOT NULL,
	TableID UNIQUEIDENTIFIER NOT NULL,
	LogData VARCHAR(MAX) NOT NULL
)
END
GO

-- Auth.Permissions
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Auth].[Permissions]', N'U') IS NULL
BEGIN
CREATE TABLE [Auth].[Permissions](
	[PermissionId] [uniqueidentifier] NOT NULL,
	[PermissionName] [varchar](250) NOT NULL UNIQUE,
	[Description] [varchar](MAX) NULL,
	[Category] [varchar](100) NOT NULL,
	[Module] [varchar](100) NOT NULL,
	[ActionType] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL DEFAULT 1,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[PermissionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Auth].[Permissions]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Auth].[Permissions]')
      AND c.name = N'PermissionId'
)
BEGIN
ALTER TABLE [Auth].[Permissions] ADD DEFAULT (newid()) FOR [PermissionId]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[Permissions]') AND name = 'IX_Permissions_Category')
BEGIN
CREATE INDEX IX_Permissions_Category ON [Auth].[Permissions]([Category])
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[Permissions]') AND name = 'IX_Permissions_Module')
BEGIN
CREATE INDEX IX_Permissions_Module ON [Auth].[Permissions]([Module])
END
GO

-- Auth.RolePermissions
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Auth].[RolePermissions]', N'U') IS NULL
BEGIN
CREATE TABLE [Auth].[RolePermissions](
	[RolePermissionId] [uniqueidentifier] NOT NULL,
	[RoleIdFK] [uniqueidentifier] NOT NULL,
	[PermissionIdFK] [uniqueidentifier] NOT NULL,
	[GrantedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[GrantedBy] [varchar](250) NULL,
	[IsActive] [bit] NOT NULL DEFAULT 1,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[RolePermissionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Auth].[RolePermissions]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Auth].[RolePermissions]')
      AND c.name = N'RolePermissionId'
)
BEGIN
ALTER TABLE [Auth].[RolePermissions] ADD DEFAULT (newid()) FOR [RolePermissionId]
END
GO
-- Foreign keys created later since referenced tables may not exist yet (we will recreate constraints after all tables created)

-- Auth.Roles
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Auth].[Roles]', N'U') IS NULL
BEGIN
CREATE TABLE [Auth].[Roles](
	[RoleId] [uniqueidentifier] NOT NULL,
	[RoleName] [varchar](100) NOT NULL UNIQUE,
	[Description] [varchar](MAX) NULL,
	[IsActive] [bit] NOT NULL DEFAULT 1,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[RoleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Auth].[Roles]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Auth].[Roles]')
      AND c.name = N'RoleId'
)
BEGIN
ALTER TABLE [Auth].[Roles] ADD DEFAULT (newid()) FOR [RoleId]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[Roles]') AND name = 'IX_Roles_RoleName')
BEGIN
CREATE INDEX IX_Roles_RoleName ON [Auth].[Roles]([RoleName])
END
GO

-- Auth.UserActivityAudit
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Auth].[UserActivityAudit]', N'U') IS NULL
BEGIN
CREATE TABLE [Auth].[UserActivityAudit](
	[UserActivityId] [uniqueidentifier] NOT NULL,
	[UserIdFK] [uniqueidentifier] NOT NULL,
	[ActivityType] [varchar](100) NOT NULL,
	[Description] [varchar](MAX) NULL,
	[TableName] [varchar](250) NULL,
	[RecordId] [uniqueidentifier] NULL,
	[OldValue] [varchar](MAX) NULL,
	[NewValue] [varchar](MAX) NULL,
	[IPAddress] [varchar](50) NOT NULL,
	[UserAgent] [varchar](500) NULL,
	[Status] [varchar](50) NOT NULL DEFAULT 'Success',
	[ErrorMessage] [varchar](MAX) NULL,
	[ActivityDateTime] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[UserActivityId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Auth].[UserActivityAudit]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Auth].[UserActivityAudit]')
      AND c.name = N'UserActivityId'
)
BEGIN
ALTER TABLE [Auth].[UserActivityAudit] ADD DEFAULT (newid()) FOR [UserActivityId]
END
GO

-- Auth.UserRoles
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Auth].[UserRoles]', N'U') IS NULL
BEGIN
CREATE TABLE [Auth].[UserRoles](
	[UserRoleId] [uniqueidentifier] NOT NULL,
	[UserIdFK] [uniqueidentifier] NOT NULL,
	[RoleIdFK] [uniqueidentifier] NOT NULL,
	[AssignedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[AssignedBy] [varchar](250) NULL,
	[ExpiryDate] [datetime] NULL,
	[IsActive] [bit] NOT NULL DEFAULT 1,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[UserRoleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Auth].[UserRoles]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Auth].[UserRoles]')
      AND c.name = N'UserRoleId'
)
BEGIN
ALTER TABLE [Auth].[UserRoles] ADD DEFAULT (newid()) FOR [UserRoleId]
END
GO

-- Auth.Users
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Auth].[Users]', N'U') IS NULL
BEGIN
CREATE TABLE [Auth].[Users](
	[UserId] [uniqueidentifier] NOT NULL,
	[Username] [varchar](100) NOT NULL UNIQUE,
	[Email] [varchar](250) NOT NULL UNIQUE,
	[PasswordHash] [varchar](MAX) NOT NULL,
	[FirstName] [varchar](250) NOT NULL,
	[LastName] [varchar](250) NOT NULL,
	[IsActive] [bit] NOT NULL DEFAULT 1,
	[AccountLockedUntil] [datetime] NULL,
	[FailedLoginAttempts] [int] NOT NULL DEFAULT 0,
	[LastLoginDate] [datetime] NULL,
	[LastPasswordChangeDate] [datetime] NULL,
	[MustChangePasswordOnLogin] [bit] NOT NULL DEFAULT 0,
	[IsSuperAdmin] [bit] NOT NULL DEFAULT 0,
	[PhoneNumber] [varchar](15) NULL,
	[Department] [varchar](100) NULL,
	[ProfileImagePath] [varchar](500) NULL,
	[Notes] [varchar](MAX) NULL,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Auth].[Users]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Auth].[Users]')
      AND c.name = N'UserId'
)
BEGIN
ALTER TABLE [Auth].[Users] ADD DEFAULT (newid()) FOR [UserId]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[Users]') AND name = 'IX_Users_Username')
BEGIN
CREATE INDEX IX_Users_Username ON [Auth].[Users]([Username])
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[Users]') AND name = 'IX_Users_Email')
BEGIN
CREATE INDEX IX_Users_Email ON [Auth].[Users]([Email])
END
GO

-- (rest of inline master continues...)

-- NOTE: The inline master contained many DDL and seed statements. For maintainability it's recommended to split this single baseline into multiple incremental migrations (schema first, then indexes/defaults, then FKs, then seed data) and remove the large baseline once a proper migration history is in place.

-- End inline master content
