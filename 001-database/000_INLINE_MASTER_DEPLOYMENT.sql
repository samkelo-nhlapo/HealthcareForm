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
        FILENAME='/var/opt/mssql/data/healthcare-form-primary.mdf',
        SIZE=500MB,
        MAXSIZE=5GB,
        FILEGROWTH=100MB),
    FILEGROUP PatientDataGroup
      ( NAME = 'PatientData_File1',
        FILENAME='/var/opt/mssql/data/healthcare-form-patient-data-1.ndf',
        SIZE=1GB,
        MAXSIZE=10GB,
        FILEGROWTH=100MB),
      ( NAME = 'PatientData_File2',
        FILENAME='/var/opt/mssql/data/healthcare-form-patient-data-2.ndf',
        SIZE=1GB,
        MAXSIZE=10GB,
        FILEGROWTH=100MB)
    LOG ON
      ( NAME='HealthcareForm_Log',
        FILENAME='/var/opt/mssql/data/healthcare-form.ldf',
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
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Location')
	EXEC('CREATE SCHEMA Location')
GO

-- Profile Schema: Patient demographic and personal information
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Profile')
	EXEC('CREATE SCHEMA Profile')
GO

-- Contacts Schema: Communication contact details (phone, email, emergency contacts)
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Contacts')
	EXEC('CREATE SCHEMA Contacts')
GO

-- Auth Schema: Authentication, authorization, and error logging
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Auth')
	EXEC('CREATE SCHEMA Auth')
GO

-- Exceptions Schema: Exception and error tracking
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Exceptions')
	EXEC('CREATE SCHEMA Exceptions')
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

IF OBJECT_ID(N'[Auth].[RolePermissions]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Auth].[Roles]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Auth].[RolePermissions]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Auth].[RolePermissions]'), N'RoleIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Auth].[Roles]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Auth].[Roles]'), N'RoleId', 'ColumnId')
)
BEGIN
ALTER TABLE [Auth].[RolePermissions] WITH CHECK ADD FOREIGN KEY([RoleIdFK])
REFERENCES [Auth].[Roles] ([RoleId])
END
GO
IF OBJECT_ID(N'[Auth].[RolePermissions]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Auth].[Permissions]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Auth].[RolePermissions]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Auth].[RolePermissions]'), N'PermissionIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Auth].[Permissions]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Auth].[Permissions]'), N'PermissionId', 'ColumnId')
)
BEGIN
ALTER TABLE [Auth].[RolePermissions] WITH CHECK ADD FOREIGN KEY([PermissionIdFK])
REFERENCES [Auth].[Permissions] ([PermissionId])
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[RolePermissions]') AND name = 'UX_RolePermissions_RolePermission')
BEGIN
CREATE UNIQUE INDEX UX_RolePermissions_RolePermission ON [Auth].[RolePermissions]([RoleIdFK], [PermissionIdFK])
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[RolePermissions]') AND name = 'IX_RolePermissions_RoleIdFK')
BEGIN
CREATE INDEX IX_RolePermissions_RoleIdFK ON [Auth].[RolePermissions]([RoleIdFK])
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[RolePermissions]') AND name = 'IX_RolePermissions_PermissionIdFK')
BEGIN
CREATE INDEX IX_RolePermissions_PermissionIdFK ON [Auth].[RolePermissions]([PermissionIdFK])
END
GO

IF OBJECT_ID(N'[Auth].[UserRoles]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Auth].[Users]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Auth].[UserRoles]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Auth].[UserRoles]'), N'UserIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Auth].[Users]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Auth].[Users]'), N'UserId', 'ColumnId')
)
BEGIN
ALTER TABLE [Auth].[UserRoles] WITH CHECK ADD FOREIGN KEY([UserIdFK])
REFERENCES [Auth].[Users] ([UserId])
END
GO
IF OBJECT_ID(N'[Auth].[UserRoles]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Auth].[Roles]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Auth].[UserRoles]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Auth].[UserRoles]'), N'RoleIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Auth].[Roles]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Auth].[Roles]'), N'RoleId', 'ColumnId')
)
BEGIN
ALTER TABLE [Auth].[UserRoles] WITH CHECK ADD FOREIGN KEY([RoleIdFK])
REFERENCES [Auth].[Roles] ([RoleId])
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[UserRoles]') AND name = 'UX_UserRoles_UserRole')
BEGIN
CREATE UNIQUE INDEX UX_UserRoles_UserRole ON [Auth].[UserRoles]([UserIdFK], [RoleIdFK])
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[UserRoles]') AND name = 'IX_UserRoles_UserIdFK')
BEGIN
CREATE INDEX IX_UserRoles_UserIdFK ON [Auth].[UserRoles]([UserIdFK])
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[UserRoles]') AND name = 'IX_UserRoles_RoleIdFK')
BEGIN
CREATE INDEX IX_UserRoles_RoleIdFK ON [Auth].[UserRoles]([RoleIdFK])
END
GO

IF OBJECT_ID(N'[Auth].[UserActivityAudit]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Auth].[Users]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Auth].[UserActivityAudit]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Auth].[UserActivityAudit]'), N'UserIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Auth].[Users]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Auth].[Users]'), N'UserId', 'ColumnId')
)
BEGIN
ALTER TABLE [Auth].[UserActivityAudit] WITH CHECK ADD FOREIGN KEY([UserIdFK])
REFERENCES [Auth].[Users] ([UserId])
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[UserActivityAudit]') AND name = 'IX_UserActivityAudit_UserIdFK')
BEGIN
CREATE INDEX IX_UserActivityAudit_UserIdFK ON [Auth].[UserActivityAudit]([UserIdFK])
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[UserActivityAudit]') AND name = 'IX_UserActivityAudit_ActivityType')
BEGIN
CREATE INDEX IX_UserActivityAudit_ActivityType ON [Auth].[UserActivityAudit]([ActivityType])
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[UserActivityAudit]') AND name = 'IX_UserActivityAudit_ActivityDateTime')
BEGIN
CREATE INDEX IX_UserActivityAudit_ActivityDateTime ON [Auth].[UserActivityAudit]([ActivityDateTime])
END
GO

-- Contacts.Emails
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Contacts].[Emails]', N'U') IS NULL
BEGIN
CREATE TABLE [Contacts].[Emails](
	[EmailId] [uniqueidentifier] NOT NULL,
	[Email] [varchar](250) NOT NULL UNIQUE,
	[IsActive] [bit] NOT NULL,
	[UpdateDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[EmailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Contacts].[Emails]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Contacts].[Emails]')
      AND c.name = N'EmailId'
)
BEGIN
ALTER TABLE [Contacts].[Emails] ADD  DEFAULT (newid()) FOR [EmailId]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[Emails]') AND name = 'IX_Emails_Email')
BEGIN
CREATE INDEX IX_Emails_Email ON [Contacts].[Emails]([Email])
END
GO

-- Contacts.EmergencyContacts
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Contacts].[EmergencyContacts]', N'U') IS NULL
BEGIN
CREATE TABLE [Contacts].[EmergencyContacts](
	[EmergencyId] [uniqueidentifier] NOT NULL,
	[FirstName] [varchar](250) NOT NULL,
	[LastName] [varchar](250) NOT NULL,
	[PhoneNumber] [varchar](250) NOT NULL,
	[Relationship] [varchar](250) NOT NULL,
	[DateOfBirth] [datetime] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[UpdateDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[EmergencyId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Contacts].[EmergencyContacts]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Contacts].[EmergencyContacts]')
      AND c.name = N'EmergencyId'
)
BEGIN
ALTER TABLE [Contacts].[EmergencyContacts] ADD  DEFAULT (newid()) FOR [EmergencyId]
END
GO

-- Contacts.FormAttachments
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Contacts].[FormAttachments]', N'U') IS NULL
BEGIN
CREATE TABLE [Contacts].[FormAttachments](
	[FormAttachmentId] [uniqueidentifier] NOT NULL,
	[FormSubmissionIdFK] [uniqueidentifier] NOT NULL,
	[FileName] [varchar](500) NOT NULL,
	[FileType] [varchar](50) NOT NULL,
	[FileSizeBytes] [bigint] NOT NULL,
	[FileHash] [varchar](64) NULL,
	[StoragePath] [varchar](MAX) NOT NULL,
	[DocumentType] [varchar](100) NOT NULL,
	[UploadedDate] [datetime] NOT NULL,
	[UploadedBy] [varchar](250) NOT NULL,
	[IsVerified] [bit] NOT NULL DEFAULT 0,
	[VerifiedBy] [varchar](250) NULL,
	[VerificationDate] [datetime] NULL,
	[ExpiryDate] [datetime] NULL,
	[Notes] [varchar](MAX) NULL,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[FormAttachmentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Contacts].[FormAttachments]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Contacts].[FormAttachments]')
      AND c.name = N'FormAttachmentId'
)
BEGIN
ALTER TABLE [Contacts].[FormAttachments] ADD DEFAULT (newid()) FOR [FormAttachmentId]
END
GO
-- Foreign key: FormSubmissionIdFK -> Contacts.FormSubmissions will be added later
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[FormAttachments]') AND name = 'IX_FormAttachments_FormSubmissionIdFK')
BEGIN
CREATE INDEX IX_FormAttachments_FormSubmissionIdFK ON [Contacts].[FormAttachments]([FormSubmissionIdFK])
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[FormAttachments]') AND name = 'IX_FormAttachments_DocumentType')
BEGIN
CREATE INDEX IX_FormAttachments_DocumentType ON [Contacts].[FormAttachments]([DocumentType])
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[FormAttachments]') AND name = 'IX_FormAttachments_UploadedDate')
BEGIN
CREATE INDEX IX_FormAttachments_UploadedDate ON [Contacts].[FormAttachments]([UploadedDate])
END
GO

-- Contacts.FormFieldValues
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Contacts].[FormFieldValues]', N'U') IS NULL
BEGIN
CREATE TABLE [Contacts].[FormFieldValues](
	[FormFieldValueId] [uniqueidentifier] NOT NULL,
	[FormSubmissionIdFK] [uniqueidentifier] NOT NULL,
	[FieldName] [varchar](250) NOT NULL,
	[FieldType] [varchar](50) NOT NULL,
	[FieldValue] [varchar](MAX) NOT NULL,
	[DisplayOrder] [int] NULL,
	[IsRequired] [bit] NOT NULL DEFAULT 0,
	[ValidationRules] [varchar](MAX) NULL,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[FormFieldValueId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Contacts].[FormFieldValues]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Contacts].[FormFieldValues]')
      AND c.name = N'FormFieldValueId'
)
BEGIN
ALTER TABLE [Contacts].[FormFieldValues] ADD DEFAULT (newid()) FOR [FormFieldValueId]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[FormFieldValues]') AND name = 'IX_FormFieldValues_FormSubmissionIdFK')
BEGIN
CREATE INDEX IX_FormFieldValues_FormSubmissionIdFK ON [Contacts].[FormFieldValues]([FormSubmissionIdFK])
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[FormFieldValues]') AND name = 'IX_FormFieldValues_FieldName')
BEGIN
CREATE INDEX IX_FormFieldValues_FieldName ON [Contacts].[FormFieldValues]([FieldName])
END
GO

-- Contacts.FormSubmissions
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Contacts].[FormSubmissions]', N'U') IS NULL
BEGIN
CREATE TABLE [Contacts].[FormSubmissions](
	[FormSubmissionId] [uniqueidentifier] NOT NULL,
	[PatientIdFK] [uniqueidentifier] NOT NULL,
	[FormTemplateIdFK] [uniqueidentifier] NOT NULL,
	[SubmissionDate] [datetime] NOT NULL,
	[CompletionDate] [datetime] NULL,
	[Status] [varchar](50) NOT NULL DEFAULT 'Draft',
	[ReviewedBy] [varchar](250) NULL,
	[ReviewDate] [datetime] NULL,
	[RejectionReason] [varchar](MAX) NULL,
	[SignatureDate] [datetime] NULL,
	[SignedBy] [varchar](250) NULL,
	[IPAddress] [varchar](50) NULL,
	[UserAgent] [varchar](500) NULL,
	[Notes] [varchar](MAX) NULL,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[FormSubmissionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Contacts].[FormSubmissions]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Contacts].[FormSubmissions]')
      AND c.name = N'FormSubmissionId'
)
BEGIN
ALTER TABLE [Contacts].[FormSubmissions] ADD DEFAULT (newid()) FOR [FormSubmissionId]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[FormSubmissions]') AND name = 'IX_FormSubmissions_PatientIdFK')
BEGIN
CREATE INDEX IX_FormSubmissions_PatientIdFK ON [Contacts].[FormSubmissions]([PatientIdFK])
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[FormSubmissions]') AND name = 'IX_FormSubmissions_FormTemplateIdFK')
BEGIN
CREATE INDEX IX_FormSubmissions_FormTemplateIdFK ON [Contacts].[FormSubmissions]([FormTemplateIdFK])
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[FormSubmissions]') AND name = 'IX_FormSubmissions_Status')
BEGIN
CREATE INDEX IX_FormSubmissions_Status ON [Contacts].[FormSubmissions]([Status])
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[FormSubmissions]') AND name = 'IX_FormSubmissions_SubmissionDate')
BEGIN
CREATE INDEX IX_FormSubmissions_SubmissionDate ON [Contacts].[FormSubmissions]([SubmissionDate])
END
GO

-- Contacts.FormTemplates
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Contacts].[FormTemplates]', N'U') IS NULL
BEGIN
CREATE TABLE [Contacts].[FormTemplates](
	[FormTemplateId] [uniqueidentifier] NOT NULL,
	[FormName] [varchar](250) NOT NULL UNIQUE,
	[FormVersion] [varchar](20) NOT NULL DEFAULT '1.0',
	[Description] [varchar](MAX) NULL,
	[FormType] [varchar](100) NOT NULL,
	[IsActive] [bit] NOT NULL DEFAULT 1,
	[RequiresSignature] [bit] NOT NULL DEFAULT 1,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[FormTemplateId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Contacts].[FormTemplates]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Contacts].[FormTemplates]')
      AND c.name = N'FormTemplateId'
)
BEGIN
ALTER TABLE [Contacts].[FormTemplates] ADD DEFAULT (newid()) FOR [FormTemplateId]
END
GO

-- Contacts.PatientEmails
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Contacts].[PatientEmails]', N'U') IS NULL
BEGIN
CREATE TABLE [Contacts].[PatientEmails](
	[PatientEmailId] [uniqueidentifier] NOT NULL,
	[PatientIdFK] [uniqueidentifier] NOT NULL,
	[EmailIdFK] [uniqueidentifier] NOT NULL,
	[IsPrimary] [bit] NOT NULL DEFAULT 0,
	[EmailType] [varchar](50) NULL,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[PatientEmailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Contacts].[PatientEmails]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Contacts].[PatientEmails]')
      AND c.name = N'PatientEmailId'
)
BEGIN
ALTER TABLE [Contacts].[PatientEmails] ADD DEFAULT (newid()) FOR [PatientEmailId]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[PatientEmails]') AND name = 'UX_PatientEmails_Unique')
BEGIN
CREATE UNIQUE INDEX UX_PatientEmails_Unique ON [Contacts].[PatientEmails]([PatientIdFK], [EmailIdFK])
END
GO

-- Contacts.PatientPhones
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Contacts].[PatientPhones]', N'U') IS NULL
BEGIN
CREATE TABLE [Contacts].[PatientPhones](
	[PatientPhoneId] [uniqueidentifier] NOT NULL,
	[PatientIdFK] [uniqueidentifier] NOT NULL,
	[PhoneIdFK] [uniqueidentifier] NOT NULL,
	[IsPrimary] [bit] NOT NULL DEFAULT 0,
	[PhoneType] [varchar](50) NULL,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[PatientPhoneId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Contacts].[PatientPhones]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Contacts].[PatientPhones]')
      AND c.name = N'PatientPhoneId'
)
BEGIN
ALTER TABLE [Contacts].[PatientPhones] ADD DEFAULT (newid()) FOR [PatientPhoneId]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[PatientPhones]') AND name = 'UX_PatientPhones_Unique')
BEGIN
CREATE UNIQUE INDEX UX_PatientPhones_Unique ON [Contacts].[PatientPhones]([PatientIdFK], [PhoneIdFK])
END
GO

-- Contacts.Phones
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Contacts].[Phones]', N'U') IS NULL
BEGIN
CREATE TABLE [Contacts].[Phones](
	[PhoneId] [uniqueidentifier] NOT NULL,
	[PhoneNumber] [varchar](15) NOT NULL UNIQUE,
	[IsActive] [bit] NOT NULL,
	[UpdateDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[PhoneId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Contacts].[Phones]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Contacts].[Phones]')
      AND c.name = N'PhoneId'
)
BEGIN
ALTER TABLE [Contacts].[Phones] ADD  DEFAULT (newid()) FOR [PhoneId]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[Phones]') AND name = 'IX_Phones_PhoneNumber')
BEGIN
CREATE INDEX IX_Phones_PhoneNumber ON [Contacts].[Phones]([PhoneNumber])
END
GO

-- Exceptions.Errors
IF OBJECT_ID(N'Exceptions.Errors', N'U') IS NULL
BEGIN
    CREATE TABLE Exceptions.Errors
    (
        ExceptionsID INT NOT NULL PRIMARY KEY IDENTITY (1,1),
        UserName VARCHAR (250) NOT NULL,
        ErrorSchema VARCHAR (250) NOT NULL,
        ErrorProcedure VARCHAR (250) NOT NULL,
        ErrorNumber INT NOT NULL,
        ErrorState INT NOT NULL,
        ErrorSeverity INT NOT NULL,
        ErrorLine INT NOT NULL,
        ErrorMessage VARCHAR (500) NOT NULL,
        ErrorDateTime DATETIME NOT NULL
    )
END
GO

-- Location.Address
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Location].[Address]', N'U') IS NULL
BEGIN
CREATE TABLE [Location].[Address](
	[AddressId] [uniqueidentifier] NOT NULL,
	[Line1] [varchar](250) NOT NULL,
	[Line2] [varchar](250) NOT NULL,
	[CityIDFK] [int] NOT NULL,
	[UpdateDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[AddressId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Location].[Address]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Location].[Address]')
      AND c.name = N'AddressId'
)
BEGIN
ALTER TABLE [Location].[Address] ADD  DEFAULT (newid()) FOR [AddressId]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Location].[Address]') AND name = 'IX_Address_CityIDFK')
BEGIN
CREATE INDEX IX_Address_CityIDFK ON [Location].[Address]([CityIDFK])
END
GO

-- Location.Cities
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Location].[Cities]', N'U') IS NULL
BEGIN
CREATE TABLE [Location].[Cities](
	[CityId] [int] IDENTITY(1,1) NOT NULL,
	[CityName] [varchar](250) NOT NULL,
	[ProvinceIDFK] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[UpdateDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[CityId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

-- Location.Countries
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Location].[Countries]', N'U') IS NULL
BEGIN
CREATE TABLE [Location].[Countries](
	[CountryId] [int] IDENTITY(1,1) NOT NULL,
	[CountryName] [varchar](250) NOT NULL,
	[Alpha2Code] [varchar](5) NOT NULL,
	[Alpha3Code] [varchar](5) NOT NULL,
	[Numeric] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[UpdateDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[CountryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

-- Location.Provinces
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Location].[Provinces]', N'U') IS NULL
BEGIN
CREATE TABLE [Location].[Provinces](
	[ProvinceId] [int] IDENTITY(1,1) NOT NULL,
	[ProvinceName] [varchar](250) NOT NULL,
	[CountryIDFK] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[UpdateDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ProvinceId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

-- Profile.Allergies
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Profile].[Allergies]', N'U') IS NULL
BEGIN
CREATE TABLE [Profile].[Allergies](
	[AllergyId] [uniqueidentifier] NOT NULL,
	[PatientIdFK] [uniqueidentifier] NOT NULL,
	[AllergyType] [varchar](50) NOT NULL,
	[AllergenName] [varchar](250) NOT NULL,
	[Reaction] [varchar](MAX) NOT NULL,
	[Severity] [varchar](50) NOT NULL DEFAULT 'Moderate',
	[ReactionOnsetDate] [datetime] NULL,
	[VerifiedBy] [varchar](250) NULL,
	[IsActive] [bit] NOT NULL DEFAULT 1,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[AllergyId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Profile].[Allergies]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[Allergies]')
      AND c.name = N'AllergyId'
)
BEGIN
ALTER TABLE [Profile].[Allergies] ADD DEFAULT (newid()) FOR [AllergyId]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Allergies]') AND name = 'IX_Allergies_PatientIdFK')
BEGIN
CREATE INDEX IX_Allergies_PatientIdFK ON [Profile].[Allergies]([PatientIdFK])
END
GO

-- Profile.Appointments
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NULL
BEGIN
CREATE TABLE [Profile].[Appointments](
	[AppointmentId] [uniqueidentifier] NOT NULL,
	[PatientIdFK] [uniqueidentifier] NOT NULL,
	[ProviderIdFK] [uniqueidentifier] NOT NULL,
	[AppointmentDateTime] [datetime] NOT NULL,
	[DurationMinutes] [int] NOT NULL DEFAULT 30,
	[AppointmentType] [varchar](100) NOT NULL,
	[Reason] [varchar](MAX) NOT NULL,
	[Location] [varchar](250) NULL,
	[Status] [varchar](50) NOT NULL DEFAULT 'Scheduled',
	[CancellationReason] [varchar](MAX) NULL,
	[CancelledBy] [varchar](250) NULL,
	[CancelledDate] [datetime] NULL,
	[Reminders] [varchar](MAX) NULL,
	[Notes] [varchar](MAX) NULL,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[AppointmentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[Appointments]')
      AND c.name = N'AppointmentId'
)
BEGIN
ALTER TABLE [Profile].[Appointments] ADD DEFAULT (newid()) FOR [AppointmentId]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Appointments]') AND name = 'IX_Appointments_PatientIdFK')
BEGIN
CREATE INDEX IX_Appointments_PatientIdFK ON [Profile].[Appointments]([PatientIdFK])
END
GO

-- Profile.BillingCodes
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Profile].[BillingCodes]', N'U') IS NULL
BEGIN
CREATE TABLE [Profile].[BillingCodes](
	[BillingCodeId] [uniqueidentifier] NOT NULL,
	[CodeType] [varchar](50) NOT NULL,
	[Code] [varchar](20) NOT NULL UNIQUE,
	[Description] [varchar](MAX) NOT NULL,
	[Category] [varchar](100) NULL,
	[Cost] [decimal](10,2) NOT NULL,
	[IsActive] [bit] NOT NULL DEFAULT 1,
	[EffectiveDate] [datetime] NOT NULL,
	[ExpiryDate] [datetime] NULL,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[BillingCodeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Profile].[BillingCodes]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[BillingCodes]')
      AND c.name = N'BillingCodeId'
)
BEGIN
ALTER TABLE [Profile].[BillingCodes] ADD DEFAULT (newid()) FOR [BillingCodeId]
END
GO

-- Profile.ConsultationNotes
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Profile].[ConsultationNotes]', N'U') IS NULL
BEGIN
CREATE TABLE [Profile].[ConsultationNotes](
	[ConsultationNoteId] [uniqueidentifier] NOT NULL,
	[AppointmentIdFK] [uniqueidentifier] NOT NULL,
	[PatientIdFK] [uniqueidentifier] NOT NULL,
	[ProviderIdFK] [uniqueidentifier] NOT NULL,
	[ConsultationDate] [datetime] NOT NULL,
	[ChiefComplaint] [varchar](MAX) NOT NULL,
	[PresentingSymptoms] [varchar](MAX) NULL,
	[History] [varchar](MAX) NULL,
	[PhysicalExamination] [varchar](MAX) NULL,
	[Diagnosis] [varchar](MAX) NOT NULL,
	[DiagnosisCodes] [varchar](MAX) NULL,
	[TreatmentPlan] [varchar](MAX) NOT NULL,
	[Medications] [varchar](MAX) NULL,
	[Procedures] [varchar](MAX) NULL,
	[FollowUpDate] [datetime] NULL,
	[ReferralNeeded] [bit] NOT NULL DEFAULT 0,
	[ReferralReason] [varchar](MAX) NULL,
	[Restrictions] [varchar](MAX) NULL,
	[Notes] [varchar](MAX) NULL,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[ConsultationNoteId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Profile].[ConsultationNotes]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[ConsultationNotes]')
      AND c.name = N'ConsultationNoteId'
)
BEGIN
ALTER TABLE [Profile].[ConsultationNotes] ADD DEFAULT (newid()) FOR [ConsultationNoteId]
END
GO

-- Profile.Gender
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Profile].[Gender]', N'U') IS NULL
BEGIN
CREATE TABLE [Profile].[Gender](
	[GenderId] [int] IDENTITY(1,1) NOT NULL,
	[GenderDescription] [varchar](250) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[UpdateDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[GenderId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

-- Profile.HealthcareProviders
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Profile].[HealthcareProviders]', N'U') IS NULL
BEGIN
CREATE TABLE [Profile].[HealthcareProviders](
	[ProviderId] [uniqueidentifier] NOT NULL,
	[FirstName] [varchar](250) NOT NULL,
	[LastName] [varchar](250) NOT NULL,
	[Title] [varchar](50) NULL,
	[Specialization] [varchar](250) NOT NULL,
	[LicenseNumber] [varchar](100) NOT NULL UNIQUE,
	[RegistrationBody] [varchar](250) NOT NULL,
	[ProviderType] [varchar](50) NOT NULL,
	[Qualifications] [varchar](MAX) NULL,
	[YearsOfExperience] [int] NULL,
	[OfficeAddressIdFK] [uniqueidentifier] NULL,
	[IsActive] [bit] NOT NULL DEFAULT 1,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[ProviderId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Profile].[HealthcareProviders]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[HealthcareProviders]')
      AND c.name = N'ProviderId'
)
BEGIN
ALTER TABLE [Profile].[HealthcareProviders] ADD DEFAULT (newid()) FOR [ProviderId]
END
GO

-- Profile.InsuranceProviders
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Profile].[InsuranceProviders]', N'U') IS NULL
BEGIN
CREATE TABLE [Profile].[InsuranceProviders](
	[InsuranceProviderId] [uniqueidentifier] NOT NULL,
	[ProviderName] [varchar](250) NOT NULL UNIQUE,
	[RegistrationNumber] [varchar](100) NOT NULL UNIQUE,
	[ContactPerson] [varchar](250) NULL,
	[AddressIdFK] [uniqueidentifier] NULL,
	[PhoneNumber] [varchar](15) NOT NULL,
	[Email] [varchar](250) NULL,
	[WebsiteUrl] [varchar](500) NULL,
	[BillingCode] [varchar](50) NULL,
	[IsActive] [bit] NOT NULL DEFAULT 1,
	[Notes] [varchar](MAX) NULL,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[InsuranceProviderId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Profile].[InsuranceProviders]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[InsuranceProviders]')
      AND c.name = N'InsuranceProviderId'
)
BEGIN
ALTER TABLE [Profile].[InsuranceProviders] ADD DEFAULT (newid()) FOR [InsuranceProviderId]
END
GO

-- Profile.Invoices
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Profile].[Invoices]', N'U') IS NULL
BEGIN
CREATE TABLE [Profile].[Invoices](
	[InvoiceId] [uniqueidentifier] NOT NULL,
	[PatientIdFK] [uniqueidentifier] NOT NULL,
	[InvoiceNumber] [varchar](100) NOT NULL UNIQUE,
	[InvoiceDate] [datetime] NOT NULL,
	[DueDate] [datetime] NOT NULL,
	[ServiceDate] [datetime] NOT NULL,
	[ProviderIdFK] [uniqueidentifier] NOT NULL,
	[BillingCodeIdFK] [uniqueidentifier] NOT NULL,
	[Description] [varchar](MAX) NOT NULL,
	[Quantity] [int] NOT NULL DEFAULT 1,
	[UnitPrice] [decimal](10,2) NOT NULL,
	[TotalAmount] [decimal](10,2) NOT NULL,
	[InsuranceCoverage] [decimal](10,2) NULL,
	[PatientResponsibility] [decimal](10,2) NOT NULL,
	[Discount] [decimal](10,2) NULL DEFAULT 0,
	[Status] [varchar](50) NOT NULL DEFAULT 'Draft',
	[PaymentMethod] [varchar](50) NULL,
	[PaymentDate] [datetime] NULL,
	[Notes] [varchar](MAX) NULL,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[InvoiceId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Profile].[Invoices]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[Invoices]')
      AND c.name = N'InvoiceId'
)
BEGIN
ALTER TABLE [Profile].[Invoices] ADD DEFAULT (newid()) FOR [InvoiceId]
END
GO

-- Profile.LabResults
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Profile].[LabResults]', N'U') IS NULL
BEGIN
CREATE TABLE [Profile].[LabResults](
	[LabResultId] [uniqueidentifier] NOT NULL,
	[PatientIdFK] [uniqueidentifier] NOT NULL,
	[TestName] [varchar](250) NOT NULL,
	[TestCode] [varchar](50) NULL,
	[SpecimenType] [varchar](100) NULL,
	[CollectionDate] [datetime] NOT NULL,
	[ResultDate] [datetime] NOT NULL,
	[ResultValue] [varchar](250) NOT NULL,
	[Unit] [varchar](50) NULL,
	[ReferenceRange] [varchar](250) NULL,
	[Status] [varchar](50) NOT NULL DEFAULT 'Normal',
	[OrderedBy] [varchar](250) NOT NULL,
	[Lab] [varchar](250) NULL,
	[Interpretation] [varchar](MAX) NULL,
	[Notes] [varchar](MAX) NULL,
	[FileAttachmentId] [uniqueidentifier] NULL,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[LabResultId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Profile].[LabResults]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[LabResults]')
      AND c.name = N'LabResultId'
)
BEGIN
ALTER TABLE [Profile].[LabResults] ADD DEFAULT (newid()) FOR [LabResultId]
END
GO

-- Profile.MaritalStatus
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Profile].[MaritalStatus]', N'U') IS NULL
BEGIN
CREATE TABLE [Profile].[MaritalStatus](
	[MaritalStatusId] [int] IDENTITY(1,1) NOT NULL,
	[MaritalStatusDescription] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[UpdateDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[MaritalStatusId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

-- Profile.MedicalHistory
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Profile].[MedicalHistory]', N'U') IS NULL
BEGIN
CREATE TABLE [Profile].[MedicalHistory](
	[MedicalHistoryId] [uniqueidentifier] NOT NULL,
	[PatientIdFK] [uniqueidentifier] NOT NULL,
	[Condition] [varchar](250) NOT NULL,
	[DiagnosisDate] [datetime] NOT NULL,
	[DiagnosingDoctor] [varchar](250) NULL,
	[Status] [varchar](50) NOT NULL DEFAULT 'Active',
	[Description] [varchar](MAX) NULL,
	[ICD10Code] [varchar](10) NULL,
	[IsActive] [bit] NOT NULL DEFAULT 1,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[MedicalHistoryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Profile].[MedicalHistory]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[MedicalHistory]')
      AND c.name = N'MedicalHistoryId'
)
BEGIN
ALTER TABLE [Profile].[MedicalHistory] ADD DEFAULT (newid()) FOR [MedicalHistoryId]
END
GO

-- Profile.Medications
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Profile].[Medications]', N'U') IS NULL
BEGIN
CREATE TABLE [Profile].[Medications](
	[MedicationId] [uniqueidentifier] NOT NULL,
	[PatientIdFK] [uniqueidentifier] NOT NULL,
	[MedicationName] [varchar](250) NOT NULL,
	[Dosage] [varchar](100) NOT NULL,
	[Frequency] [varchar](100) NOT NULL,
	[Route] [varchar](50) NOT NULL DEFAULT 'Oral',
	[Indication] [varchar](250) NULL,
	[PrescribedBy] [varchar](250) NULL,
	[PrescriptionDate] [datetime] NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[Status] [varchar](50) NOT NULL DEFAULT 'Active',
	[SideEffects] [varchar](MAX) NULL,
	[Notes] [varchar](MAX) NULL,
	[IsActive] [bit] NOT NULL DEFAULT 1,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[MedicationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Profile].[Medications]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[Medications]')
      AND c.name = N'MedicationId'
)
BEGIN
ALTER TABLE [Profile].[Medications] ADD DEFAULT (newid()) FOR [MedicationId]
END
GO

-- Profile.PatientInsurance
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Profile].[PatientInsurance]', N'U') IS NULL
BEGIN
CREATE TABLE [Profile].[PatientInsurance](
	[PatientInsuranceId] [uniqueidentifier] NOT NULL,
	[PatientIdFK] [uniqueidentifier] NOT NULL,
	[InsuranceProviderIdFK] [uniqueidentifier] NOT NULL,
	[PolicyNumber] [varchar](100) NOT NULL,
	[GroupNumber] [varchar](100) NULL,
	[MemberId] [varchar](100) NOT NULL UNIQUE,
	[EmployerName] [varchar](250) NULL,
	[CoveragePlan] [varchar](250) NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[ExpiryDate] [datetime] NOT NULL,
	[CoverageType] [varchar](50) NOT NULL,
	[Deductible] [decimal](10,2) NULL,
	[CopayAmount] [decimal](10,2) NULL,
	[OutOfPocketMax] [decimal](10,2) NULL,
	[IsPrimary] [bit] NOT NULL DEFAULT 1,
	[Status] [varchar](50) NOT NULL DEFAULT 'Active',
	[Notes] [varchar](MAX) NULL,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[PatientInsuranceId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Profile].[PatientInsurance]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[PatientInsurance]')
      AND c.name = N'PatientInsuranceId'
)
BEGIN
ALTER TABLE [Profile].[PatientInsurance] ADD DEFAULT (newid()) FOR [PatientInsuranceId]
END
GO

-- Profile.Patient
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Profile].[Patient]', N'U') IS NULL
BEGIN
CREATE TABLE [Profile].[Patient](
	[PatientId] [uniqueidentifier] NOT NULL,
	[FirstName] [varchar](250) NOT NULL,
	[LastName] [varchar](250) NOT NULL,
	[ID_Number] [varchar](250) NOT NULL UNIQUE,
	[DateOfBirth] [datetime] NOT NULL,
	[GenderIDFK] [int] NOT NULL,
	[MedicationList] [varchar](MAX) NULL,
	[AddressIDFK] [uniqueidentifier] NULL,
	[MaritalStatusIDFK] [int] NOT NULL,
	[EmergencyIDFK] [uniqueidentifier] NULL,
	[IsDeleted] [BIT] NOT NULL DEFAULT 0,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[PatientId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[Patient]')
      AND c.name = N'PatientId'
)
BEGIN
ALTER TABLE [Profile].[Patient] ADD  DEFAULT (newid()) FOR [PatientId]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Patient]') AND name = 'IX_Patient_IDNumber')
BEGIN
CREATE INDEX IX_Patient_IDNumber ON [Profile].[Patient]([ID_Number])
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Patient]') AND name = 'IX_Patient_LastName')
BEGIN
CREATE INDEX IX_Patient_LastName ON [Profile].[Patient]([LastName])
END
GO

-- Profile.Clients
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Profile].[ClientClinicCategories]', N'U') IS NULL
BEGIN
    CREATE TABLE [Profile].[ClientClinicCategories](
    	[ClientClinicCategoryId] [int] IDENTITY(1,1) NOT NULL,
    	[CategoryName] [varchar](100) NOT NULL UNIQUE,
    	[ClinicSize] [varchar](20) NOT NULL,
    	[OwnershipType] [varchar](20) NOT NULL,
    	[IsActive] [bit] NOT NULL DEFAULT 1,
    	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
    	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY CLUSTERED
    (
    	[ClientClinicCategoryId] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
    ) ON [PRIMARY]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ClientClinicCategories_ClinicSize')
BEGIN
ALTER TABLE [Profile].[ClientClinicCategories] WITH CHECK
ADD CONSTRAINT CK_ClientClinicCategories_ClinicSize
CHECK ([ClinicSize] IN ('Small', 'Medium'))
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ClientClinicCategories_OwnershipType')
BEGIN
ALTER TABLE [Profile].[ClientClinicCategories] WITH CHECK
ADD CONSTRAINT CK_ClientClinicCategories_OwnershipType
CHECK ([OwnershipType] IN ('Private', 'Public'))
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientClinicCategories]') AND name = 'IX_ClientClinicCategories_IsActive')
BEGIN
CREATE INDEX IX_ClientClinicCategories_IsActive ON [Profile].[ClientClinicCategories]([IsActive])
END
GO

IF OBJECT_ID(N'[Profile].[Clients]', N'U') IS NULL
BEGIN
    CREATE TABLE [Profile].[Clients](
    	[ClientId] [uniqueidentifier] NOT NULL,
    	[PatientIdFK] [uniqueidentifier] NULL,
    	[ClientClinicCategoryIDFK] [int] NULL,
    	[ClientCode] [varchar](50) NOT NULL UNIQUE,
    	[FirstName] [varchar](250) NOT NULL,
    	[LastName] [varchar](250) NOT NULL,
    	[DateOfBirth] [datetime] NULL,
    	[ID_Number] [varchar](250) NULL,
    	[Email] [varchar](250) NULL,
    	[PhoneNumber] [varchar](25) NULL,
    	[AddressIDFK] [uniqueidentifier] NULL,
    	[IsActive] [bit] NOT NULL DEFAULT 1,
    	[IsDeleted] [bit] NOT NULL DEFAULT 0,
    	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
    	[CreatedBy] [varchar](250) NULL,
    	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
    	[UpdatedBy] [varchar](250) NULL,
    PRIMARY KEY CLUSTERED
    (
    	[ClientId] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
    ) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Profile].[Clients]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[Clients]')
      AND c.name = N'ClientId'
)
BEGIN
ALTER TABLE [Profile].[Clients] ADD DEFAULT (newid()) FOR [ClientId]
END
GO
IF OBJECT_ID(N'[Profile].[Clients]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[Clients]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Clients]'), N'PatientIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[Patient]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Patient]'), N'PatientId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[Clients] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
REFERENCES [Profile].[Patient] ([PatientId])
END
GO
IF OBJECT_ID(N'[Profile].[Clients]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[ClientClinicCategories]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[Clients]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Clients]'), N'ClientClinicCategoryIDFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[ClientClinicCategories]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[ClientClinicCategories]'), N'ClientClinicCategoryId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[Clients] WITH CHECK ADD FOREIGN KEY([ClientClinicCategoryIDFK])
REFERENCES [Profile].[ClientClinicCategories] ([ClientClinicCategoryId])
END
GO
IF OBJECT_ID(N'[Profile].[Clients]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Location].[Address]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[Clients]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Clients]'), N'AddressIDFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Location].[Address]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Location].[Address]'), N'AddressId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[Clients] WITH CHECK ADD FOREIGN KEY([AddressIDFK])
REFERENCES [Location].[Address] ([AddressId])
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Clients]') AND name = 'UX_Clients_PatientIdFK')
BEGIN
CREATE UNIQUE INDEX UX_Clients_PatientIdFK ON [Profile].[Clients]([PatientIdFK]) WHERE [PatientIdFK] IS NOT NULL
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Clients]') AND name = 'IX_Clients_ClientCode')
BEGIN
CREATE INDEX IX_Clients_ClientCode ON [Profile].[Clients]([ClientCode])
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Clients]') AND name = 'IX_Clients_ClientClinicCategoryIDFK')
BEGIN
CREATE INDEX IX_Clients_ClientClinicCategoryIDFK ON [Profile].[Clients]([ClientClinicCategoryIDFK])
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Clients]') AND name = 'IX_Clients_LastName')
BEGIN
CREATE INDEX IX_Clients_LastName ON [Profile].[Clients]([LastName])
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Clients]') AND name = 'IX_Clients_IsDeleted')
BEGIN
CREATE INDEX IX_Clients_IsDeleted ON [Profile].[Clients]([IsDeleted])
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Clients]') AND name = 'IX_Clients_IsActive')
BEGIN
CREATE INDEX IX_Clients_IsActive ON [Profile].[Clients]([IsActive])
END
GO

-- Profile.ClientStaff
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NULL
BEGIN
    CREATE TABLE [Profile].[ClientStaff](
        [ClientStaffId] [uniqueidentifier] NOT NULL,
        [ClientIdFK] [uniqueidentifier] NOT NULL,
        [RoleIdFK] [uniqueidentifier] NULL,
        [UserIdFK] [uniqueidentifier] NULL,
        [ProviderIdFK] [uniqueidentifier] NULL,
        [StaffCode] [varchar](50) NOT NULL UNIQUE,
        [FirstName] [varchar](250) NOT NULL,
        [LastName] [varchar](250) NOT NULL,
        [Email] [varchar](250) NULL,
        [PhoneNumber] [varchar](25) NULL,
        [JobTitle] [varchar](150) NULL,
        [Department] [varchar](100) NULL,
        [StaffType] [varchar](50) NOT NULL DEFAULT 'Administrative',
        [EmploymentType] [varchar](50) NOT NULL DEFAULT 'Full-Time',
        [HireDate] [datetime] NULL,
        [TerminationDate] [datetime] NULL,
        [IsPrimaryContact] [bit] NOT NULL DEFAULT 0,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        [IsDeleted] [bit] NOT NULL DEFAULT 0,
        [CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
        [CreatedBy] [varchar](250) NULL,
        [UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
        [UpdatedBy] [varchar](250) NULL,
    PRIMARY KEY CLUSTERED
    (
        [ClientStaffId] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
    ) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[ClientStaff]')
      AND c.name = N'ClientStaffId'
)
BEGIN
ALTER TABLE [Profile].[ClientStaff] ADD DEFAULT (newid()) FOR [ClientStaffId]
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ClientStaff_StaffType')
BEGIN
ALTER TABLE [Profile].[ClientStaff] WITH CHECK
ADD CONSTRAINT CK_ClientStaff_StaffType
CHECK ([StaffType] IN ('Clinical', 'Administrative', 'Support', 'Management'))
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ClientStaff_EmploymentType')
BEGIN
ALTER TABLE [Profile].[ClientStaff] WITH CHECK
ADD CONSTRAINT CK_ClientStaff_EmploymentType
CHECK ([EmploymentType] IN ('Full-Time', 'Part-Time', 'Contract', 'Locum'))
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ClientStaff_TerminationDate')
BEGIN
ALTER TABLE [Profile].[ClientStaff] WITH CHECK
ADD CONSTRAINT CK_ClientStaff_TerminationDate
CHECK ([TerminationDate] IS NULL OR [HireDate] IS NULL OR [TerminationDate] >= [HireDate])
END
GO
IF OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[Clients]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[ClientStaff]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[ClientStaff]'), N'ClientIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[Clients]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Clients]'), N'ClientId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[ClientStaff] WITH CHECK ADD FOREIGN KEY([ClientIdFK])
REFERENCES [Profile].[Clients] ([ClientId])
END
GO
IF OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Auth].[Roles]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[ClientStaff]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[ClientStaff]'), N'RoleIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Auth].[Roles]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Auth].[Roles]'), N'RoleId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[ClientStaff] WITH CHECK ADD FOREIGN KEY([RoleIdFK])
REFERENCES [Auth].[Roles] ([RoleId])
END
GO
IF OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Auth].[Users]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[ClientStaff]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[ClientStaff]'), N'UserIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Auth].[Users]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Auth].[Users]'), N'UserId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[ClientStaff] WITH CHECK ADD FOREIGN KEY([UserIdFK])
REFERENCES [Auth].[Users] ([UserId])
END
GO
IF OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[HealthcareProviders]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[ClientStaff]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[ClientStaff]'), N'ProviderIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[HealthcareProviders]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[HealthcareProviders]'), N'ProviderId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[ClientStaff] WITH CHECK ADD FOREIGN KEY([ProviderIdFK])
REFERENCES [Profile].[HealthcareProviders] ([ProviderId])
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientStaff]') AND name = 'UX_ClientStaff_Client_Email')
BEGIN
CREATE UNIQUE INDEX UX_ClientStaff_Client_Email
ON [Profile].[ClientStaff]([ClientIdFK], [Email])
WHERE [Email] IS NOT NULL AND [IsDeleted] = 0
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientStaff]') AND name = 'IX_ClientStaff_ClientIdFK')
BEGIN
CREATE INDEX IX_ClientStaff_ClientIdFK ON [Profile].[ClientStaff]([ClientIdFK])
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientStaff]') AND name = 'IX_ClientStaff_RoleIdFK')
BEGIN
CREATE INDEX IX_ClientStaff_RoleIdFK ON [Profile].[ClientStaff]([RoleIdFK])
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientStaff]') AND name = 'IX_ClientStaff_IsActive')
BEGIN
CREATE INDEX IX_ClientStaff_IsActive ON [Profile].[ClientStaff]([IsActive])
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientStaff]') AND name = 'IX_ClientStaff_IsDeleted')
BEGIN
CREATE INDEX IX_ClientStaff_IsDeleted ON [Profile].[ClientStaff]([IsDeleted])
END
GO

-- Profile.Referrals
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Profile].[Referrals]', N'U') IS NULL
BEGIN
CREATE TABLE [Profile].[Referrals](
	[ReferralId] [uniqueidentifier] NOT NULL,
	[PatientIdFK] [uniqueidentifier] NOT NULL,
	[ReferringProviderIdFK] [uniqueidentifier] NOT NULL,
	[ReferredProviderIdFK] [uniqueidentifier] NULL,
	[ReferralDate] [datetime] NOT NULL,
	[Reason] [varchar](MAX) NOT NULL,
	[Priority] [varchar](50) NOT NULL DEFAULT 'Normal',
	[ReferralType] [varchar](100) NOT NULL,
	[SpecializationNeeded] [varchar](250) NOT NULL,
	[ReferralCode] [varchar](50) NULL,
	[Status] [varchar](50) NOT NULL DEFAULT 'Pending',
	[AcceptanceDate] [datetime] NULL,
	[CompletionDate] [datetime] NULL,
	[Notes] [varchar](MAX) NULL,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[ReferralId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Profile].[Referrals]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[Referrals]')
      AND c.name = N'ReferralId'
)
BEGIN
ALTER TABLE [Profile].[Referrals] ADD DEFAULT (newid()) FOR [ReferralId]
END
GO

-- Profile.Vaccinations
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Profile].[Vaccinations]', N'U') IS NULL
BEGIN
CREATE TABLE [Profile].[Vaccinations](
	[VaccinationId] [uniqueidentifier] NOT NULL,
	[PatientIdFK] [uniqueidentifier] NOT NULL,
	[VaccineName] [varchar](250) NOT NULL,
	[VaccineCode] [varchar](50) NULL,
	[AdministrationDate] [datetime] NOT NULL,
	[DueDate] [datetime] NULL,
	[AdministeredBy] [varchar](250) NOT NULL,
	[Lot] [varchar](100) NULL,
	[Site] [varchar](100) NOT NULL DEFAULT 'Left Arm',
	[Route] [varchar](50) NOT NULL DEFAULT 'Intramuscular',
	[Reaction] [varchar](MAX) NULL,
	[Status] [varchar](50) NOT NULL DEFAULT 'Completed',
	[Notes] [varchar](MAX) NULL,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[VaccinationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF OBJECT_ID(N'[Profile].[Vaccinations]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[Vaccinations]')
      AND c.name = N'VaccinationId'
)
BEGIN
ALTER TABLE [Profile].[Vaccinations] ADD DEFAULT (newid()) FOR [VaccinationId]
END
GO

-- Auth.DB_Errors (legacy)
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Auth].[DB_Errors]', N'U') IS NULL
BEGIN
CREATE TABLE [Auth].[DB_Errors](
	[ErrorID] [int] IDENTITY(1,1) NOT NULL,
	[UserName] [varchar](100) NULL,
	[ErrorSchema] [varchar](100) NULL,
	[ErrorProcedure] [varchar](max) NULL,
	[ErrorNumber] [int] NULL,
	[ErrorState] [int] NULL,
	[ErrorSeverity] [int] NULL,
	[ErrorLine] [int] NULL,
	[ErrorMessage] [varchar](max) NULL,
	[ErrorDateTime] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO

-- =================================================================================================
-- 5) Add foreign key constraints that reference tables created later (safe-guarded)
-- Note: many scripts already had FK creation lines; depending on creation order some were omitted earlier
-- We'll add known FKs with IF EXISTS guards to avoid failures if they already exist.
-- =================================================================================================

-- Example: Add FK [Location].[Provinces].CountryIDFK -> [Location].[Countries].CountryId
IF OBJECT_ID('FK_Provinces_Country', 'F') IS NULL
BEGIN
    ALTER TABLE [Location].[Provinces] WITH CHECK ADD FOREIGN KEY([CountryIDFK])
    REFERENCES [Location].[Countries] ([CountryId])
END
GO

-- More FK additions can be scripted here as needed. Many FK constraints were defined inline above; if any failed due to ordering, add them here.

-- =================================================================================================
-- 6) Stored Procedures, Triggers, Functions (inlined from 006 and 007 folders)
-- Include core data-quality and audit functions/triggers.
-- =================================================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Exceptions].[spErrorHandling]
(
    @UserName VARCHAR(200),
    @ErrorSchema VARCHAR(200),
    @ErrorProc VARCHAR(200),
    @ErrorNumber INT,
    @ErrorState INT,
    @ErrorSeverity INT,
    @ErrorLine INT,
    @ErrorMessage VARCHAR(MAX),
    @ErrorDateTime DATETIME
)
AS
BEGIN
    INSERT INTO Exceptions.Errors
    (
        UserName,
        ErrorSchema,
        ErrorProcedure,
        ErrorNumber,
        ErrorState,
        ErrorSeverity,
        ErrorLine,
        ErrorMessage,
        ErrorDateTime
    )
    VALUES
    (
        @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber, @ErrorState,
        @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
    );
END
GO

CREATE OR ALTER PROC [Profile].[spListPatients]
(
    @SearchTerm VARCHAR(250) = '',
    @GenderIDFK INT = 0,
    @MaritalStatusIDFK INT = 0,
    @CityIDFK INT = 0,
    @IsDeleted BIT = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 25,
    @TotalRecords INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Offset INT,
            @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME;

    SET NOCOUNT ON;

    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize < 1 SET @PageSize = 25;
    IF @PageSize > 200 SET @PageSize = 200;

    SET @Offset = (@PageNumber - 1) * @PageSize;
    SET @TotalRecords = 0;
    SET @Message = '';

    BEGIN TRY
        ;WITH PatientBase AS
        (
            SELECT
                P.PatientId,
                P.FirstName,
                P.LastName,
                P.ID_Number,
                P.DateOfBirth,
                P.GenderIDFK,
                P.MaritalStatusIDFK,
                P.MedicationList,
                P.IsDeleted,
                P.CreatedDate,
                P.UpdatedDate,
                CE.Email,
                CP.PhoneNumber,
                LA.Line1,
                LA.Line2,
                LC.CityId,
                LC.CityName,
                LP.ProvinceId,
                LP.ProvinceName,
                LCO.CountryId,
                LCO.CountryName
            FROM Profile.Patient P
            LEFT JOIN Location.Address LA ON LA.AddressId = P.AddressIDFK
            LEFT JOIN Location.Cities LC ON LC.CityId = LA.CityIDFK
            LEFT JOIN Location.Provinces LP ON LP.ProvinceId = LC.ProvinceIDFK
            LEFT JOIN Location.Countries LCO ON LCO.CountryId = LP.CountryIDFK
            OUTER APPLY
            (
                SELECT TOP (1) PE.EmailIdFK
                FROM Contacts.PatientEmails PE
                WHERE PE.PatientIdFK = P.PatientId
                ORDER BY PE.IsPrimary DESC, PE.CreatedDate DESC
            ) PE1
            LEFT JOIN Contacts.Emails CE ON CE.EmailId = PE1.EmailIdFK
            OUTER APPLY
            (
                SELECT TOP (1) PP.PhoneIdFK
                FROM Contacts.PatientPhones PP
                WHERE PP.PatientIdFK = P.PatientId
                ORDER BY PP.IsPrimary DESC, PP.CreatedDate DESC
            ) PP1
            LEFT JOIN Contacts.Phones CP ON CP.PhoneId = PP1.PhoneIdFK
            WHERE
                (
                    @SearchTerm = ''
                    OR P.FirstName LIKE '%' + @SearchTerm + '%'
                    OR P.LastName LIKE '%' + @SearchTerm + '%'
                    OR P.ID_Number LIKE '%' + @SearchTerm + '%'
                    OR ISNULL(CE.Email, '') LIKE '%' + @SearchTerm + '%'
                    OR ISNULL(CP.PhoneNumber, '') LIKE '%' + @SearchTerm + '%'
                )
                AND (@GenderIDFK = 0 OR P.GenderIDFK = @GenderIDFK)
                AND (@MaritalStatusIDFK = 0 OR P.MaritalStatusIDFK = @MaritalStatusIDFK)
                AND (@CityIDFK = 0 OR LC.CityId = @CityIDFK)
                AND (@IsDeleted IS NULL OR P.IsDeleted = @IsDeleted)
        ),
        Numbered AS
        (
            SELECT
                PB.*,
                COUNT(1) OVER () AS TotalRows,
                ROW_NUMBER() OVER (ORDER BY PB.LastName ASC, PB.FirstName ASC, PB.PatientId ASC) AS RowNum
            FROM PatientBase PB
        )
        SELECT
            PatientId,
            FirstName,
            LastName,
            ID_Number,
            DateOfBirth,
            GenderIDFK,
            MaritalStatusIDFK,
            MedicationList,
            IsDeleted,
            Email,
            PhoneNumber,
            Line1,
            Line2,
            CityId,
            CityName,
            ProvinceId,
            ProvinceName,
            CountryId,
            CountryName,
            CreatedDate,
            UpdatedDate
        FROM Numbered
        WHERE RowNum > @Offset
          AND RowNum <= (@Offset + @PageSize)
        ORDER BY RowNum;

        SELECT @TotalRecords = ISNULL(MAX(TotalRows), 0)
        FROM Numbered;

        SET @Message = '';
    END TRY
    BEGIN CATCH
        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName,
                        ErrorSchema,
                        ErrorProcedure,
                        ErrorNumber,
                        ErrorState,
                        ErrorSeverity,
                        ErrorLine,
                        ErrorMessage,
                        ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName,
                        @ErrorSchema,
                        @ErrorProc,
                        @ErrorNumber,
                        @ErrorState,
                        @ErrorSeverity,
                        @ErrorLine,
                        LEFT(@ErrorMessage, 500),
                        @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName,
                ErrorSchema,
                ErrorProcedure,
                ErrorNumber,
                ErrorState,
                ErrorSeverity,
                ErrorLine,
                ErrorMessage,
                ErrorDateTime
            )
            VALUES
            (
                @UserName,
                @ErrorSchema,
                @ErrorProc,
                @ErrorNumber,
                @ErrorState,
                @ErrorSeverity,
                @ErrorLine,
                LEFT(@ErrorMessage, 500),
                @ErrorDateTime
            );
        END

        SET @TotalRecords = 0;
        SET @Message = 'Failed to retrieve patient list.';
    END CATCH

    SET NOCOUNT OFF;
END
GO

CREATE OR ALTER PROC [Profile].[spRestorePatient]
(
    @IDNumber VARCHAR(250) = '',
    @Message VARCHAR(250) OUTPUT,
    @StatusCode INT OUTPUT
)
AS
BEGIN
    DECLARE @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME;

    SET NOCOUNT ON;

    SET @StatusCode = -1;
    SET @Message = '';

    BEGIN TRY
        IF LTRIM(RTRIM(@IDNumber)) = ''
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'ID number is required.';
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM Profile.Patient WHERE ID_Number = @IDNumber AND IsDeleted = 0)
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'Patient is already active.';
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM Profile.Patient WHERE ID_Number = @IDNumber AND IsDeleted = 1)
        BEGIN
            UPDATE Profile.Patient
            SET IsDeleted = 0,
                UpdatedDate = GETDATE(),
                UpdatedBy = SUSER_SNAME()
            WHERE ID_Number = @IDNumber
              AND IsDeleted = 1;

            SET @StatusCode = 0;
            SET @Message = '';
            RETURN;
        END

        SET @StatusCode = 1;
        SET @Message = 'Patient does not exist.';
    END TRY
    BEGIN CATCH
        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName,
                        ErrorSchema,
                        ErrorProcedure,
                        ErrorNumber,
                        ErrorState,
                        ErrorSeverity,
                        ErrorLine,
                        ErrorMessage,
                        ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName,
                        @ErrorSchema,
                        @ErrorProc,
                        @ErrorNumber,
                        @ErrorState,
                        @ErrorSeverity,
                        @ErrorLine,
                        LEFT(@ErrorMessage, 500),
                        @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName,
                ErrorSchema,
                ErrorProcedure,
                ErrorNumber,
                ErrorState,
                ErrorSeverity,
                ErrorLine,
                ErrorMessage,
                ErrorDateTime
            )
            VALUES
            (
                @UserName,
                @ErrorSchema,
                @ErrorProc,
                @ErrorNumber,
                @ErrorState,
                @ErrorSeverity,
                @ErrorLine,
                LEFT(@ErrorMessage, 500),
                @ErrorDateTime
            );
        END

        SET @StatusCode = -1;
        SET @Message = 'Failed to restore patient record.';
    END CATCH

    SET NOCOUNT OFF;
END
GO

USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spAddClient]
(
    @ClientCode VARCHAR(50),
    @FirstName VARCHAR(250),
    @LastName VARCHAR(250),
    @DateOfBirth DATETIME = NULL,
    @ID_Number VARCHAR(250) = NULL,
    @Email VARCHAR(250) = NULL,
    @PhoneNumber VARCHAR(25) = NULL,
    @AddressIDFK UNIQUEIDENTIFIER = NULL,
    @PatientIdFK UNIQUEIDENTIFIER = NULL,
    @ClientClinicCategoryIDFK INT = NULL,
    @CreatedBy VARCHAR(250) = NULL,
    @ClientIdOutput UNIQUEIDENTIFIER OUTPUT,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE(),
            @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME,
            @NormalizedPhone VARCHAR(25),
            @FormattedPhone VARCHAR(25);

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @ClientIdOutput = NULL;
    SET @StatusCode = -1;
    SET @Message = '';

    IF LTRIM(RTRIM(ISNULL(@ClientCode, ''))) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientCode is required.';
        RETURN;
    END

    IF LTRIM(RTRIM(ISNULL(@FirstName, ''))) = '' OR LTRIM(RTRIM(ISNULL(@LastName, ''))) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'FirstName and LastName are required.';
        RETURN;
    END

    IF @DateOfBirth IS NOT NULL AND @DateOfBirth > GETDATE()
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'DateOfBirth cannot be in the future.';
        RETURN;
    END

    IF NULLIF(LTRIM(RTRIM(ISNULL(@Email, ''))), '') IS NOT NULL
       AND @Email NOT LIKE '%_@_%._%'
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Invalid email format.';
        RETURN;
    END

    IF @AddressIDFK IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Location.Address WHERE AddressId = @AddressIDFK)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'AddressIDFK does not exist.';
        RETURN;
    END

    IF @PatientIdFK IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Profile.Patient WHERE PatientId = @PatientIdFK)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'PatientIdFK does not exist.';
        RETURN;
    END

    IF @ClientClinicCategoryIDFK IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM Profile.ClientClinicCategories CCC
           WHERE CCC.ClientClinicCategoryId = @ClientClinicCategoryIDFK
             AND CCC.IsActive = 1
       )
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientClinicCategoryIDFK does not exist or is inactive.';
        RETURN;
    END

    SET @NormalizedPhone = LTRIM(RTRIM(ISNULL(@PhoneNumber, '')));
    IF @NormalizedPhone <> ''
    BEGIN
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '-', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, ' ', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '+', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '(', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, ')', '');

        IF LEN(@NormalizedPhone) <> 10 OR @NormalizedPhone LIKE '%[^0-9]%'
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'PhoneNumber must contain exactly 10 digits.';
            RETURN;
        END

        SET @FormattedPhone = SUBSTRING(@NormalizedPhone, 1, 3) + '-' +
                              SUBSTRING(@NormalizedPhone, 4, 3) + '-' +
                              SUBSTRING(@NormalizedPhone, 7, 4);
    END
    ELSE
    BEGIN
        SET @FormattedPhone = NULL;
    END

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM Profile.Clients WHERE ClientCode = @ClientCode)
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'ClientCode already exists.';
            RETURN;
        END

        IF @PatientIdFK IS NOT NULL
           AND EXISTS (SELECT 1 FROM Profile.Clients WHERE PatientIdFK = @PatientIdFK)
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'A client is already linked to this PatientIdFK.';
            RETURN;
        END

        SET @ClientIdOutput = NEWID();

        INSERT INTO Profile.Clients
        (
            ClientId, PatientIdFK, ClientClinicCategoryIDFK, ClientCode, FirstName, LastName,
            DateOfBirth, ID_Number, Email, PhoneNumber, AddressIDFK,
            IsActive, IsDeleted, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy
        )
        VALUES
        (
            @ClientIdOutput, @PatientIdFK, @ClientClinicCategoryIDFK, @ClientCode, @FirstName, @LastName,
            @DateOfBirth, NULLIF(LTRIM(RTRIM(ISNULL(@ID_Number, ''))), ''),
            NULLIF(LTRIM(RTRIM(ISNULL(@Email, ''))), ''), @FormattedPhone, @AddressIDFK,
            1, 0, @Now, COALESCE(NULLIF(@CreatedBy, ''), SUSER_SNAME()), @Now, COALESCE(NULLIF(@CreatedBy, ''), SUSER_SNAME())
        );

        SET @StatusCode = 0;
        SET @Message = '';
    END TRY
    BEGIN CATCH
        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                        ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                        @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
            )
            VALUES
            (
                @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
            );
        END

        SET @ClientIdOutput = NULL;
        SET @StatusCode = -1;
        SET @Message = 'Failed to add client record.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spGetClient]
(
    @ClientId UNIQUEIDENTIFIER = NULL,
    @ClientCode VARCHAR(50) = '',
    @IncludeDeleted BIT = 0,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME;

    SET NOCOUNT ON;
    SET @Message = '';

    BEGIN TRY
        IF @ClientId IS NULL AND LTRIM(RTRIM(@ClientCode)) = ''
        BEGIN
            SET @Message = 'ClientId or ClientCode is required.';
            RETURN;
        END

        IF EXISTS
        (
            SELECT 1
            FROM Profile.Clients C
            WHERE
                ((@ClientId IS NOT NULL AND C.ClientId = @ClientId)
                 OR (@ClientId IS NULL AND C.ClientCode = @ClientCode))
                AND (@IncludeDeleted = 1 OR C.IsDeleted = 0)
        )
        BEGIN
            SELECT
                C.ClientId,
                C.PatientIdFK,
                C.ClientClinicCategoryIDFK,
                CCC.CategoryName AS ClientClinicCategoryName,
                CCC.ClinicSize,
                CCC.OwnershipType,
                C.ClientCode,
                C.FirstName,
                C.LastName,
                C.DateOfBirth,
                C.ID_Number,
                C.Email,
                C.PhoneNumber,
                C.AddressIDFK,
                LA.Line1,
                LA.Line2,
                LA.CityIDFK,
                C.IsActive,
                C.IsDeleted,
                C.CreatedDate,
                C.CreatedBy,
                C.UpdatedDate,
                C.UpdatedBy
            FROM Profile.Clients C
            LEFT JOIN Location.Address LA ON LA.AddressId = C.AddressIDFK
            LEFT JOIN Profile.ClientClinicCategories CCC ON CCC.ClientClinicCategoryId = C.ClientClinicCategoryIDFK
            WHERE
                ((@ClientId IS NOT NULL AND C.ClientId = @ClientId)
                 OR (@ClientId IS NULL AND C.ClientCode = @ClientCode))
                AND (@IncludeDeleted = 1 OR C.IsDeleted = 0);

            SET @Message = '';
        END
        ELSE
        BEGIN
            SET @Message = 'Client not found.';
        END
    END TRY
    BEGIN CATCH
        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                        ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                        @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
            )
            VALUES
            (
                @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
            );
        END

        SET @Message = 'Failed to retrieve client record.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spListClients]
(
    @SearchTerm VARCHAR(250) = '',
    @ClientClinicCategoryIDFK INT = 0,
    @ClinicSize VARCHAR(20) = '',
    @OwnershipType VARCHAR(20) = '',
    @IsActive BIT = NULL,
    @IsDeleted BIT = 0,
    @PageNumber INT = 1,
    @PageSize INT = 25,
    @TotalRecords INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Offset INT,
            @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME;

    SET NOCOUNT ON;

    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize < 1 SET @PageSize = 25;
    IF @PageSize > 200 SET @PageSize = 200;

    SET @Offset = (@PageNumber - 1) * @PageSize;
    SET @TotalRecords = 0;
    SET @Message = '';

    BEGIN TRY
        ;WITH Base AS
        (
            SELECT
                C.ClientId,
                C.PatientIdFK,
                C.ClientClinicCategoryIDFK,
                CCC.CategoryName AS ClientClinicCategoryName,
                CCC.ClinicSize,
                CCC.OwnershipType,
                C.ClientCode,
                C.FirstName,
                C.LastName,
                C.DateOfBirth,
                C.ID_Number,
                C.Email,
                C.PhoneNumber,
                C.AddressIDFK,
                C.IsActive,
                C.IsDeleted,
                C.CreatedDate,
                C.UpdatedDate,
                LA.Line1,
                LA.Line2,
                LA.CityIDFK
            FROM Profile.Clients C
            LEFT JOIN Location.Address LA ON LA.AddressId = C.AddressIDFK
            LEFT JOIN Profile.ClientClinicCategories CCC ON CCC.ClientClinicCategoryId = C.ClientClinicCategoryIDFK
            WHERE
                (
                    @SearchTerm = ''
                    OR C.ClientCode LIKE '%' + @SearchTerm + '%'
                    OR C.FirstName LIKE '%' + @SearchTerm + '%'
                    OR C.LastName LIKE '%' + @SearchTerm + '%'
                    OR ISNULL(C.ID_Number, '') LIKE '%' + @SearchTerm + '%'
                    OR ISNULL(C.Email, '') LIKE '%' + @SearchTerm + '%'
                    OR ISNULL(C.PhoneNumber, '') LIKE '%' + @SearchTerm + '%'
                )
                AND (@ClientClinicCategoryIDFK = 0 OR C.ClientClinicCategoryIDFK = @ClientClinicCategoryIDFK)
                AND (@ClinicSize = '' OR ISNULL(CCC.ClinicSize, '') = @ClinicSize)
                AND (@OwnershipType = '' OR ISNULL(CCC.OwnershipType, '') = @OwnershipType)
                AND (@IsActive IS NULL OR C.IsActive = @IsActive)
                AND (@IsDeleted IS NULL OR C.IsDeleted = @IsDeleted)
        ),
        Numbered AS
        (
            SELECT
                B.*,
                COUNT(1) OVER () AS TotalRows,
                ROW_NUMBER() OVER (ORDER BY B.LastName ASC, B.FirstName ASC, B.ClientId ASC) AS RowNum
            FROM Base B
        )
        SELECT
            ClientId,
            PatientIdFK,
            ClientClinicCategoryIDFK,
            ClientClinicCategoryName,
            ClinicSize,
            OwnershipType,
            ClientCode,
            FirstName,
            LastName,
            DateOfBirth,
            ID_Number,
            Email,
            PhoneNumber,
            AddressIDFK,
            Line1,
            Line2,
            CityIDFK,
            IsActive,
            IsDeleted,
            CreatedDate,
            UpdatedDate
        FROM Numbered
        WHERE RowNum > @Offset
          AND RowNum <= (@Offset + @PageSize)
        ORDER BY RowNum;

        SELECT @TotalRecords = ISNULL(MAX(TotalRows), 0)
        FROM Numbered;

        SET @Message = '';
    END TRY
    BEGIN CATCH
        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                        ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                        @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
            )
            VALUES
            (
                @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
            );
        END

        SET @TotalRecords = 0;
        SET @Message = 'Failed to retrieve clients list.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spUpdateClient]
(
    @ClientId UNIQUEIDENTIFIER,
    @ClientCode VARCHAR(50),
    @FirstName VARCHAR(250),
    @LastName VARCHAR(250),
    @DateOfBirth DATETIME = NULL,
    @ID_Number VARCHAR(250) = NULL,
    @Email VARCHAR(250) = NULL,
    @PhoneNumber VARCHAR(25) = NULL,
    @AddressIDFK UNIQUEIDENTIFIER = NULL,
    @PatientIdFK UNIQUEIDENTIFIER = NULL,
    @ClientClinicCategoryIDFK INT = NULL,
    @IsActive BIT = 1,
    @UpdatedBy VARCHAR(250) = NULL,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE(),
            @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME,
            @NormalizedPhone VARCHAR(25),
            @FormattedPhone VARCHAR(25);

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @StatusCode = -1;
    SET @Message = '';

    IF @ClientId IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientId is required.';
        RETURN;
    END

    IF LTRIM(RTRIM(ISNULL(@ClientCode, ''))) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientCode is required.';
        RETURN;
    END

    IF LTRIM(RTRIM(ISNULL(@FirstName, ''))) = '' OR LTRIM(RTRIM(ISNULL(@LastName, ''))) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'FirstName and LastName are required.';
        RETURN;
    END

    IF @DateOfBirth IS NOT NULL AND @DateOfBirth > GETDATE()
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'DateOfBirth cannot be in the future.';
        RETURN;
    END

    IF NULLIF(LTRIM(RTRIM(ISNULL(@Email, ''))), '') IS NOT NULL
       AND @Email NOT LIKE '%_@_%._%'
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Invalid email format.';
        RETURN;
    END

    IF @AddressIDFK IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Location.Address WHERE AddressId = @AddressIDFK)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'AddressIDFK does not exist.';
        RETURN;
    END

    IF @PatientIdFK IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Profile.Patient WHERE PatientId = @PatientIdFK)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'PatientIdFK does not exist.';
        RETURN;
    END

    IF @ClientClinicCategoryIDFK IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM Profile.ClientClinicCategories CCC
           WHERE CCC.ClientClinicCategoryId = @ClientClinicCategoryIDFK
             AND CCC.IsActive = 1
       )
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientClinicCategoryIDFK does not exist or is inactive.';
        RETURN;
    END

    SET @NormalizedPhone = LTRIM(RTRIM(ISNULL(@PhoneNumber, '')));
    IF @NormalizedPhone <> ''
    BEGIN
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '-', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, ' ', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '+', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '(', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, ')', '');

        IF LEN(@NormalizedPhone) <> 10 OR @NormalizedPhone LIKE '%[^0-9]%'
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'PhoneNumber must contain exactly 10 digits.';
            RETURN;
        END

        SET @FormattedPhone = SUBSTRING(@NormalizedPhone, 1, 3) + '-' +
                              SUBSTRING(@NormalizedPhone, 4, 3) + '-' +
                              SUBSTRING(@NormalizedPhone, 7, 4);
    END
    ELSE
    BEGIN
        SET @FormattedPhone = NULL;
    END

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Profile.Clients WHERE ClientId = @ClientId AND IsDeleted = 0)
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'Client not found or already deleted.';
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM Profile.Clients WHERE ClientCode = @ClientCode AND ClientId <> @ClientId)
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'ClientCode already exists.';
            RETURN;
        END

        IF @PatientIdFK IS NOT NULL
           AND EXISTS (SELECT 1 FROM Profile.Clients WHERE PatientIdFK = @PatientIdFK AND ClientId <> @ClientId)
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'A client is already linked to this PatientIdFK.';
            RETURN;
        END

        UPDATE Profile.Clients
        SET ClientCode = @ClientCode,
            FirstName = @FirstName,
            LastName = @LastName,
            DateOfBirth = @DateOfBirth,
            ID_Number = NULLIF(LTRIM(RTRIM(ISNULL(@ID_Number, ''))), ''),
            Email = NULLIF(LTRIM(RTRIM(ISNULL(@Email, ''))), ''),
            PhoneNumber = @FormattedPhone,
            AddressIDFK = @AddressIDFK,
            PatientIdFK = @PatientIdFK,
            ClientClinicCategoryIDFK = @ClientClinicCategoryIDFK,
            IsActive = @IsActive,
            UpdatedDate = @Now,
            UpdatedBy = COALESCE(NULLIF(@UpdatedBy, ''), SUSER_SNAME())
        WHERE ClientId = @ClientId
          AND IsDeleted = 0;

        SET @StatusCode = 0;
        SET @Message = '';
    END TRY
    BEGIN CATCH
        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                        ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                        @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
            )
            VALUES
            (
                @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
            );
        END

        SET @StatusCode = -1;
        SET @Message = 'Failed to update client record.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spDeleteClient]
(
    @ClientId UNIQUEIDENTIFIER = NULL,
    @ClientCode VARCHAR(50) = '',
    @UpdatedBy VARCHAR(250) = NULL,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE(),
            @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME;

    SET NOCOUNT ON;

    SET @StatusCode = -1;
    SET @Message = '';

    BEGIN TRY
        IF @ClientId IS NULL AND LTRIM(RTRIM(@ClientCode)) = ''
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'ClientId or ClientCode is required.';
            RETURN;
        END

        IF EXISTS
        (
            SELECT 1
            FROM Profile.Clients C
            WHERE
                ((@ClientId IS NOT NULL AND C.ClientId = @ClientId)
                 OR (@ClientId IS NULL AND C.ClientCode = @ClientCode))
                AND C.IsDeleted = 0
        )
        BEGIN
            UPDATE C
            SET IsDeleted = 1,
                IsActive = 0,
                UpdatedDate = @Now,
                UpdatedBy = COALESCE(NULLIF(@UpdatedBy, ''), SUSER_SNAME())
            FROM Profile.Clients C
            WHERE
                ((@ClientId IS NOT NULL AND C.ClientId = @ClientId)
                 OR (@ClientId IS NULL AND C.ClientCode = @ClientCode))
                AND C.IsDeleted = 0;

            SET @StatusCode = 0;
            SET @Message = '';
        END
        ELSE
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'Client does not exist or is already deleted.';
        END
    END TRY
    BEGIN CATCH
        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                        ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                        @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
            )
            VALUES
            (
                @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
            );
        END

        SET @StatusCode = -1;
        SET @Message = 'Failed to delete client record.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spGetClientClinicCategories]
(
    @ClientClinicCategoryId INT = 0,
    @IsActive BIT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CCC.ClientClinicCategoryId,
        CCC.CategoryName,
        CCC.ClinicSize,
        CCC.OwnershipType,
        CCC.IsActive,
        CCC.CreatedDate,
        CCC.UpdatedDate
    FROM Profile.ClientClinicCategories CCC
    WHERE (@ClientClinicCategoryId = 0 OR CCC.ClientClinicCategoryId = @ClientClinicCategoryId)
      AND (@IsActive IS NULL OR CCC.IsActive = @IsActive)
    ORDER BY CCC.CategoryName;

    SET NOCOUNT OFF;
END
GO
USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spAssignClientClinicCategory]
(
    @ClientId UNIQUEIDENTIFIER = NULL,
    @ClientCode VARCHAR(50) = '',
    @ClientClinicCategoryIDFK INT,
    @UpdatedBy VARCHAR(250) = NULL,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE(),
            @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME;

    SET NOCOUNT ON;

    SET @StatusCode = -1;
    SET @Message = '';

    BEGIN TRY
        IF @ClientId IS NULL AND LTRIM(RTRIM(@ClientCode)) = ''
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'ClientId or ClientCode is required.';
            RETURN;
        END

        IF @ClientClinicCategoryIDFK IS NULL
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'ClientClinicCategoryIDFK is required.';
            RETURN;
        END

        IF NOT EXISTS
        (
            SELECT 1
            FROM Profile.ClientClinicCategories CCC
            WHERE CCC.ClientClinicCategoryId = @ClientClinicCategoryIDFK
              AND CCC.IsActive = 1
        )
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'ClientClinicCategoryIDFK does not exist or is inactive.';
            RETURN;
        END

        IF EXISTS
        (
            SELECT 1
            FROM Profile.Clients C
            WHERE
                ((@ClientId IS NOT NULL AND C.ClientId = @ClientId)
                 OR (@ClientId IS NULL AND C.ClientCode = @ClientCode))
                AND C.IsDeleted = 0
        )
        BEGIN
            UPDATE C
            SET C.ClientClinicCategoryIDFK = @ClientClinicCategoryIDFK,
                C.UpdatedDate = @Now,
                C.UpdatedBy = COALESCE(NULLIF(@UpdatedBy, ''), SUSER_SNAME())
            FROM Profile.Clients C
            WHERE
                ((@ClientId IS NOT NULL AND C.ClientId = @ClientId)
                 OR (@ClientId IS NULL AND C.ClientCode = @ClientCode))
                AND C.IsDeleted = 0;

            SET @StatusCode = 0;
            SET @Message = '';
        END
        ELSE
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'Client does not exist or is deleted.';
        END
    END TRY
    BEGIN CATCH
        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                        ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                        @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
            )
            VALUES
            (
                @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
            );
        END

        SET @StatusCode = -1;
        SET @Message = 'Failed to assign clinic category to client.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spAddClientStaff]
(
    @ClientIdFK UNIQUEIDENTIFIER,
    @RoleIdFK UNIQUEIDENTIFIER = NULL,
    @UserIdFK UNIQUEIDENTIFIER = NULL,
    @ProviderIdFK UNIQUEIDENTIFIER = NULL,
    @StaffCode VARCHAR(50),
    @FirstName VARCHAR(250),
    @LastName VARCHAR(250),
    @Email VARCHAR(250) = NULL,
    @PhoneNumber VARCHAR(25) = NULL,
    @JobTitle VARCHAR(150) = NULL,
    @Department VARCHAR(100) = NULL,
    @StaffType VARCHAR(50) = 'Administrative',
    @EmploymentType VARCHAR(50) = 'Full-Time',
    @HireDate DATETIME = NULL,
    @IsPrimaryContact BIT = 0,
    @CreatedBy VARCHAR(250) = NULL,
    @ClientStaffIdOutput UNIQUEIDENTIFIER OUTPUT,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE(),
            @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME,
            @NormalizedPhone VARCHAR(25),
            @FormattedPhone VARCHAR(25);

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @ClientStaffIdOutput = NULL;
    SET @StatusCode = -1;
    SET @Message = '';

    IF @ClientIdFK IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientIdFK is required.';
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Profile.Clients WHERE ClientId = @ClientIdFK AND IsDeleted = 0)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Client does not exist or is deleted.';
        RETURN;
    END

    IF LTRIM(RTRIM(ISNULL(@StaffCode, ''))) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'StaffCode is required.';
        RETURN;
    END

    IF LTRIM(RTRIM(ISNULL(@FirstName, ''))) = '' OR LTRIM(RTRIM(ISNULL(@LastName, ''))) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'FirstName and LastName are required.';
        RETURN;
    END

    IF @RoleIdFK IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Auth.Roles WHERE RoleId = @RoleIdFK)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'RoleIdFK does not exist.';
        RETURN;
    END

    IF @UserIdFK IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Auth.Users WHERE UserId = @UserIdFK)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'UserIdFK does not exist.';
        RETURN;
    END

    IF @ProviderIdFK IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Profile.HealthcareProviders WHERE ProviderId = @ProviderIdFK)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ProviderIdFK does not exist.';
        RETURN;
    END

    IF NULLIF(LTRIM(RTRIM(ISNULL(@Email, ''))), '') IS NOT NULL
       AND @Email NOT LIKE '%_@_%._%'
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Invalid email format.';
        RETURN;
    END

    SET @NormalizedPhone = LTRIM(RTRIM(ISNULL(@PhoneNumber, '')));
    IF @NormalizedPhone <> ''
    BEGIN
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '-', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, ' ', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '+', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '(', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, ')', '');

        IF LEN(@NormalizedPhone) <> 10 OR @NormalizedPhone LIKE '%[^0-9]%'
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'PhoneNumber must contain exactly 10 digits.';
            RETURN;
        END

        SET @FormattedPhone = SUBSTRING(@NormalizedPhone, 1, 3) + '-' +
                              SUBSTRING(@NormalizedPhone, 4, 3) + '-' +
                              SUBSTRING(@NormalizedPhone, 7, 4);
    END
    ELSE
    BEGIN
        SET @FormattedPhone = NULL;
    END

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM Profile.ClientStaff WHERE StaffCode = @StaffCode)
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'StaffCode already exists.';
            RETURN;
        END

        IF NULLIF(LTRIM(RTRIM(ISNULL(@Email, ''))), '') IS NOT NULL
           AND EXISTS
           (
               SELECT 1
               FROM Profile.ClientStaff
               WHERE ClientIdFK = @ClientIdFK
                 AND Email = LTRIM(RTRIM(@Email))
                 AND IsDeleted = 0
           )
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'Email already exists for this client.';
            RETURN;
        END

        SET @ClientStaffIdOutput = NEWID();

        INSERT INTO Profile.ClientStaff
        (
            ClientStaffId, ClientIdFK, RoleIdFK, UserIdFK, ProviderIdFK,
            StaffCode, FirstName, LastName, Email, PhoneNumber,
            JobTitle, Department, StaffType, EmploymentType, HireDate,
            IsPrimaryContact, IsActive, IsDeleted,
            CreatedDate, CreatedBy, UpdatedDate, UpdatedBy
        )
        VALUES
        (
            @ClientStaffIdOutput, @ClientIdFK, @RoleIdFK, @UserIdFK, @ProviderIdFK,
            @StaffCode, @FirstName, @LastName,
            NULLIF(LTRIM(RTRIM(ISNULL(@Email, ''))), ''), @FormattedPhone,
            NULLIF(LTRIM(RTRIM(ISNULL(@JobTitle, ''))), ''), NULLIF(LTRIM(RTRIM(ISNULL(@Department, ''))), ''),
            @StaffType, @EmploymentType, @HireDate,
            @IsPrimaryContact, 1, 0,
            @Now, COALESCE(NULLIF(@CreatedBy, ''), SUSER_SNAME()), @Now, COALESCE(NULLIF(@CreatedBy, ''), SUSER_SNAME())
        );

        IF @IsPrimaryContact = 1
        BEGIN
            UPDATE Profile.ClientStaff
            SET IsPrimaryContact = CASE WHEN ClientStaffId = @ClientStaffIdOutput THEN 1 ELSE 0 END,
                UpdatedDate = @Now,
                UpdatedBy = COALESCE(NULLIF(@CreatedBy, ''), SUSER_SNAME())
            WHERE ClientIdFK = @ClientIdFK
              AND IsDeleted = 0;
        END

        SET @StatusCode = 0;
        SET @Message = '';
    END TRY
    BEGIN CATCH
        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                        ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                        @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
            )
            VALUES
            (
                @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
            );
        END

        SET @ClientStaffIdOutput = NULL;
        SET @StatusCode = -1;
        SET @Message = 'Failed to add client staff record.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spGetClientStaff]
(
    @ClientStaffId UNIQUEIDENTIFIER = NULL,
    @StaffCode VARCHAR(50) = '',
    @IncludeDeleted BIT = 0,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET @Message = '';

    IF @ClientStaffId IS NULL AND LTRIM(RTRIM(@StaffCode)) = ''
    BEGIN
        SET @Message = 'ClientStaffId or StaffCode is required.';
        RETURN;
    END

    IF EXISTS
    (
        SELECT 1
        FROM Profile.ClientStaff CS
        WHERE ((@ClientStaffId IS NOT NULL AND CS.ClientStaffId = @ClientStaffId)
               OR (@ClientStaffId IS NULL AND CS.StaffCode = @StaffCode))
          AND (@IncludeDeleted = 1 OR CS.IsDeleted = 0)
    )
    BEGIN
        SELECT
            CS.ClientStaffId,
            CS.ClientIdFK,
            C.ClientCode,
            CS.RoleIdFK,
            R.RoleName,
            CS.UserIdFK,
            U.Username,
            CS.ProviderIdFK,
            CS.StaffCode,
            CS.FirstName,
            CS.LastName,
            CS.Email,
            CS.PhoneNumber,
            CS.JobTitle,
            CS.Department,
            CS.StaffType,
            CS.EmploymentType,
            CS.HireDate,
            CS.TerminationDate,
            CS.IsPrimaryContact,
            CS.IsActive,
            CS.IsDeleted,
            CS.CreatedDate,
            CS.CreatedBy,
            CS.UpdatedDate,
            CS.UpdatedBy
        FROM Profile.ClientStaff CS
        INNER JOIN Profile.Clients C ON C.ClientId = CS.ClientIdFK
        LEFT JOIN Auth.Roles R ON R.RoleId = CS.RoleIdFK
        LEFT JOIN Auth.Users U ON U.UserId = CS.UserIdFK
        WHERE ((@ClientStaffId IS NOT NULL AND CS.ClientStaffId = @ClientStaffId)
               OR (@ClientStaffId IS NULL AND CS.StaffCode = @StaffCode))
          AND (@IncludeDeleted = 1 OR CS.IsDeleted = 0);

        SET @Message = '';
    END
    ELSE
    BEGIN
        SET @Message = 'Client staff not found.';
    END

    SET NOCOUNT OFF;
END
GO
USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spListClientStaff]
(
    @ClientIdFK UNIQUEIDENTIFIER = NULL,
    @SearchTerm VARCHAR(250) = '',
    @RoleIdFK UNIQUEIDENTIFIER = NULL,
    @StaffType VARCHAR(50) = '',
    @IsActive BIT = NULL,
    @IsDeleted BIT = 0,
    @PageNumber INT = 1,
    @PageSize INT = 25,
    @TotalRecords INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize < 1 SET @PageSize = 25;
    IF @PageSize > 200 SET @PageSize = 200;

    SET @TotalRecords = 0;
    SET @Message = '';

    ;WITH Base AS
    (
        SELECT
            CS.ClientStaffId,
            CS.ClientIdFK,
            C.ClientCode,
            CS.RoleIdFK,
            R.RoleName,
            CS.UserIdFK,
            U.Username,
            CS.ProviderIdFK,
            CS.StaffCode,
            CS.FirstName,
            CS.LastName,
            CS.Email,
            CS.PhoneNumber,
            CS.JobTitle,
            CS.Department,
            CS.StaffType,
            CS.EmploymentType,
            CS.HireDate,
            CS.TerminationDate,
            CS.IsPrimaryContact,
            CS.IsActive,
            CS.IsDeleted,
            CS.CreatedDate,
            CS.UpdatedDate
        FROM Profile.ClientStaff CS
        INNER JOIN Profile.Clients C ON C.ClientId = CS.ClientIdFK
        LEFT JOIN Auth.Roles R ON R.RoleId = CS.RoleIdFK
        LEFT JOIN Auth.Users U ON U.UserId = CS.UserIdFK
        WHERE (@ClientIdFK IS NULL OR CS.ClientIdFK = @ClientIdFK)
          AND (@RoleIdFK IS NULL OR CS.RoleIdFK = @RoleIdFK)
          AND (@StaffType = '' OR CS.StaffType = @StaffType)
          AND (@IsActive IS NULL OR CS.IsActive = @IsActive)
          AND (@IsDeleted IS NULL OR CS.IsDeleted = @IsDeleted)
          AND (
                @SearchTerm = ''
                OR CS.StaffCode LIKE '%' + @SearchTerm + '%'
                OR CS.FirstName LIKE '%' + @SearchTerm + '%'
                OR CS.LastName LIKE '%' + @SearchTerm + '%'
                OR ISNULL(CS.Email, '') LIKE '%' + @SearchTerm + '%'
                OR ISNULL(CS.PhoneNumber, '') LIKE '%' + @SearchTerm + '%'
                OR ISNULL(CS.JobTitle, '') LIKE '%' + @SearchTerm + '%'
              )
    ),
    Numbered AS
    (
        SELECT
            B.*,
            COUNT(1) OVER () AS TotalRows,
            ROW_NUMBER() OVER (ORDER BY B.LastName ASC, B.FirstName ASC, B.ClientStaffId ASC) AS RowNum
        FROM Base B
    )
    SELECT
        ClientStaffId,
        ClientIdFK,
        ClientCode,
        RoleIdFK,
        RoleName,
        UserIdFK,
        Username,
        ProviderIdFK,
        StaffCode,
        FirstName,
        LastName,
        Email,
        PhoneNumber,
        JobTitle,
        Department,
        StaffType,
        EmploymentType,
        HireDate,
        TerminationDate,
        IsPrimaryContact,
        IsActive,
        IsDeleted,
        CreatedDate,
        UpdatedDate
    FROM Numbered
    WHERE RowNum > ((@PageNumber - 1) * @PageSize)
      AND RowNum <= ((@PageNumber - 1) * @PageSize + @PageSize)
    ORDER BY RowNum;

    SELECT @TotalRecords = ISNULL(MAX(TotalRows), 0)
    FROM Numbered;

    SET NOCOUNT OFF;
END
GO
USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spUpdateClientStaff]
(
    @ClientStaffId UNIQUEIDENTIFIER,
    @RoleIdFK UNIQUEIDENTIFIER = NULL,
    @UserIdFK UNIQUEIDENTIFIER = NULL,
    @ProviderIdFK UNIQUEIDENTIFIER = NULL,
    @StaffCode VARCHAR(50),
    @FirstName VARCHAR(250),
    @LastName VARCHAR(250),
    @Email VARCHAR(250) = NULL,
    @PhoneNumber VARCHAR(25) = NULL,
    @JobTitle VARCHAR(150) = NULL,
    @Department VARCHAR(100) = NULL,
    @StaffType VARCHAR(50),
    @EmploymentType VARCHAR(50),
    @HireDate DATETIME = NULL,
    @TerminationDate DATETIME = NULL,
    @IsPrimaryContact BIT = 0,
    @IsActive BIT = 1,
    @UpdatedBy VARCHAR(250) = NULL,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE(),
            @ClientIdFK UNIQUEIDENTIFIER,
            @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME,
            @NormalizedPhone VARCHAR(25),
            @FormattedPhone VARCHAR(25);

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @StatusCode = -1;
    SET @Message = '';

    IF @ClientStaffId IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientStaffId is required.';
        RETURN;
    END

    IF LTRIM(RTRIM(ISNULL(@StaffCode, ''))) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'StaffCode is required.';
        RETURN;
    END

    IF LTRIM(RTRIM(ISNULL(@FirstName, ''))) = '' OR LTRIM(RTRIM(ISNULL(@LastName, ''))) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'FirstName and LastName are required.';
        RETURN;
    END

    IF @TerminationDate IS NOT NULL AND @HireDate IS NOT NULL AND @TerminationDate < @HireDate
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'TerminationDate cannot be before HireDate.';
        RETURN;
    END

    SELECT @ClientIdFK = ClientIdFK
    FROM Profile.ClientStaff
    WHERE ClientStaffId = @ClientStaffId
      AND IsDeleted = 0;

    IF @ClientIdFK IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Client staff not found or already deleted.';
        RETURN;
    END

    IF @RoleIdFK IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Auth.Roles WHERE RoleId = @RoleIdFK)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'RoleIdFK does not exist.';
        RETURN;
    END

    IF @UserIdFK IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Auth.Users WHERE UserId = @UserIdFK)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'UserIdFK does not exist.';
        RETURN;
    END

    IF @ProviderIdFK IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Profile.HealthcareProviders WHERE ProviderId = @ProviderIdFK)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ProviderIdFK does not exist.';
        RETURN;
    END

    IF NULLIF(LTRIM(RTRIM(ISNULL(@Email, ''))), '') IS NOT NULL
       AND @Email NOT LIKE '%_@_%._%'
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Invalid email format.';
        RETURN;
    END

    SET @NormalizedPhone = LTRIM(RTRIM(ISNULL(@PhoneNumber, '')));
    IF @NormalizedPhone <> ''
    BEGIN
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '-', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, ' ', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '+', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '(', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, ')', '');

        IF LEN(@NormalizedPhone) <> 10 OR @NormalizedPhone LIKE '%[^0-9]%'
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'PhoneNumber must contain exactly 10 digits.';
            RETURN;
        END

        SET @FormattedPhone = SUBSTRING(@NormalizedPhone, 1, 3) + '-' +
                              SUBSTRING(@NormalizedPhone, 4, 3) + '-' +
                              SUBSTRING(@NormalizedPhone, 7, 4);
    END
    ELSE
    BEGIN
        SET @FormattedPhone = NULL;
    END

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM Profile.ClientStaff WHERE StaffCode = @StaffCode AND ClientStaffId <> @ClientStaffId)
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'StaffCode already exists.';
            RETURN;
        END

        IF NULLIF(LTRIM(RTRIM(ISNULL(@Email, ''))), '') IS NOT NULL
           AND EXISTS
           (
               SELECT 1
               FROM Profile.ClientStaff
               WHERE ClientIdFK = @ClientIdFK
                 AND Email = LTRIM(RTRIM(@Email))
                 AND IsDeleted = 0
                 AND ClientStaffId <> @ClientStaffId
           )
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'Email already exists for this client.';
            RETURN;
        END

        UPDATE Profile.ClientStaff
        SET RoleIdFK = @RoleIdFK,
            UserIdFK = @UserIdFK,
            ProviderIdFK = @ProviderIdFK,
            StaffCode = @StaffCode,
            FirstName = @FirstName,
            LastName = @LastName,
            Email = NULLIF(LTRIM(RTRIM(ISNULL(@Email, ''))), ''),
            PhoneNumber = @FormattedPhone,
            JobTitle = NULLIF(LTRIM(RTRIM(ISNULL(@JobTitle, ''))), ''),
            Department = NULLIF(LTRIM(RTRIM(ISNULL(@Department, ''))), ''),
            StaffType = @StaffType,
            EmploymentType = @EmploymentType,
            HireDate = @HireDate,
            TerminationDate = @TerminationDate,
            IsPrimaryContact = @IsPrimaryContact,
            IsActive = @IsActive,
            UpdatedDate = @Now,
            UpdatedBy = COALESCE(NULLIF(@UpdatedBy, ''), SUSER_SNAME())
        WHERE ClientStaffId = @ClientStaffId
          AND IsDeleted = 0;

        IF @IsPrimaryContact = 1
        BEGIN
            UPDATE Profile.ClientStaff
            SET IsPrimaryContact = CASE WHEN ClientStaffId = @ClientStaffId THEN 1 ELSE 0 END,
                UpdatedDate = @Now,
                UpdatedBy = COALESCE(NULLIF(@UpdatedBy, ''), SUSER_SNAME())
            WHERE ClientIdFK = @ClientIdFK
              AND IsDeleted = 0;
        END

        SET @StatusCode = 0;
        SET @Message = '';
    END TRY
    BEGIN CATCH
        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                        ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                        @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
            )
            VALUES
            (
                @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
            );
        END

        SET @StatusCode = -1;
        SET @Message = 'Failed to update client staff record.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spDeleteClientStaff]
(
    @ClientStaffId UNIQUEIDENTIFIER = NULL,
    @StaffCode VARCHAR(50) = '',
    @UpdatedBy VARCHAR(250) = NULL,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @StatusCode = -1;
    SET @Message = '';

    IF @ClientStaffId IS NULL AND LTRIM(RTRIM(@StaffCode)) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientStaffId or StaffCode is required.';
        RETURN;
    END

    IF EXISTS
    (
        SELECT 1
        FROM Profile.ClientStaff
        WHERE ((@ClientStaffId IS NOT NULL AND ClientStaffId = @ClientStaffId)
               OR (@ClientStaffId IS NULL AND StaffCode = @StaffCode))
          AND IsDeleted = 0
    )
    BEGIN
        UPDATE Profile.ClientStaff
        SET IsDeleted = 1,
            IsActive = 0,
            IsPrimaryContact = 0,
            UpdatedDate = GETDATE(),
            UpdatedBy = COALESCE(NULLIF(@UpdatedBy, ''), SUSER_SNAME())
        WHERE ((@ClientStaffId IS NOT NULL AND ClientStaffId = @ClientStaffId)
               OR (@ClientStaffId IS NULL AND StaffCode = @StaffCode))
          AND IsDeleted = 0;

        SET @StatusCode = 0;
        SET @Message = '';
    END
    ELSE
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Client staff not found or already deleted.';
    END

    SET NOCOUNT OFF;
END
GO
CREATE OR ALTER FUNCTION [dbo].[CapitalizeFirstLetter]
(
    @InputString VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
AS
BEGIN
    IF @InputString IS NULL
        RETURN NULL;

    DECLARE @Index INT,
            @Char CHAR(1),
            @PrevChar CHAR(1),
            @OutputString VARCHAR(MAX);

    SET @OutputString = LOWER(@InputString);
    SET @Index = 1;

    WHILE @Index <= LEN(@InputString)
    BEGIN
        SET @Char = SUBSTRING(@InputString, @Index, 1);
        SET @PrevChar = CASE WHEN @Index = 1 THEN ' '
                             ELSE SUBSTRING(@InputString, @Index - 1, 1)
                        END;

        IF @PrevChar IN (' ', ';', ':', '!', '?', ',', '.', '_', '-', '/', '&', '''', '(')
        BEGIN
            IF @PrevChar <> ''''
                SET @OutputString = STUFF(@OutputString, @Index, 1, UPPER(@Char));
        END

        SET @Index = @Index + 1;
    END

    RETURN @OutputString;
END
GO

CREATE OR ALTER FUNCTION [dbo].[CapitalizeFirstLetterBody]
(
    @InputString VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
AS
BEGIN
    IF @InputString IS NULL
        RETURN NULL;

    DECLARE @Index INT,
            @Char CHAR(1),
            @PrevChar CHAR(1),
            @OutputString VARCHAR(MAX);

    SET @OutputString = LOWER(@InputString);
    SET @Index = 1;

    WHILE @Index <= LEN(@InputString)
    BEGIN
        SET @Char = SUBSTRING(@InputString, @Index, 1);
        SET @PrevChar = CASE WHEN @Index = 1 THEN ' '
                             ELSE SUBSTRING(@InputString, @Index - 1, 1)
                        END;

        IF @PrevChar IN (';', ':', '!', '?', ',', '.', '_', '-', '/', '&', '''', '(')
        BEGIN
            IF @PrevChar <> ''''
                SET @OutputString = STUFF(@OutputString, @Index, 1, UPPER(@Char));
        END

        SET @Index = @Index + 1;
    END

    RETURN @OutputString;
END
GO

CREATE OR ALTER FUNCTION [Contacts].[FormatPhoneNumber]
(
    @PhoneNumber VARCHAR(25)
)
RETURNS VARCHAR(12)
AS
BEGIN
    DECLARE @Normalized VARCHAR(25);

    IF @PhoneNumber IS NULL
        RETURN NULL;

    SET @Normalized = LTRIM(RTRIM(@PhoneNumber));
    SET @Normalized = REPLACE(@Normalized, '-', '');
    SET @Normalized = REPLACE(@Normalized, ' ', '');
    SET @Normalized = REPLACE(@Normalized, '+', '');
    SET @Normalized = REPLACE(@Normalized, '(', '');
    SET @Normalized = REPLACE(@Normalized, ')', '');

    IF LEN(@Normalized) <> 10 OR @Normalized LIKE '%[^0-9]%'
        RETURN NULL;

    RETURN SUBSTRING(@Normalized, 1, 3) + '-' +
           SUBSTRING(@Normalized, 4, 3) + '-' +
           SUBSTRING(@Normalized, 7, 4);
END
GO

CREATE OR ALTER TRIGGER [Contacts].[tr_NormalizeAndValidateEmail]
ON [Contacts].[Emails]
AFTER INSERT, UPDATE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    SET NOCOUNT ON;

    DECLARE @Normalized TABLE
    (
        EmailId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        NormalizedEmail VARCHAR(250) NOT NULL
    );

    INSERT INTO @Normalized (EmailId, NormalizedEmail)
    SELECT
        I.EmailId,
        LTRIM(RTRIM(LOWER(I.Email)))
    FROM inserted I;

    IF EXISTS
    (
        SELECT 1
        FROM @Normalized N
        WHERE N.NormalizedEmail = ''
           OR N.NormalizedEmail LIKE '% %'
           OR N.NormalizedEmail NOT LIKE '%_@_%._%'
    )
    BEGIN
        RAISERROR('Invalid email address format.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    UPDATE E
    SET
        E.Email = N.NormalizedEmail,
        E.UpdateDate = GETDATE(),
        E.UpdatedBy = SYSTEM_USER
    FROM Contacts.Emails E
    INNER JOIN @Normalized N ON N.EmailId = E.EmailId
    WHERE ISNULL(E.Email, '') <> ISNULL(N.NormalizedEmail, '');
END
GO

CREATE OR ALTER TRIGGER [Contacts].[tr_NormalizeAndValidatePhoneNumber]
ON [Contacts].[Phones]
AFTER INSERT, UPDATE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    SET NOCOUNT ON;

    DECLARE @Normalized TABLE
    (
        PhoneId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        FormattedPhone VARCHAR(12) NULL
    );

    INSERT INTO @Normalized (PhoneId, FormattedPhone)
    SELECT
        I.PhoneId,
        [Contacts].[FormatPhoneNumber](I.PhoneNumber)
    FROM inserted I;

    IF EXISTS
    (
        SELECT 1
        FROM @Normalized N
        WHERE N.FormattedPhone IS NULL
    )
    BEGIN
        RAISERROR('Invalid phone number format. Use a 10-digit phone number.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    UPDATE P
    SET
        P.PhoneNumber = N.FormattedPhone,
        P.UpdateDate = GETDATE(),
        P.UpdatedBy = SYSTEM_USER
    FROM Contacts.Phones P
    INNER JOIN @Normalized N ON N.PhoneId = P.PhoneId
    WHERE ISNULL(P.PhoneNumber, '') <> ISNULL(N.FormattedPhone, '');
END
GO

CREATE OR ALTER TRIGGER [Contacts].[tr_EnforceSinglePrimaryPatientEmail]
ON [Contacts].[PatientEmails]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    SET NOCOUNT ON;

    ;WITH AffectedPatients AS
    (
        SELECT DISTINCT PatientIdFK FROM inserted
        UNION
        SELECT DISTINCT PatientIdFK FROM deleted
    ),
    PrimaryRows AS
    (
        SELECT
            PE.PatientEmailId,
            PE.PatientIdFK,
            ROW_NUMBER() OVER
            (
                PARTITION BY PE.PatientIdFK
                ORDER BY
                    CASE WHEN PE.IsPrimary = 1 THEN 0 ELSE 1 END,
                    ISNULL(PE.UpdatedDate, PE.CreatedDate) DESC,
                    PE.PatientEmailId DESC
            ) AS RN,
            SUM(CASE WHEN PE.IsPrimary = 1 THEN 1 ELSE 0 END)
                OVER (PARTITION BY PE.PatientIdFK) AS PrimaryCount
        FROM Contacts.PatientEmails PE
        INNER JOIN AffectedPatients AP ON AP.PatientIdFK = PE.PatientIdFK
    )
    UPDATE PE
    SET
        IsPrimary = CASE WHEN PR.RN = 1 THEN 1 ELSE 0 END,
        UpdatedDate = GETDATE(),
        UpdatedBy = SYSTEM_USER
    FROM Contacts.PatientEmails PE
    INNER JOIN PrimaryRows PR ON PR.PatientEmailId = PE.PatientEmailId
    WHERE
        (PR.PrimaryCount = 0 OR PR.PrimaryCount > 1)
        OR (PR.RN = 1 AND PE.IsPrimary = 0)
        OR (PR.RN > 1 AND PE.IsPrimary = 1);
END
GO

CREATE OR ALTER TRIGGER [Contacts].[tr_EnforceSinglePrimaryPatientPhone]
ON [Contacts].[PatientPhones]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    SET NOCOUNT ON;

    ;WITH AffectedPatients AS
    (
        SELECT DISTINCT PatientIdFK FROM inserted
        UNION
        SELECT DISTINCT PatientIdFK FROM deleted
    ),
    PrimaryRows AS
    (
        SELECT
            PP.PatientPhoneId,
            PP.PatientIdFK,
            ROW_NUMBER() OVER
            (
                PARTITION BY PP.PatientIdFK
                ORDER BY
                    CASE WHEN PP.IsPrimary = 1 THEN 0 ELSE 1 END,
                    ISNULL(PP.UpdatedDate, PP.CreatedDate) DESC,
                    PP.PatientPhoneId DESC
            ) AS RN,
            SUM(CASE WHEN PP.IsPrimary = 1 THEN 1 ELSE 0 END)
                OVER (PARTITION BY PP.PatientIdFK) AS PrimaryCount
        FROM Contacts.PatientPhones PP
        INNER JOIN AffectedPatients AP ON AP.PatientIdFK = PP.PatientIdFK
    )
    UPDATE PP
    SET
        IsPrimary = CASE WHEN PR.RN = 1 THEN 1 ELSE 0 END,
        UpdatedDate = GETDATE(),
        UpdatedBy = SYSTEM_USER
    FROM Contacts.PatientPhones PP
    INNER JOIN PrimaryRows PR ON PR.PatientPhoneId = PP.PatientPhoneId
    WHERE
        (PR.PrimaryCount = 0 OR PR.PrimaryCount > 1)
        OR (PR.RN = 1 AND PP.IsPrimary = 0)
        OR (PR.RN > 1 AND PP.IsPrimary = 1);
END
GO

CREATE OR ALTER TRIGGER [Profile].[tr_AfterInsertPatient]
ON [Profile].[Patient]
AFTER INSERT
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    SET NOCOUNT ON;

    INSERT INTO Auth.AuditLog
    (
        ModifiedTime,
        ModifiedBy,
        Operation,
        SchemaName,
        TableName,
        TableID,
        LogData
    )
    SELECT
        GETDATE(),
        SYSTEM_USER,
        'Inserted',
        'Profile',
        'Patient',
        I.PatientId,
        J.LogData
    FROM inserted I
    CROSS APPLY
    (
        SELECT LogData =
        (
            SELECT
                I.PatientId,
                I.FirstName,
                I.LastName,
                I.ID_Number,
                I.DateOfBirth,
                I.GenderIDFK,
                I.MedicationList,
                I.AddressIDFK,
                I.MaritalStatusIDFK,
                I.EmergencyIDFK,
                I.IsDeleted,
                I.CreatedDate,
                I.CreatedBy,
                I.UpdatedDate,
                I.UpdatedBy
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    ) J;
END
GO

CREATE OR ALTER TRIGGER [Profile].[tr_AUpdatePatient]
ON [Profile].[Patient]
AFTER UPDATE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    SET NOCOUNT ON;

    ;WITH ChangedRows AS
    (
        SELECT I.*, D.PatientId AS DPatientId,
               D.FirstName AS DFirstName,
               D.LastName AS DLastName,
               D.ID_Number AS DID_Number,
               D.DateOfBirth AS DDateOfBirth,
               D.GenderIDFK AS DGenderIDFK,
               D.MedicationList AS DMedicationList,
               D.AddressIDFK AS DAddressIDFK,
               D.MaritalStatusIDFK AS DMaritalStatusIDFK,
               D.EmergencyIDFK AS DEmergencyIDFK,
               D.IsDeleted AS DIsDeleted,
               D.CreatedDate AS DCreatedDate,
               D.CreatedBy AS DCreatedBy,
               D.UpdatedDate AS DUpdatedDate,
               D.UpdatedBy AS DUpdatedBy
        FROM inserted I
        INNER JOIN deleted D ON D.PatientId = I.PatientId
        WHERE
            ISNULL(D.FirstName, '') <> ISNULL(I.FirstName, '') OR
            ISNULL(D.LastName, '') <> ISNULL(I.LastName, '') OR
            ISNULL(D.ID_Number, '') <> ISNULL(I.ID_Number, '') OR
            ISNULL(CONVERT(VARCHAR(30), D.DateOfBirth, 126), '') <> ISNULL(CONVERT(VARCHAR(30), I.DateOfBirth, 126), '') OR
            ISNULL(D.GenderIDFK, -1) <> ISNULL(I.GenderIDFK, -1) OR
            ISNULL(D.MedicationList, '') <> ISNULL(I.MedicationList, '') OR
            ISNULL(CONVERT(VARCHAR(36), D.AddressIDFK), '') <> ISNULL(CONVERT(VARCHAR(36), I.AddressIDFK), '') OR
            ISNULL(D.MaritalStatusIDFK, -1) <> ISNULL(I.MaritalStatusIDFK, -1) OR
            ISNULL(CONVERT(VARCHAR(36), D.EmergencyIDFK), '') <> ISNULL(CONVERT(VARCHAR(36), I.EmergencyIDFK), '') OR
            ISNULL(D.IsDeleted, 0) <> ISNULL(I.IsDeleted, 0) OR
            ISNULL(CONVERT(VARCHAR(30), D.CreatedDate, 126), '') <> ISNULL(CONVERT(VARCHAR(30), I.CreatedDate, 126), '') OR
            ISNULL(D.CreatedBy, '') <> ISNULL(I.CreatedBy, '') OR
            ISNULL(CONVERT(VARCHAR(30), D.UpdatedDate, 126), '') <> ISNULL(CONVERT(VARCHAR(30), I.UpdatedDate, 126), '') OR
            ISNULL(D.UpdatedBy, '') <> ISNULL(I.UpdatedBy, '')
    )
    INSERT INTO Auth.AuditLog
    (
        ModifiedTime,
        ModifiedBy,
        Operation,
        SchemaName,
        TableName,
        TableID,
        LogData
    )
    SELECT
        GETDATE(),
        SYSTEM_USER,
        'Updated',
        'Profile',
        'Patient',
        C.PatientId,
        J.LogData
    FROM ChangedRows C
    CROSS APPLY
    (
        SELECT LogData =
        (
            SELECT
                [Old] =
                (
                    SELECT
                        C.DPatientId AS PatientId,
                        C.DFirstName AS FirstName,
                        C.DLastName AS LastName,
                        C.DID_Number AS ID_Number,
                        C.DDateOfBirth AS DateOfBirth,
                        C.DGenderIDFK AS GenderIDFK,
                        C.DMedicationList AS MedicationList,
                        C.DAddressIDFK AS AddressIDFK,
                        C.DMaritalStatusIDFK AS MaritalStatusIDFK,
                        C.DEmergencyIDFK AS EmergencyIDFK,
                        C.DIsDeleted AS IsDeleted,
                        C.DCreatedDate AS CreatedDate,
                        C.DCreatedBy AS CreatedBy,
                        C.DUpdatedDate AS UpdatedDate,
                        C.DUpdatedBy AS UpdatedBy
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ),
                [New] =
                (
                    SELECT
                        C.PatientId,
                        C.FirstName,
                        C.LastName,
                        C.ID_Number,
                        C.DateOfBirth,
                        C.GenderIDFK,
                        C.MedicationList,
                        C.AddressIDFK,
                        C.MaritalStatusIDFK,
                        C.EmergencyIDFK,
                        C.IsDeleted,
                        C.CreatedDate,
                        C.CreatedBy,
                        C.UpdatedDate,
                        C.UpdatedBy
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                )
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    ) J;
END
GO

CREATE OR ALTER TRIGGER [Profile].[tr_ADeletePatient]
ON [Profile].[Patient]
INSTEAD OF DELETE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    SET NOCOUNT ON;

    INSERT INTO Auth.AuditLog
    (
        ModifiedTime,
        ModifiedBy,
        Operation,
        SchemaName,
        TableName,
        TableID,
        LogData
    )
    SELECT
        GETDATE(),
        SYSTEM_USER,
        'DeleteBlocked',
        'Profile',
        'Patient',
        D.PatientId,
        J.LogData
    FROM deleted D
    CROSS APPLY
    (
        SELECT LogData =
        (
            SELECT
                D.PatientId,
                D.FirstName,
                D.LastName,
                D.ID_Number,
                D.DateOfBirth,
                D.GenderIDFK,
                D.MedicationList,
                D.AddressIDFK,
                D.MaritalStatusIDFK,
                D.EmergencyIDFK,
                D.IsDeleted,
                D.CreatedDate,
                D.CreatedBy,
                D.UpdatedDate,
                D.UpdatedBy
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    ) J;

    RAISERROR('Hard delete is not allowed on Profile.Patient. Use soft delete (IsDeleted = 1).', 16, 1);
    ROLLBACK TRANSACTION;
    RETURN;
END
GO

CREATE OR ALTER TRIGGER [Profile].[tr_BlockPatientIDNumberUpdate]
ON [Profile].[Patient]
AFTER UPDATE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        INNER JOIN deleted D ON D.PatientId = I.PatientId
        WHERE ISNULL(I.ID_Number, '') <> ISNULL(D.ID_Number, '')
    )
    BEGIN
        RAISERROR('Updating Profile.Patient.ID_Number is not allowed.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO

CREATE OR ALTER TRIGGER [Profile].[tr_ValidateAppointmentStatusTransition]
ON [Profile].[Appointments]
AFTER UPDATE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        WHERE I.Status NOT IN ('Scheduled', 'In Progress', 'Completed', 'Cancelled', 'No-show', 'Rescheduled')
    )
    BEGIN
        RAISERROR('Invalid appointment status value.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        INNER JOIN deleted D ON D.AppointmentId = I.AppointmentId
        WHERE D.Status IN ('Completed', 'Cancelled', 'No-show')
          AND I.Status <> D.Status
    )
    BEGIN
        RAISERROR('Cannot transition from terminal appointment status.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        INNER JOIN deleted D ON D.AppointmentId = I.AppointmentId
        WHERE I.Status = 'Cancelled'
          AND D.Status <> 'Cancelled'
          AND (NULLIF(LTRIM(RTRIM(ISNULL(I.CancellationReason, ''))), '') IS NULL
               OR NULLIF(LTRIM(RTRIM(ISNULL(I.CancelledBy, ''))), '') IS NULL
               OR I.CancelledDate IS NULL)
    )
    BEGIN
        RAISERROR('Cancelled appointments require CancellationReason, CancelledBy and CancelledDate.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO

-- =================================================================================================
-- 7) Seed Lookup & Reference Data (inlined)
-- =================================================================================================
-- (Seed section consolidated further down; legacy duplicates removed.)

PRINT '[0/11] Initializing client clinic categories lookup...'
DECLARE @ClientCategoryDate DATETIME = GETDATE()
INSERT INTO Profile.ClientClinicCategories (CategoryName, ClinicSize, OwnershipType, IsActive, CreatedDate, UpdatedDate)
SELECT  V.CategoryName, V.ClinicSize, V.OwnershipType, 1, @ClientCategoryDate, @ClientCategoryDate
FROM (VALUES
    ('Small Private Clinic', 'Small', 'Private'),
    ('Small Public Clinic', 'Small', 'Public'),
    ('Medium Private Clinic', 'Medium', 'Private'),
    ('Medium Public Clinic', 'Medium', 'Public')
) V(CategoryName, ClinicSize, OwnershipType)
LEFT JOIN Profile.ClientClinicCategories C ON C.CategoryName = V.CategoryName
WHERE C.ClientClinicCategoryId IS NULL;
GO

-- Step 1: Initialize Location Lookups (no dependencies)
PRINT '[1/11] Initializing Countries lookup...'
-- Inlined and adapted from: 005. Insert Countries.sql
-- Begin countries insert
DECLARE @DefaultDate DATETIME = GETDATE()
INSERT INTO Location.Countries ( CountryName, Alpha2Code, Alpha3Code, Numeric, IsActive, UpdateDate)
SELECT  v.CountryName, v.Alpha2Code, v.Alpha3Code, v.Numeric, v.IsActive, v.UpdateDate
FROM (VALUES
	('South Africa', 'ZA', 'ZAF', 710, 1, @DefaultDate),
	('Botswana', 'BW', 'BWA', 0, 1, @DefaultDate),
	('Lesotho', 'LS', 'LSO', 0, 1, @DefaultDate),
	('Namibia', 'NA', 'NAM', 0, 1, @DefaultDate),
	('Eswatini', 'SZ', 'SWZ', 0, 1, @DefaultDate),
	('Zimbabwe', 'ZW', 'ZWE', 0, 1, @DefaultDate),
	('Mozambique', 'MZ', 'MOZ', 0, 1, @DefaultDate),
	('Angola', 'AO', 'AGO', 0, 1, @DefaultDate),
	('Zambia', 'ZM', 'ZMB', 0, 1, @DefaultDate),
	('Malawi', 'MW', 'MWI', 0, 1, @DefaultDate),
	('United States', 'US', 'USA', 0, 1, @DefaultDate),
	('United Kingdom', 'GB', 'GBR', 0, 1, @DefaultDate),
	('Canada', 'CA', 'CAN', 0, 1, @DefaultDate),
	('Australia', 'AU', 'AUS', 0, 1, @DefaultDate),
	('Germany', 'DE', 'DEU', 0, 1, @DefaultDate),
	('France', 'FR', 'FRA', 0, 1, @DefaultDate),
	('India', 'IN', 'IND', 0, 1, @DefaultDate),
	('Brazil', 'BR', 'BRA', 0, 1, @DefaultDate),
	('Japan', 'JP', 'JPN', 0, 1, @DefaultDate),
	('China', 'CN', 'CHN', 0, 1, @DefaultDate)
) v(CountryName, Alpha2Code, Alpha3Code, Numeric, IsActive, UpdateDate)
LEFT JOIN Location.Countries c ON c.Alpha2Code = v.Alpha2Code
WHERE c.CountryId IS NULL;

PRINT 'Countries lookup table populated successfully'
-- End countries insert
GO

PRINT '[2/11] Initializing Provinces lookup...'
-- Inlined: 006. Insert Provinces.sql (adapted)
-- Begin provinces insert
DECLARE @CountryId INT = (SELECT CountryId FROM Location.Countries WHERE Alpha2Code = 'ZA'),
		@DefaultDate2 DATETIME = GETDATE()

INSERT INTO Location.Provinces ( ProvinceName, CountryIDFK, IsActive, UpdateDate)
SELECT  v.ProvinceName, v.CountryIDFK, v.IsActive, v.UpdateDate
FROM (VALUES
	( 'Western Cape', @CountryId, 1, @DefaultDate2),
	( 'Eastern Cape', @CountryId, 1, @DefaultDate2),
	( 'Northern Cape', @CountryId, 1, @DefaultDate2),
	( 'Free State', @CountryId, 1, @DefaultDate2),
	( 'KwaZulu-Natal', @CountryId, 1, @DefaultDate2),
	( 'Gauteng', @CountryId, 1, @DefaultDate2),
	( 'Limpopo', @CountryId, 1, @DefaultDate2),
	( 'Mpumalanga', @CountryId, 1, @DefaultDate2),
	( 'North West', @CountryId, 1, @DefaultDate2)
) v(ProvinceName, CountryIDFK, IsActive, UpdateDate)
LEFT JOIN Location.Provinces p ON p.ProvinceName = v.ProvinceName AND p.CountryIDFK = v.CountryIDFK
WHERE p.ProvinceId IS NULL;

PRINT 'Provinces lookup table populated successfully'
-- End provinces insert
GO

PRINT '[3/11] Initializing Cities lookup...'
-- Inlined: 007. Insert Cities.sql (adapted)
-- Begin cities insert
DECLARE @DefaultDate3 DATETIME = GETDATE(),
		@ProvinceId_GT INT = (SELECT ProvinceId FROM Location.Provinces WHERE ProvinceName = 'Gauteng'),
		@ProvinceId_WC INT = (SELECT ProvinceId FROM Location.Provinces WHERE ProvinceName = 'Western Cape'),
		@ProvinceId_KZN INT = (SELECT ProvinceId FROM Location.Provinces WHERE ProvinceName = 'KwaZulu-Natal'),
		@ProvinceId_EC INT = (SELECT ProvinceId FROM Location.Provinces WHERE ProvinceName = 'Eastern Cape'),
		@ProvinceId_MP INT = (SELECT ProvinceId FROM Location.Provinces WHERE ProvinceName = 'Mpumalanga'),
		@ProvinceId_LP INT = (SELECT ProvinceId FROM Location.Provinces WHERE ProvinceName = 'Limpopo'),
		@ProvinceId_FS INT = (SELECT ProvinceId FROM Location.Provinces WHERE ProvinceName = 'Free State'),
		@ProvinceId_NC INT = (SELECT ProvinceId FROM Location.Provinces WHERE ProvinceName = 'Northern Cape'),
		@ProvinceId_NW INT = (SELECT ProvinceId FROM Location.Provinces WHERE ProvinceName = 'North West')

INSERT INTO Location.Cities ( CityName, ProvinceIDFK, IsActive, UpdateDate)
SELECT v.CityName, v.ProvinceIDFK, v.IsActive, v.UpdateDate
FROM (VALUES
	('Johannesburg', @ProvinceId_GT, 1, @DefaultDate3),
	('Pretoria', @ProvinceId_GT, 1, @DefaultDate3),
	('Sandton', @ProvinceId_GT, 1, @DefaultDate3),
	('Midrand', @ProvinceId_GT, 1, @DefaultDate3),
	('Soweto', @ProvinceId_GT, 1, @DefaultDate3),
	('Benoni', @ProvinceId_GT, 1, @DefaultDate3),
	('Germiston', @ProvinceId_GT, 1, @DefaultDate3),
	('Roodepoort', @ProvinceId_GT, 1, @DefaultDate3),
	('Cape Town', @ProvinceId_WC, 1, @DefaultDate3),
	('Bellville', @ProvinceId_WC, 1, @DefaultDate3),
	('Parow', @ProvinceId_WC, 1, @DefaultDate3),
	('Mitchells Plain', @ProvinceId_WC, 1, @DefaultDate3),
	('Stellenbosch', @ProvinceId_WC, 1, @DefaultDate3),
	('Paarl', @ProvinceId_WC, 1, @DefaultDate3),
	('Durban', @ProvinceId_KZN, 1, @DefaultDate3),
	('Pietermaritzburg', @ProvinceId_KZN, 1, @DefaultDate3),
	('Newcastle', @ProvinceId_KZN, 1, @DefaultDate3),
	('Pinetown', @ProvinceId_KZN, 1, @DefaultDate3),
	('Umhlanga', @ProvinceId_KZN, 1, @DefaultDate3),
	('Westville', @ProvinceId_KZN, 1, @DefaultDate3),
	('Port Elizabeth', @ProvinceId_EC, 1, @DefaultDate3),
	('East London', @ProvinceId_EC, 1, @DefaultDate3),
	('Gqeberha', @ProvinceId_EC, 1, @DefaultDate3),
	('Nelspruit', @ProvinceId_MP, 1, @DefaultDate3),
	('Secunda', @ProvinceId_MP, 1, @DefaultDate3),
	('Emalahleni', @ProvinceId_MP, 1, @DefaultDate3),
	('Polokwane', @ProvinceId_LP, 1, @DefaultDate3),
	('Messina', @ProvinceId_LP, 1, @DefaultDate3),
	('Musina', @ProvinceId_LP, 1, @DefaultDate3),
	('Bloemfontein', @ProvinceId_FS, 1, @DefaultDate3),
	('Welkom', @ProvinceId_FS, 1, @DefaultDate3),
	('Kroonstad', @ProvinceId_FS, 1, @DefaultDate3),
	('Kimberley', @ProvinceId_NC, 1, @DefaultDate3),
	('De Aar', @ProvinceId_NC, 1, @DefaultDate3),
	('Rustenburg', @ProvinceId_NW, 1, @DefaultDate3),
	('Mafikeng', @ProvinceId_NW, 1, @DefaultDate3),
	('Potchefstroom', @ProvinceId_NW, 1, @DefaultDate3)
) v( CityName, ProvinceIDFK, IsActive, UpdateDate)
LEFT JOIN Location.Cities c ON c.CityName = v.CityName AND c.ProvinceIDFK = v.ProvinceIDFK
WHERE c.CityId IS NULL;

PRINT 'Cities lookup table populated successfully'
-- End cities insert
GO

-- Step 2: Initialize Gender and Marital Status
PRINT '[4/11] Initializing Gender lookup...'
-- Inlined: Insert Gender.sql (adapted)
DECLARE @GenderDate DATETIME = GETDATE()

INSERT INTO Profile.Gender (GenderDescription, IsActive, UpdateDate)
SELECT v.GenderDescription, v.IsActive, @GenderDate
FROM (VALUES
    ('Male', 1),
    ('Female', 1),
    ('Other', 1),
    ('Prefer Not to Say', 1)
) v(GenderDescription, IsActive)
WHERE NOT EXISTS (
    SELECT 1
    FROM Profile.Gender g
    WHERE g.GenderDescription = v.GenderDescription
)

PRINT 'Gender lookup table populated successfully'
GO

PRINT '[5/11] Initializing Marital Status lookup...'
-- Inlined: Insert Marital Status (adapted)
DECLARE @MaritalDate DATETIME = GETDATE()

INSERT INTO Profile.MaritalStatus (MaritalStatusDescription, IsActive, UpdateDate)
SELECT v.MaritalStatusDescription, v.IsActive, @MaritalDate
FROM (VALUES
    ('Single', 1),
    ('Married', 1),
    ('Widowed', 1),
    ('Divorced', 1),
    ('Separated', 1),
    ('Domestic Partnership', 1)
) v(MaritalStatusDescription, IsActive)
WHERE NOT EXISTS (
    SELECT 1
    FROM Profile.MaritalStatus ms
    WHERE ms.MaritalStatusDescription = v.MaritalStatusDescription
)

PRINT 'Marital status lookup table populated successfully'
GO

-- Step 3: Initialize Auth roles and permissions
PRINT '[6/11] Initializing Auth Roles...'
DECLARE @RolesDate DATETIME = GETDATE()

INSERT INTO Auth.Roles (RoleName, Description, IsActive, CreatedDate, CreatedBy)
SELECT v.RoleName, v.Description, 1, @RolesDate, 'SYSTEM'
FROM (VALUES
    ('ADMIN', 'System Administrator - Full system access'),
    ('DOCTOR', 'Medical Doctor - Patient care and clinical decision making'),
    ('NURSE', 'Registered Nurse - Patient care and monitoring'),
    ('RECEPTIONIST', 'Receptionist - Appointment scheduling and patient check-in'),
    ('PATIENT', 'Patient - Access own health records and appointment booking'),
    ('BILLING', 'Billing Administrator - Invoice and payment management'),
    ('PHARMACIST', 'Pharmacist - Medication management and dispensing')
) v(RoleName, Description)
WHERE NOT EXISTS (
    SELECT 1
    FROM Auth.Roles r
    WHERE r.RoleName = v.RoleName
)

PRINT 'Auth roles inserted successfully'
GO

PRINT '[7/11] Initializing Auth Permissions...'
DECLARE @PermDate DATETIME = GETDATE()

INSERT INTO Auth.Permissions (PermissionId, PermissionName, Description, Category, Module, ActionType, IsActive, CreatedDate, CreatedBy)
SELECT
    NEWID(),
    v.PermissionName,
    v.Description,
    v.Category,
    v.Module,
    v.ActionType,
    1,
    @PermDate,
    'SYSTEM'
FROM (VALUES
    ('Patient_Create', 'Create new patient record', 'PATIENT', 'CORE', 'CREATE'),
    ('Patient_Read', 'View patient information', 'PATIENT', 'CORE', 'READ'),
    ('Patient_Update', 'Modify patient information', 'PATIENT', 'CORE', 'UPDATE'),
    ('Patient_Delete', 'Delete patient record', 'PATIENT', 'CORE', 'DELETE'),
    ('Patient_ViewAll', 'View all patients in system', 'PATIENT', 'CORE', 'READ'),
    ('MedicalHistory_Create', 'Add medical history entry', 'CLINICAL', 'MEDICAL_HISTORY', 'CREATE'),
    ('MedicalHistory_Read', 'View medical history', 'CLINICAL', 'MEDICAL_HISTORY', 'READ'),
    ('MedicalHistory_Update', 'Modify medical history', 'CLINICAL', 'MEDICAL_HISTORY', 'UPDATE'),
    ('MedicalHistory_Delete', 'Delete medical history entry', 'CLINICAL', 'MEDICAL_HISTORY', 'DELETE'),
    ('Appointment_Create', 'Create appointment', 'CLINICAL', 'APPOINTMENTS', 'CREATE'),
    ('Appointment_Read', 'View appointments', 'CLINICAL', 'APPOINTMENTS', 'READ'),
    ('Appointment_Update', 'Modify appointment', 'CLINICAL', 'APPOINTMENTS', 'UPDATE'),
    ('Appointment_Cancel', 'Cancel appointment', 'CLINICAL', 'APPOINTMENTS', 'UPDATE'),
    ('Appointment_ViewAll', 'View all appointments', 'CLINICAL', 'APPOINTMENTS', 'READ'),
    ('Medication_Create', 'Add medication record', 'CLINICAL', 'MEDICATIONS', 'CREATE'),
    ('Medication_Read', 'View medication history', 'CLINICAL', 'MEDICATIONS', 'READ'),
    ('Medication_Update', 'Modify medication record', 'CLINICAL', 'MEDICATIONS', 'UPDATE'),
    ('Medication_Delete', 'Remove medication record', 'CLINICAL', 'MEDICATIONS', 'DELETE'),
    ('Medication_Manage', 'Manage all medications in system', 'CLINICAL', 'MEDICATIONS', 'MANAGE'),
    ('ConsultationNotes_Create', 'Create consultation notes', 'CLINICAL', 'NOTES', 'CREATE'),
    ('ConsultationNotes_Read', 'View consultation notes', 'CLINICAL', 'NOTES', 'READ'),
    ('ConsultationNotes_Update', 'Modify consultation notes', 'CLINICAL', 'NOTES', 'UPDATE'),
    ('ConsultationNotes_Delete', 'Delete consultation notes', 'CLINICAL', 'NOTES', 'DELETE'),
    ('Form_Create', 'Create form template', 'WORKFLOW', 'FORMS', 'CREATE'),
    ('Form_Read', 'View forms', 'WORKFLOW', 'FORMS', 'READ'),
    ('Form_Update', 'Modify form template', 'WORKFLOW', 'FORMS', 'UPDATE'),
    ('Form_Delete', 'Delete form', 'WORKFLOW', 'FORMS', 'DELETE'),
    ('Form_Submit', 'Submit form', 'WORKFLOW', 'FORMS', 'SUBMIT'),
    ('Form_Review', 'Review submitted forms', 'WORKFLOW', 'FORMS', 'REVIEW'),
    ('Invoice_Create', 'Create invoice', 'BILLING', 'BILLING', 'CREATE'),
    ('Invoice_Read', 'View invoices', 'BILLING', 'BILLING', 'READ'),
    ('Invoice_Update', 'Modify invoice', 'BILLING', 'BILLING', 'UPDATE'),
    ('Invoice_Delete', 'Delete invoice', 'BILLING', 'BILLING', 'DELETE'),
    ('Payment_Process', 'Process payment', 'BILLING', 'PAYMENTS', 'EXECUTE'),
    ('Payment_View', 'View payment history', 'BILLING', 'PAYMENTS', 'READ'),
    ('Insurance_Create', 'Create insurance record', 'BILLING', 'INSURANCE', 'CREATE'),
    ('Insurance_Read', 'View insurance information', 'BILLING', 'INSURANCE', 'READ'),
    ('Insurance_Update', 'Modify insurance record', 'BILLING', 'INSURANCE', 'UPDATE'),
    ('Insurance_Delete', 'Delete insurance record', 'BILLING', 'INSURANCE', 'DELETE'),
    ('Allergy_Create', 'Add allergy record', 'CLINICAL', 'ALLERGY', 'CREATE'),
    ('Allergy_Read', 'View allergy information', 'CLINICAL', 'ALLERGY', 'READ'),
    ('Allergy_Update', 'Modify allergy record', 'CLINICAL', 'ALLERGY', 'UPDATE'),
    ('Allergy_Delete', 'Delete allergy record', 'CLINICAL', 'ALLERGY', 'DELETE'),
    ('LabResults_Create', 'Create lab results', 'CLINICAL', 'LABS', 'CREATE'),
    ('LabResults_Read', 'View lab results', 'CLINICAL', 'LABS', 'READ'),
    ('LabResults_Update', 'Modify lab results', 'CLINICAL', 'LABS', 'UPDATE'),
    ('LabResults_Delete', 'Delete lab results', 'CLINICAL', 'LABS', 'DELETE'),
    ('SystemAdmin_User', 'Manage users and roles', 'ADMIN', 'SYSTEM', 'MANAGE'),
    ('SystemAdmin_Audit', 'View audit logs', 'ADMIN', 'SYSTEM', 'READ'),
    ('SystemAdmin_Reports', 'Generate system reports', 'ADMIN', 'SYSTEM', 'EXECUTE'),
    ('SystemAdmin_Settings', 'Modify system settings', 'ADMIN', 'SYSTEM', 'UPDATE'),
    ('SystemAdmin_Database', 'Database administration', 'ADMIN', 'SYSTEM', 'ADMIN'),
    ('Referral_Create', 'Create referral', 'CLINICAL', 'REFERRALS', 'CREATE'),
    ('Referral_Read', 'View referrals', 'CLINICAL', 'REFERRALS', 'READ'),
    ('Referral_Update', 'Update referral status', 'CLINICAL', 'REFERRALS', 'UPDATE'),
    ('Referral_Delete', 'Delete referral', 'CLINICAL', 'REFERRALS', 'DELETE')
) v(PermissionName, Description, Category, Module, ActionType)
WHERE NOT EXISTS (
    SELECT 1
    FROM Auth.Permissions p
    WHERE p.PermissionName = v.PermissionName
)

PRINT 'Auth permissions inserted successfully'
GO

PRINT '[8/11] Mapping Role Permissions...'
-- Use uniqueidentifier types for RoleId/PermissionId
DECLARE @MapDate DATETIME = GETDATE(),
		@RoleId_ADMIN UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'ADMIN'),
		@RoleId_DOCTOR UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'DOCTOR'),
		@RoleId_NURSE UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'NURSE'),
		@RoleId_RECEPTIONIST UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'RECEPTIONIST'),
		@RoleId_PATIENT UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'PATIENT'),
		@RoleId_BILLING UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'BILLING'),
		@RoleId_PHARMACIST UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'PHARMACIST')

INSERT INTO Auth.RolePermissions (RolePermissionId, RoleIdFK, PermissionIdFK, CreatedDate, CreatedBy)
SELECT NEWID(), RPM.RoleIdFK, RPM.PermissionIdFK, @MapDate, 'SYSTEM'
FROM
(
    SELECT @RoleId_ADMIN AS RoleIdFK, P.PermissionId AS PermissionIdFK
    FROM Auth.Permissions P

    UNION ALL

    SELECT @RoleId_DOCTOR, P.PermissionId
    FROM Auth.Permissions P
    WHERE P.PermissionName IN (
        'Patient_Create', 'Patient_Read', 'Patient_Update', 'Patient_ViewAll',
        'MedicalHistory_Create', 'MedicalHistory_Read', 'MedicalHistory_Update', 'MedicalHistory_Delete',
        'Appointment_Create', 'Appointment_Read', 'Appointment_Update', 'Appointment_Cancel', 'Appointment_ViewAll',
        'Medication_Create', 'Medication_Read', 'Medication_Update', 'Medication_Delete', 'Medication_Manage',
        'ConsultationNotes_Create', 'ConsultationNotes_Read', 'ConsultationNotes_Update', 'ConsultationNotes_Delete',
        'Allergy_Create', 'Allergy_Read', 'Allergy_Update', 'Allergy_Delete',
        'LabResults_Create', 'LabResults_Read', 'LabResults_Update',
        'Referral_Create', 'Referral_Read', 'Referral_Update',
        'Insurance_Read', 'Payment_View'
    )

    UNION ALL

    SELECT @RoleId_NURSE, P.PermissionId
    FROM Auth.Permissions P
    WHERE P.PermissionName IN (
        'Patient_Read', 'Patient_Update', 'Patient_ViewAll',
        'MedicalHistory_Create', 'MedicalHistory_Read', 'MedicalHistory_Update',
        'Appointment_Read', 'Appointment_ViewAll',
        'Medication_Read', 'Medication_Update',
        'ConsultationNotes_Create', 'ConsultationNotes_Read', 'ConsultationNotes_Update',
        'Allergy_Create', 'Allergy_Read', 'Allergy_Update', 'Allergy_Delete',
        'LabResults_Create', 'LabResults_Read', 'LabResults_Update',
        'Form_Read', 'Form_Submit', 'Form_Review',
        'Payment_View'
    )

    UNION ALL

    SELECT @RoleId_RECEPTIONIST, P.PermissionId
    FROM Auth.Permissions P
    WHERE P.PermissionName IN (
        'Patient_Create', 'Patient_Read', 'Patient_Update', 'Patient_ViewAll',
        'Appointment_Create', 'Appointment_Read', 'Appointment_Update', 'Appointment_Cancel', 'Appointment_ViewAll',
        'Form_Read', 'Form_Submit',
        'Payment_View'
    )

    UNION ALL

    SELECT @RoleId_PATIENT, P.PermissionId
    FROM Auth.Permissions P
    WHERE P.PermissionName IN (
        'Patient_Read', 'Patient_Update',
        'MedicalHistory_Read',
        'Appointment_Create', 'Appointment_Read', 'Appointment_Cancel',
        'Medication_Read',
        'ConsultationNotes_Read',
        'Allergy_Read',
        'LabResults_Read',
        'Form_Read', 'Form_Submit',
        'Insurance_Read',
        'Payment_View'
    )

    UNION ALL

    SELECT @RoleId_BILLING, P.PermissionId
    FROM Auth.Permissions P
    WHERE P.PermissionName IN (
        'Patient_Read', 'Patient_ViewAll',
        'Appointment_Read', 'Appointment_ViewAll',
        'Invoice_Create', 'Invoice_Read', 'Invoice_Update', 'Invoice_Delete',
        'Payment_Process', 'Payment_View',
        'Insurance_Create', 'Insurance_Read', 'Insurance_Update', 'Insurance_Delete'
    )

    UNION ALL

    SELECT @RoleId_PHARMACIST, P.PermissionId
    FROM Auth.Permissions P
    WHERE P.PermissionName IN (
        'Patient_Read', 'Patient_ViewAll',
        'Medication_Create', 'Medication_Read', 'Medication_Update', 'Medication_Delete', 'Medication_Manage',
        'Prescription_Read',
        'Allergy_Read'
    )
) RPM
WHERE RPM.RoleIdFK IS NOT NULL
  AND RPM.PermissionIdFK IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM Auth.RolePermissions RP
      WHERE RP.RoleIdFK = RPM.RoleIdFK
        AND RP.PermissionIdFK = RPM.PermissionIdFK
  )

PRINT 'Role permissions mapped successfully'
GO

PRINT '[9/11] Creating initial admin user...'
-- Create admin user and assign role (use GUIDs)
DECLARE @AdminDate DATETIME = GETDATE(),
		@AdminRoleId UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'ADMIN'),
		@AdminUserId UNIQUEIDENTIFIER

-- Provide securely at execution time:
--   sqlcmd -v ADMIN_PASSWORD_HASH="<bcrypt hash>"
DECLARE @AdminPasswordHash VARCHAR(MAX) = '$(ADMIN_PASSWORD_HASH)',
		@AdminPasswordHashPlaceholder VARCHAR(64) = CHAR(36) + '(ADMIN_PASSWORD_HASH)'

SELECT @AdminUserId = UserId FROM Auth.Users WHERE Username = 'admin'

IF @AdminUserId IS NULL
BEGIN
	IF NULLIF(LTRIM(RTRIM(ISNULL(@AdminPasswordHash, ''))), '') IS NULL
	   OR @AdminPasswordHash = @AdminPasswordHashPlaceholder
		THROW 50001, 'ADMIN_PASSWORD_HASH is required to create admin user.', 1;

	SET @AdminUserId = NEWID()

	INSERT INTO Auth.Users (UserId, Username, Email, PasswordHash, FirstName, LastName, IsActive, LastLoginDate, CreatedDate, CreatedBy)
	VALUES (@AdminUserId, 'admin', 'admin@healthcareform.local', @AdminPasswordHash, 'System', 'Administrator', 1, NULL, @AdminDate, 'SYSTEM')
END

IF NOT EXISTS (
	SELECT 1
	FROM Auth.UserRoles UR
	WHERE UR.UserIdFK = @AdminUserId
	  AND UR.RoleIdFK = @AdminRoleId
)
BEGIN
	INSERT INTO Auth.UserRoles (UserRoleId, UserIdFK, RoleIdFK, CreatedDate, CreatedBy)
	VALUES (NEWID(), @AdminUserId, @AdminRoleId, @AdminDate, 'SYSTEM')
END

PRINT 'Admin user created successfully'
PRINT 'Username: admin'
PRINT 'Admin user created. Do NOT store or print passwords in repository.'
PRINT 'Set the admin password via a secure secret and rotate it immediately.'
GO

-- Step 4: Initialize Billing Codes (adapted to Profile schema)
PRINT '[10/11] Initializing Billing Codes...'
DECLARE @BillingDefaultDate DATETIME = GETDATE()

INSERT INTO Profile.BillingCodes (BillingCodeId, CodeType, Code, Description, Category, Cost, EffectiveDate, IsActive, CreatedDate, CreatedBy)
SELECT
    NEWID(),
    v.CodeType,
    v.Code,
    v.Description,
    v.Category,
    v.Cost,
    @BillingDefaultDate,
    1,
    @BillingDefaultDate,
    'SYSTEM'
FROM (VALUES
    ('ICD-10', 'E10.9', 'Type 1 diabetes mellitus without complications', 'ENDOCRINE', 0.00),
    ('ICD-10', 'E11.9', 'Type 2 diabetes mellitus without complications', 'ENDOCRINE', 0.00),
    ('ICD-10', 'E78.5', 'Hyperlipidemia, unspecified', 'METABOLIC', 0.00),
    ('ICD-10', 'I10', 'Essential (primary) hypertension', 'CARDIOVASCULAR', 0.00),
    ('ICD-10', 'I21.9', 'ST elevation (STEMI) and non-ST elevation (NSTEMI) of unspecified site', 'CARDIOVASCULAR', 0.00),
    ('ICD-10', 'I50.9', 'Heart failure, unspecified', 'CARDIOVASCULAR', 0.00),
    ('ICD-10', 'J45.901', 'Unspecified asthma with (acute) exacerbation', 'RESPIRATORY', 0.00),
    ('ICD-10', 'J06.9', 'Acute upper respiratory infection, unspecified', 'RESPIRATORY', 0.00),
    ('ICD-10', 'J44.9', 'Chronic obstructive pulmonary disease, unspecified', 'RESPIRATORY', 0.00),
    ('ICD-10', 'F41.1', 'Generalized anxiety disorder', 'PSYCHIATRIC', 0.00),
    ('ICD-10', 'F32.9', 'Major depressive disorder, single episode, unspecified', 'PSYCHIATRIC', 0.00),
    ('ICD-10', 'F33.9', 'Major depressive disorder, recurrent, unspecified', 'PSYCHIATRIC', 0.00),
    ('ICD-10', 'K21.9', 'Unspecified gastro-esophageal reflux disease', 'GASTROINTESTINAL', 0.00),
    ('ICD-10', 'K29.7', 'Gastritis, unspecified', 'GASTROINTESTINAL', 0.00),
    ('ICD-10', 'K80.9', 'Unspecified cholelithiasis', 'GASTROINTESTINAL', 0.00),
    ('ICD-10', 'M79.3', 'Panniculitis, unspecified', 'MUSCULOSKELETAL', 0.00),
    ('ICD-10', 'M15.9', 'Unspecified osteoarthritis', 'MUSCULOSKELETAL', 0.00),
    ('ICD-10', 'M17.11', 'Primary osteoarthritis, right knee', 'MUSCULOSKELETAL', 0.00),
    ('ICD-10', 'M54.5', 'Low back pain', 'MUSCULOSKELETAL', 0.00),
    ('ICD-10', 'N39.0', 'Urinary tract infection, site not specified', 'GENITOURINARY', 0.00),
    ('CPT', '99213', 'Office visit for established patient - low complexity', 'CONSULTATION', 0.00),
    ('CPT', '99214', 'Office visit for established patient - moderate complexity', 'CONSULTATION', 0.00),
    ('CPT', '99215', 'Office visit for established patient - high complexity', 'CONSULTATION', 0.00),
    ('CPT', '99232', 'Inpatient hospital visit - established patient - low complexity', 'INPATIENT', 0.00),
    ('CPT', '93000', 'Electrocardiogram - complete', 'DIAGNOSTIC', 0.00),
    ('CPT', '70450', 'Computed tomography, head or brain - without contrast', 'DIAGNOSTIC', 0.00),
    ('CPT', '71020', 'Chest X-ray - 2 views', 'DIAGNOSTIC', 0.00),
    ('CPT', '80053', 'Comprehensive metabolic panel', 'LABORATORY', 0.00),
    ('CPT', '85025', 'Complete blood count - automated', 'LABORATORY', 0.00),
    ('CPT', '80061', 'Lipid panel', 'LABORATORY', 0.00),
    ('CPT', '92004', 'Comprehensive eye exam - new patient', 'SPECIALTY', 0.00),
    ('CPT', '29881', 'Arthroscopy, knee - diagnostic', 'SURGICAL', 0.00),
    ('CPT', '49505', 'Repair initial inguinal hernia', 'SURGICAL', 0.00),
    ('CPT', '47562', 'Laparoscopic cholecystectomy', 'SURGICAL', 0.00),
    ('HCPCS', 'J1100', 'Injection, dexamethasone sodium phosphate - 4mg', 'INJECTION', 0.00),
    ('HCPCS', 'J1110', 'Injection, dihydroergotamine mesylate - per 1mg', 'INJECTION', 0.00),
    ('HCPCS', 'J3301', 'Triamcinolone acetonide, preservative-free', 'INJECTION', 0.00),
    ('HCPCS', 'E0781', 'Ambulatory infusion pump - stationary or single speed', 'EQUIPMENT', 0.00),
    ('HCPCS', 'E1390', 'Oxygen concentrator, portable - rental', 'EQUIPMENT', 0.00)
) v(CodeType, Code, Description, Category, Cost)
WHERE NOT EXISTS (
    SELECT 1
    FROM Profile.BillingCodes BC
    WHERE BC.Code = v.Code
)

PRINT 'Billing codes inserted successfully'
GO

PRINT '[11/11] Initializing Healthcare Providers and Insurance...'
-- Healthcare providers (map ProviderName -> FirstName)
DECLARE @ProvidersDefaultDate DATETIME = GETDATE()

INSERT INTO Profile.HealthcareProviders (ProviderId, FirstName, LastName, Title, Specialization, LicenseNumber, RegistrationBody, ProviderType, Qualifications, YearsOfExperience, OfficeAddressIdFK, IsActive, CreatedDate, CreatedBy)
SELECT
    NEWID(),
    v.FirstName,
    v.LastName,
    v.Title,
    v.Specialization,
    v.LicenseNumber,
    v.RegistrationBody,
    v.ProviderType,
    v.Qualifications,
    v.YearsOfExperience,
    v.OfficeAddressIdFK,
    1,
    @ProvidersDefaultDate,
    'SYSTEM'
FROM (VALUES
    ('Dr. Thabo Mthembu', '', CAST(NULL AS VARCHAR(50)), 'GP', 'ZA-MP-0012345', 'N/A', 'GENERAL_PRACTITIONER', CAST(NULL AS VARCHAR(250)), CAST(NULL AS INT), CAST(NULL AS UNIQUEIDENTIFIER)),
    ('Dr. Naledi Johnson', '', CAST(NULL AS VARCHAR(50)), 'CARDIOLOGY', 'ZA-MP-0054321', 'N/A', 'CARDIOLOGIST', CAST(NULL AS VARCHAR(250)), CAST(NULL AS INT), CAST(NULL AS UNIQUEIDENTIFIER)),
    ('Dr. Amira Hassan', '', CAST(NULL AS VARCHAR(50)), 'NEUROLOGY', 'ZA-MP-0098765', 'N/A', 'NEUROLOGIST', CAST(NULL AS VARCHAR(250)), CAST(NULL AS INT), CAST(NULL AS UNIQUEIDENTIFIER)),
    ('Dr. Kevin Smith', '', CAST(NULL AS VARCHAR(50)), 'ORTHOPEDICS', 'ZA-MP-0011111', 'N/A', 'ORTHOPEDIC_SURGEON', CAST(NULL AS VARCHAR(250)), CAST(NULL AS INT), CAST(NULL AS UNIQUEIDENTIFIER)),
    ('Dr. Patricia Ndlovu', '', CAST(NULL AS VARCHAR(50)), 'PEDIATRICS', 'ZA-MP-0022222', 'N/A', 'PEDIATRICIAN', CAST(NULL AS VARCHAR(250)), CAST(NULL AS INT), CAST(NULL AS UNIQUEIDENTIFIER)),
    ('Dr. Michael Chen', '', CAST(NULL AS VARCHAR(50)), 'PSYCHIATRY', 'ZA-MP-0033333', 'N/A', 'PSYCHIATRIST', CAST(NULL AS VARCHAR(250)), CAST(NULL AS INT), CAST(NULL AS UNIQUEIDENTIFIER)),
    ('Dr. Sarah Botha', '', CAST(NULL AS VARCHAR(50)), 'ENDOCRINOLOGY', 'ZA-MP-0044444', 'N/A', 'ENDOCRINOLOGIST', CAST(NULL AS VARCHAR(250)), CAST(NULL AS INT), CAST(NULL AS UNIQUEIDENTIFIER)),
    ('Dr. James Okafor', '', CAST(NULL AS VARCHAR(50)), 'PULMONOLOGY', 'ZA-MP-0055555', 'N/A', 'PULMONOLOGIST', CAST(NULL AS VARCHAR(250)), CAST(NULL AS INT), CAST(NULL AS UNIQUEIDENTIFIER)),
    ('Dr. Kavya Patel', '', CAST(NULL AS VARCHAR(50)), 'GASTROENTEROLOGY', 'ZA-MP-0066666', 'N/A', 'GASTROENTEROLOGIST', CAST(NULL AS VARCHAR(250)), CAST(NULL AS INT), CAST(NULL AS UNIQUEIDENTIFIER)),
    ('Dr. Robert Mendes', '', CAST(NULL AS VARCHAR(50)), 'UROLOGY', 'ZA-MP-0077777', 'N/A', 'UROLOGIST', CAST(NULL AS VARCHAR(250)), CAST(NULL AS INT), CAST(NULL AS UNIQUEIDENTIFIER))
) v(FirstName, LastName, Title, Specialization, LicenseNumber, RegistrationBody, ProviderType, Qualifications, YearsOfExperience, OfficeAddressIdFK)
WHERE NOT EXISTS (
    SELECT 1
    FROM Profile.HealthcareProviders HP
    WHERE HP.LicenseNumber = v.LicenseNumber
)

PRINT 'Healthcare providers inserted successfully'
GO

-- Insurance providers (map to Profile.InsuranceProviders)
DECLARE @InsuranceDefaultDate DATETIME = GETDATE()

INSERT INTO Profile.InsuranceProviders (InsuranceProviderId, ProviderName, RegistrationNumber, ContactPerson, AddressIdFK, PhoneNumber, Email, WebsiteUrl, BillingCode, IsActive, Notes, CreatedDate, CreatedBy)
SELECT
    NEWID(),
    v.ProviderName,
    v.RegistrationNumber,
    v.ContactPerson,
    v.AddressIdFK,
    v.PhoneNumber,
    v.Email,
    v.WebsiteUrl,
    v.BillingCode,
    1,
    v.Notes,
    @InsuranceDefaultDate,
    'SYSTEM'
FROM (VALUES
    ('Discovery Health', 'REG001', CAST(NULL AS VARCHAR(250)), CAST(NULL AS UNIQUEIDENTIFIER), '+27 11 799 8000', 'inquiry@discovery.co.za', CAST(NULL AS VARCHAR(250)), CAST(NULL AS VARCHAR(100)), CAST(NULL AS VARCHAR(MAX))),
    ('Momentum Health Solutions', 'REG002', CAST(NULL AS VARCHAR(250)), CAST(NULL AS UNIQUEIDENTIFIER), '+27 11 408 6600', 'support@momentum.co.za', CAST(NULL AS VARCHAR(250)), CAST(NULL AS VARCHAR(100)), CAST(NULL AS VARCHAR(MAX))),
    ('Medshelf Medical Scheme', 'REG003', CAST(NULL AS VARCHAR(250)), CAST(NULL AS UNIQUEIDENTIFIER), '+27 10 020 2020', 'membercare@medshelf.co.za', CAST(NULL AS VARCHAR(250)), CAST(NULL AS VARCHAR(100)), CAST(NULL AS VARCHAR(MAX))),
    ('Bonitas', 'REG004', CAST(NULL AS VARCHAR(250)), CAST(NULL AS UNIQUEIDENTIFIER), '+27 11 407 5000', 'support@bonitas.co.za', CAST(NULL AS VARCHAR(250)), CAST(NULL AS VARCHAR(100)), CAST(NULL AS VARCHAR(MAX))),
    ('Polmed', 'REG005', CAST(NULL AS VARCHAR(250)), CAST(NULL AS UNIQUEIDENTIFIER), '+27 11 386 4800', 'info@polmed.co.za', CAST(NULL AS VARCHAR(250)), CAST(NULL AS VARCHAR(100)), CAST(NULL AS VARCHAR(MAX))),
    ('GEMS (Government Employees Medical Scheme)', 'REG006', CAST(NULL AS VARCHAR(250)), CAST(NULL AS UNIQUEIDENTIFIER), '+27 12 307 9000', 'support@gems.gov.za', CAST(NULL AS VARCHAR(250)), CAST(NULL AS VARCHAR(100)), CAST(NULL AS VARCHAR(MAX))),
    ('Sizwe Medical Scheme', 'REG007', CAST(NULL AS VARCHAR(250)), CAST(NULL AS UNIQUEIDENTIFIER), '+27 11 287 8000', 'member@sizwehealth.co.za', CAST(NULL AS VARCHAR(250)), CAST(NULL AS VARCHAR(100)), CAST(NULL AS VARCHAR(MAX))),
    ('Umkhulu Medical Scheme', 'REG008', CAST(NULL AS VARCHAR(250)), CAST(NULL AS UNIQUEIDENTIFIER), '+27 31 328 6000', 'support@umkhulu.co.za', CAST(NULL AS VARCHAR(250)), CAST(NULL AS VARCHAR(100)), CAST(NULL AS VARCHAR(MAX)))
) v(ProviderName, RegistrationNumber, ContactPerson, AddressIdFK, PhoneNumber, Email, WebsiteUrl, BillingCode, Notes)
WHERE NOT EXISTS (
    SELECT 1
    FROM Profile.InsuranceProviders IP
    WHERE IP.RegistrationNumber = v.RegistrationNumber
       OR IP.ProviderName = v.ProviderName
)

PRINT 'Insurance providers inserted successfully'
GO

-- Lookup schema: reference allergy & medication lists (keeps reference data separate from patient records)
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Lookup')
	EXEC('CREATE SCHEMA Lookup')
GO

IF OBJECT_ID(N'[Lookup].[Allergies]', N'U') IS NULL
BEGIN
CREATE TABLE Lookup.Allergies (
	AllergyId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
	AllergyName VARCHAR(250) NOT NULL,
	AllergyCategory VARCHAR(50) NOT NULL,
	Severity VARCHAR(50) NOT NULL,
	ReactionDescription VARCHAR(MAX) NULL,
	IsCritical BIT NOT NULL DEFAULT 0,
	IsActive BIT NOT NULL DEFAULT 1,
	CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
	CreatedBy VARCHAR(250) NULL,
	PRIMARY KEY (AllergyId)
)
END
GO

IF OBJECT_ID(N'[Lookup].[Medications]', N'U') IS NULL
BEGIN
CREATE TABLE Lookup.Medications (
	MedicationId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
	MedicationName VARCHAR(250) NOT NULL,
	MedicationGenericName VARCHAR(250) NULL,
	MedicationCategory VARCHAR(100) NULL,
	Strength VARCHAR(50) NULL,
	Unit VARCHAR(50) NULL,
	RouteOfAdministration VARCHAR(50) NULL,
	ManufacturerName VARCHAR(250) NULL,
	IsActive BIT NOT NULL DEFAULT 1,
	CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
	CreatedBy VARCHAR(250) NULL,
	PRIMARY KEY (MedicationId)
)
END
GO

-- Insert common allergies (from original seed)
DECLARE @AllMedDefaultDate DATETIME = GETDATE()

INSERT INTO Lookup.Allergies (AllergyName, AllergyCategory, Severity, ReactionDescription, IsCritical, IsActive, CreatedDate, CreatedBy)
SELECT
    v.AllergyName,
    v.AllergyCategory,
    v.Severity,
    v.ReactionDescription,
    v.IsCritical,
    1,
    @AllMedDefaultDate,
    'SYSTEM'
FROM (VALUES
    ('Penicillin', 'MEDICATION', 'HIGH', 'Anaphylaxis - severe respiratory distress', 1),
    ('Cephalosporin', 'MEDICATION', 'HIGH', 'Anaphylaxis - hives and throat swelling', 1),
    ('Aspirin', 'MEDICATION', 'MEDIUM', 'Rash and gastrointestinal upset', 0),
    ('NSAIDs', 'MEDICATION', 'MEDIUM', 'Gastric ulcers and bleeding', 0),
    ('Sulfonamides', 'MEDICATION', 'HIGH', 'Stevens-Johnson Syndrome risk', 1),
    ('Peanuts', 'FOOD', 'HIGH', 'Anaphylaxis - throat closing', 1),
    ('Tree Nuts', 'FOOD', 'HIGH', 'Anaphylaxis and airway obstruction', 1),
    ('Shellfish', 'FOOD', 'HIGH', 'Anaphylaxis - cardiovascular collapse risk', 1),
    ('Milk', 'FOOD', 'MEDIUM', 'Lactose intolerance and digestive issues', 0),
    ('Eggs', 'FOOD', 'MEDIUM', 'Urticaria and gastrointestinal symptoms', 0),
    ('Latex', 'ENVIRONMENTAL', 'HIGH', 'Anaphylaxis - respiratory compromise', 1),
    ('Iodine', 'MEDICATION', 'MEDIUM', 'Angioedema and rash', 0),
    ('Codeine', 'MEDICATION', 'MEDIUM', 'Respiratory depression and hypersensitivity', 0),
    ('ACE Inhibitors', 'MEDICATION', 'MEDIUM', 'Persistent cough and angioedema', 0),
    ('Statins', 'MEDICATION', 'LOW', 'Muscle pain and elevated liver enzymes', 0)
) v(AllergyName, AllergyCategory, Severity, ReactionDescription, IsCritical)
WHERE NOT EXISTS (
    SELECT 1
    FROM Lookup.Allergies A
    WHERE A.AllergyName = v.AllergyName
)

GO
DECLARE @AllMedDefaultDate DATETIME = GETDATE()
-- Insert common reference medications
INSERT INTO Lookup.Medications (MedicationName, MedicationGenericName, MedicationCategory, Strength, Unit, RouteOfAdministration, ManufacturerName, IsActive, CreatedDate, CreatedBy)
SELECT
    v.MedicationName,
    v.MedicationGenericName,
    v.MedicationCategory,
    v.Strength,
    v.Unit,
    v.RouteOfAdministration,
    v.ManufacturerName,
    1,
    @AllMedDefaultDate,
    'SYSTEM'
FROM (VALUES
    ('Amoxicillin', 'Amoxicillin', 'ANTIBIOTIC', '500', 'mg', 'ORAL', 'Various Manufacturers'),
    ('Lisinopril', 'Lisinopril', 'ACE_INHIBITOR', '10', 'mg', 'ORAL', 'Various Manufacturers'),
    ('Metformin', 'Metformin', 'ANTIDIABETIC', '500', 'mg', 'ORAL', 'Various Manufacturers'),
    ('Atorvastatin', 'Atorvastatin', 'STATIN', '20', 'mg', 'ORAL', 'Pfizer'),
    ('Omeprazole', 'Omeprazole', 'PROTON_PUMP_INHIBITOR', '20', 'mg', 'ORAL', 'Various Manufacturers'),
    ('Sertraline', 'Sertraline', 'ANTIDEPRESSANT', '50', 'mg', 'ORAL', 'Pfizer'),
    ('Ibuprofen', 'Ibuprofen', 'NSAID', '400', 'mg', 'ORAL', 'Various Manufacturers'),
    ('Albuterol', 'Salbutamol', 'BRONCHODILATOR', '100', 'mcg', 'INHALED', 'Various Manufacturers'),
    ('Insulin Glargine', 'Insulin Glargine', 'INSULIN', '100', 'IU/mL', 'SUBCUTANEOUS', 'Sanofi'),
    ('Levothyroxine', 'Levothyroxine', 'THYROID_HORMONE', '50', 'mcg', 'ORAL', 'Various Manufacturers'),
    ('Potassium Chloride', 'Potassium Chloride', 'ELECTROLYTE', '20', 'mEq', 'ORAL', 'Various Manufacturers'),
    ('Metoprolol', 'Metoprolol', 'BETA_BLOCKER', '50', 'mg', 'ORAL', 'Various Manufacturers'),
    ('Warfarin', 'Warfarin', 'ANTICOAGULANT', '5', 'mg', 'ORAL', 'Various Manufacturers'),
    ('Amlodipine', 'Amlodipine', 'CALCIUM_CHANNEL_BLOCKER', '5', 'mg', 'ORAL', 'Various Manufacturers'),
    ('Clopidogrel', 'Clopidogrel', 'ANTIPLATELET', '75', 'mg', 'ORAL', 'Sanofi')
) v(MedicationName, MedicationGenericName, MedicationCategory, Strength, Unit, RouteOfAdministration, ManufacturerName)
WHERE NOT EXISTS (
    SELECT 1
    FROM Lookup.Medications M
    WHERE M.MedicationName = v.MedicationName
)

PRINT 'Allergies and medications reference data inserted successfully'
-- End allergies and medications insert
GO

-- ============================================================================================
-- Client Department Helpers
-- ============================================================================================
CREATE OR ALTER PROC [Profile].[spAddClientDepartment]
(
    @ClientIdFK UNIQUEIDENTIFIER,
    @DepartmentName VARCHAR(100),
    @DepartmentCode VARCHAR(50) = NULL,
    @DepartmentType VARCHAR(50) = 'Clinical',
    @CreatedBy VARCHAR(250) = NULL,
    @ClientDepartmentIdOutput UNIQUEIDENTIFIER OUTPUT,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE();

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @ClientDepartmentIdOutput = NULL;
    SET @StatusCode = -1;
    SET @Message = '';

    IF @ClientIdFK IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientIdFK is required.';
        RETURN;
    END

    IF LTRIM(RTRIM(ISNULL(@DepartmentName, ''))) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'DepartmentName is required.';
        RETURN;
    END

    IF @DepartmentType NOT IN ('Clinical', 'Administrative', 'Support', 'Management', 'Allied')
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Invalid DepartmentType.';
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Profile.Clients WHERE ClientId = @ClientIdFK AND IsDeleted = 0)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Client does not exist or is deleted.';
        RETURN;
    END

    IF EXISTS
    (
        SELECT 1
        FROM Profile.ClientDepartments
        WHERE ClientIdFK = @ClientIdFK
          AND DepartmentName = LTRIM(RTRIM(@DepartmentName))
          AND IsDeleted = 0
    )
    BEGIN
        SET @StatusCode = 2;
        SET @Message = 'Department already exists for this client.';
        RETURN;
    END

    SET @ClientDepartmentIdOutput = NEWID();

    INSERT INTO Profile.ClientDepartments
    (
        ClientDepartmentId,
        ClientIdFK,
        DepartmentCode,
        DepartmentName,
        DepartmentType,
        IsActive,
        IsDeleted,
        CreatedDate,
        CreatedBy,
        UpdatedDate,
        UpdatedBy
    )
    VALUES
    (
        @ClientDepartmentIdOutput,
        @ClientIdFK,
        NULLIF(LTRIM(RTRIM(ISNULL(@DepartmentCode, ''))), ''),
        LTRIM(RTRIM(@DepartmentName)),
        @DepartmentType,
        1,
        0,
        @Now,
        COALESCE(NULLIF(@CreatedBy, ''), SUSER_SNAME()),
        @Now,
        COALESCE(NULLIF(@CreatedBy, ''), SUSER_SNAME())
    );

    SET @StatusCode = 0;
    SET @Message = '';
    SET NOCOUNT OFF;
END
GO

CREATE OR ALTER PROC [Profile].[spListClientDepartments]
(
    @ClientIdFK UNIQUEIDENTIFIER = NULL,
    @DepartmentType VARCHAR(50) = '',
    @SearchTerm VARCHAR(100) = '',
    @IsActive BIT = NULL,
    @IsDeleted BIT = 0,
    @PageNumber INT = 1,
    @PageSize INT = 25,
    @TotalRecords INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Offset INT;

    SET NOCOUNT ON;

    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize < 1 SET @PageSize = 25;
    IF @PageSize > 200 SET @PageSize = 200;

    IF @DepartmentType <> ''
       AND @DepartmentType NOT IN ('Clinical', 'Administrative', 'Support', 'Management', 'Allied')
    BEGIN
        SET @TotalRecords = 0;
        SET @Message = 'Invalid DepartmentType.';
        RETURN;
    END

    SET @Offset = (@PageNumber - 1) * @PageSize;
    SET @TotalRecords = 0;
    SET @Message = '';

    ;WITH Base AS
    (
        SELECT
            CD.ClientDepartmentId,
            CD.ClientIdFK,
            C.ClientCode,
            C.FirstName AS ClientFirstName,
            C.LastName AS ClientLastName,
            CD.DepartmentCode,
            CD.DepartmentName,
            CD.DepartmentType,
            CD.IsActive,
            CD.IsDeleted,
            CD.CreatedDate,
            CD.CreatedBy,
            CD.UpdatedDate,
            CD.UpdatedBy
        FROM Profile.ClientDepartments CD
        INNER JOIN Profile.Clients C ON C.ClientId = CD.ClientIdFK
        WHERE (@ClientIdFK IS NULL OR CD.ClientIdFK = @ClientIdFK)
          AND (@DepartmentType = '' OR CD.DepartmentType = @DepartmentType)
          AND (@IsActive IS NULL OR CD.IsActive = @IsActive)
          AND (@IsDeleted IS NULL OR CD.IsDeleted = @IsDeleted)
          AND
          (
                @SearchTerm = ''
                OR CD.DepartmentName LIKE '%' + @SearchTerm + '%'
                OR ISNULL(CD.DepartmentCode, '') LIKE '%' + @SearchTerm + '%'
                OR C.ClientCode LIKE '%' + @SearchTerm + '%'
          )
    ),
    Numbered AS
    (
        SELECT
            B.*,
            COUNT(1) OVER () AS TotalRows,
            ROW_NUMBER() OVER (ORDER BY B.DepartmentName ASC, B.ClientDepartmentId ASC) AS RowNum
        FROM Base B
    )
    SELECT
        ClientDepartmentId,
        ClientIdFK,
        ClientCode,
        ClientFirstName,
        ClientLastName,
        DepartmentCode,
        DepartmentName,
        DepartmentType,
        IsActive,
        IsDeleted,
        CreatedDate,
        CreatedBy,
        UpdatedDate,
        UpdatedBy
    FROM Numbered
    WHERE RowNum > @Offset
      AND RowNum <= (@Offset + @PageSize)
    ORDER BY RowNum;

    SELECT @TotalRecords = ISNULL(MAX(TotalRows), 0)
    FROM Numbered;

    SET @Message = '';
    SET NOCOUNT OFF;
END
GO

CREATE OR ALTER PROC [Profile].[spUpdateClientDepartment]
(
    @ClientDepartmentId UNIQUEIDENTIFIER,
    @DepartmentName VARCHAR(100),
    @DepartmentCode VARCHAR(50) = NULL,
    @DepartmentType VARCHAR(50),
    @IsActive BIT = 1,
    @UpdatedBy VARCHAR(250) = NULL,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE(),
            @ClientIdFK UNIQUEIDENTIFIER;

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @StatusCode = -1;
    SET @Message = '';

    IF @ClientDepartmentId IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientDepartmentId is required.';
        RETURN;
    END

    IF LTRIM(RTRIM(ISNULL(@DepartmentName, ''))) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'DepartmentName is required.';
        RETURN;
    END

    IF @DepartmentType NOT IN ('Clinical', 'Administrative', 'Support', 'Management', 'Allied')
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Invalid DepartmentType.';
        RETURN;
    END

    SELECT @ClientIdFK = ClientIdFK
    FROM Profile.ClientDepartments
    WHERE ClientDepartmentId = @ClientDepartmentId
      AND IsDeleted = 0;

    IF @ClientIdFK IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Client department not found or already deleted.';
        RETURN;
    END

    IF EXISTS
    (
        SELECT 1
        FROM Profile.ClientDepartments
        WHERE ClientIdFK = @ClientIdFK
          AND DepartmentName = LTRIM(RTRIM(@DepartmentName))
          AND ClientDepartmentId <> @ClientDepartmentId
          AND IsDeleted = 0
    )
    BEGIN
        SET @StatusCode = 2;
        SET @Message = 'Department name already exists for this client.';
        RETURN;
    END

    UPDATE Profile.ClientDepartments
    SET DepartmentCode = NULLIF(LTRIM(RTRIM(ISNULL(@DepartmentCode, ''))), ''),
        DepartmentName = LTRIM(RTRIM(@DepartmentName)),
        DepartmentType = @DepartmentType,
        IsActive = @IsActive,
        UpdatedDate = @Now,
        UpdatedBy = COALESCE(NULLIF(@UpdatedBy, ''), SUSER_SNAME())
    WHERE ClientDepartmentId = @ClientDepartmentId
      AND IsDeleted = 0;

    SET @StatusCode = 0;
    SET @Message = '';
    SET NOCOUNT OFF;
END
GO

CREATE OR ALTER PROC [Profile].[spDeleteClientDepartment]
(
    @ClientDepartmentId UNIQUEIDENTIFIER,
    @UpdatedBy VARCHAR(250) = NULL,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE();

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @StatusCode = -1;
    SET @Message = '';

    IF @ClientDepartmentId IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientDepartmentId is required.';
        RETURN;
    END

    IF NOT EXISTS
    (
        SELECT 1
        FROM Profile.ClientDepartments
        WHERE ClientDepartmentId = @ClientDepartmentId
          AND IsDeleted = 0
    )
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Client department not found or already deleted.';
        RETURN;
    END

    DECLARE @HasAssignedStaff BIT = 0;
    IF COL_LENGTH('Profile.ClientStaff', 'PrimaryDepartmentIdFK') IS NOT NULL
    BEGIN
        DECLARE @CheckSql NVARCHAR(MAX) = N'
            IF EXISTS
            (
                SELECT 1
                FROM Profile.ClientStaff
                WHERE PrimaryDepartmentIdFK = @DeptId
                  AND IsDeleted = 0
            )
                SET @HasAssignedStaffOut = 1;';

        EXEC sp_executesql
            @CheckSql,
            N'@DeptId UNIQUEIDENTIFIER, @HasAssignedStaffOut BIT OUTPUT',
            @DeptId = @ClientDepartmentId,
            @HasAssignedStaffOut = @HasAssignedStaff OUTPUT;
    END

    IF @HasAssignedStaff = 1
    BEGIN
        SET @StatusCode = 2;
        SET @Message = 'Department cannot be deleted while staff are assigned to it.';
        RETURN;
    END

    UPDATE Profile.ClientDepartments
    SET IsDeleted = 1,
        IsActive = 0,
        UpdatedDate = @Now,
        UpdatedBy = COALESCE(NULLIF(@UpdatedBy, ''), SUSER_SNAME())
    WHERE ClientDepartmentId = @ClientDepartmentId
      AND IsDeleted = 0;

    SET @StatusCode = 0;
    SET @Message = '';
    SET NOCOUNT OFF;
END
GO

-- ============================================================================================
-- Phase 1 Hardening: tenant-ready columns + rerunnable FK/index creation
-- ============================================================================================
IF OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
BEGIN
	IF COL_LENGTH('Profile.Patient', 'ClientIdFK') IS NULL
		ALTER TABLE [Profile].[Patient] ADD [ClientIdFK] UNIQUEIDENTIFIER NULL;
END
GO

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
BEGIN
	IF COL_LENGTH('Profile.Appointments', 'ClientIdFK') IS NULL
		ALTER TABLE [Profile].[Appointments] ADD [ClientIdFK] UNIQUEIDENTIFIER NULL;
END
GO

IF OBJECT_ID(N'[Profile].[ConsultationNotes]', N'U') IS NOT NULL
BEGIN
	IF COL_LENGTH('Profile.ConsultationNotes', 'ClientIdFK') IS NULL
		ALTER TABLE [Profile].[ConsultationNotes] ADD [ClientIdFK] UNIQUEIDENTIFIER NULL;
END
GO

IF OBJECT_ID(N'[Contacts].[FormSubmissions]', N'U') IS NOT NULL
BEGIN
	IF COL_LENGTH('Contacts.FormSubmissions', 'ClientIdFK') IS NULL
		ALTER TABLE [Contacts].[FormSubmissions] ADD [ClientIdFK] UNIQUEIDENTIFIER NULL;
END
GO

IF OBJECT_ID(N'[Profile].[Invoices]', N'U') IS NOT NULL
BEGIN
	IF COL_LENGTH('Profile.Invoices', 'ClientIdFK') IS NULL
		ALTER TABLE [Profile].[Invoices] ADD [ClientIdFK] UNIQUEIDENTIFIER NULL;
END
GO

IF OBJECT_ID(N'[Profile].[Clients]', N'U') IS NOT NULL AND OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Patient_Client')
BEGIN
	ALTER TABLE [Profile].[Patient] WITH CHECK
	ADD CONSTRAINT [FK_Patient_Client] FOREIGN KEY([ClientIdFK]) REFERENCES [Profile].[Clients]([ClientId]);
END
GO

IF OBJECT_ID(N'[Profile].[Clients]', N'U') IS NOT NULL AND OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Appointments_Client')
BEGIN
	ALTER TABLE [Profile].[Appointments] WITH CHECK
	ADD CONSTRAINT [FK_Appointments_Client] FOREIGN KEY([ClientIdFK]) REFERENCES [Profile].[Clients]([ClientId]);
END
GO

IF OBJECT_ID(N'[Profile].[Clients]', N'U') IS NOT NULL AND OBJECT_ID(N'[Profile].[ConsultationNotes]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ConsultationNotes_Client')
BEGIN
	ALTER TABLE [Profile].[ConsultationNotes] WITH CHECK
	ADD CONSTRAINT [FK_ConsultationNotes_Client] FOREIGN KEY([ClientIdFK]) REFERENCES [Profile].[Clients]([ClientId]);
END
GO

IF OBJECT_ID(N'[Profile].[Clients]', N'U') IS NOT NULL AND OBJECT_ID(N'[Contacts].[FormSubmissions]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_FormSubmissions_Client')
BEGIN
	ALTER TABLE [Contacts].[FormSubmissions] WITH CHECK
	ADD CONSTRAINT [FK_FormSubmissions_Client] FOREIGN KEY([ClientIdFK]) REFERENCES [Profile].[Clients]([ClientId]);
END
GO

IF OBJECT_ID(N'[Profile].[Clients]', N'U') IS NOT NULL AND OBJECT_ID(N'[Profile].[Invoices]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Invoices_Client')
BEGIN
	ALTER TABLE [Profile].[Invoices] WITH CHECK
	ADD CONSTRAINT [FK_Invoices_Client] FOREIGN KEY([ClientIdFK]) REFERENCES [Profile].[Clients]([ClientId]);
END
GO

IF OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Patient]') AND name = 'IX_Patient_ClientIdFK')
	CREATE INDEX IX_Patient_ClientIdFK ON [Profile].[Patient]([ClientIdFK]);
GO

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Appointments]') AND name = 'IX_Appointments_ClientIdFK_AppointmentDateTime')
	CREATE INDEX IX_Appointments_ClientIdFK_AppointmentDateTime ON [Profile].[Appointments]([ClientIdFK], [AppointmentDateTime]);
GO

IF OBJECT_ID(N'[Profile].[ConsultationNotes]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ConsultationNotes]') AND name = 'IX_ConsultationNotes_ClientIdFK')
	CREATE INDEX IX_ConsultationNotes_ClientIdFK ON [Profile].[ConsultationNotes]([ClientIdFK]);
GO

IF OBJECT_ID(N'[Contacts].[FormSubmissions]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[FormSubmissions]') AND name = 'IX_FormSubmissions_ClientIdFK')
	CREATE INDEX IX_FormSubmissions_ClientIdFK ON [Contacts].[FormSubmissions]([ClientIdFK]);
GO

IF OBJECT_ID(N'[Profile].[Invoices]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Invoices]') AND name = 'IX_Invoices_ClientIdFK')
	CREATE INDEX IX_Invoices_ClientIdFK ON [Profile].[Invoices]([ClientIdFK]);
GO

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
PRINT '   Password: [Set securely during deployment; no default password is stored in scripts]'
PRINT '3. Create application users and assign appropriate roles'
PRINT '4. Test appointment scheduling and patient form submission workflows'
PRINT '5. Configure backup and maintenance schedules'
PRINT ''

GO

-- ============================================================================================
-- Sync Block: Objects present in modular scripts and required in inline deployment
-- Added: 2026-02-19 17:50:03
-- ============================================================================================

-- [Profile].[StaffDesignations]

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Profile].[StaffDesignations]', N'U') IS NULL

CREATE TABLE [Profile].[StaffDesignations](
    [StaffDesignationId] [uniqueidentifier] NOT NULL,
    [DesignationName] [varchar](100) NOT NULL UNIQUE,
    [Category] [varchar](50) NOT NULL DEFAULT 'Clinical',
    [Description] [varchar](250) NULL,
    [IsActive] [bit] NOT NULL DEFAULT 1,
    [CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
    [CreatedBy] [varchar](250) NULL,
    [UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
    [UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED
(
    [StaffDesignationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

IF OBJECT_ID(N'[Profile].[StaffDesignations]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[StaffDesignations]')
      AND c.name = N'StaffDesignationId'
)
BEGIN
ALTER TABLE [Profile].[StaffDesignations] ADD DEFAULT (newid()) FOR [StaffDesignationId]
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_StaffDesignations_Category')
BEGIN
ALTER TABLE [Profile].[StaffDesignations] WITH CHECK
ADD CONSTRAINT CK_StaffDesignations_Category
CHECK ([Category] IN ('Clinical', 'Administrative', 'Support', 'Management', 'Allied'))
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[StaffDesignations]') AND name = 'IX_StaffDesignations_IsActive')
    CREATE INDEX IX_StaffDesignations_IsActive ON [Profile].[StaffDesignations]([IsActive])
GO

-- [Profile].[ClientDepartments]

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[Profile].[ClientDepartments]', N'U') IS NULL

CREATE TABLE [Profile].[ClientDepartments](
    [ClientDepartmentId] [uniqueidentifier] NOT NULL,
    [ClientIdFK] [uniqueidentifier] NOT NULL,
    [DepartmentCode] [varchar](50) NULL,
    [DepartmentName] [varchar](100) NOT NULL,
    [DepartmentType] [varchar](50) NOT NULL DEFAULT 'Clinical',
    [IsActive] [bit] NOT NULL DEFAULT 1,
    [IsDeleted] [bit] NOT NULL DEFAULT 0,
    [CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
    [CreatedBy] [varchar](250) NULL,
    [UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
    [UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED
(
    [ClientDepartmentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

IF OBJECT_ID(N'[Profile].[ClientDepartments]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[ClientDepartments]')
      AND c.name = N'ClientDepartmentId'
)
BEGIN
ALTER TABLE [Profile].[ClientDepartments] ADD DEFAULT (newid()) FOR [ClientDepartmentId]
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ClientDepartments_DepartmentType')
BEGIN
ALTER TABLE [Profile].[ClientDepartments] WITH CHECK
ADD CONSTRAINT CK_ClientDepartments_DepartmentType
CHECK ([DepartmentType] IN ('Clinical', 'Administrative', 'Support', 'Management', 'Allied'))
END
GO

IF OBJECT_ID(N'[Profile].[ClientDepartments]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[Clients]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[ClientDepartments]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[ClientDepartments]'), N'ClientIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[Clients]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Clients]'), N'ClientId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[ClientDepartments] WITH CHECK ADD FOREIGN KEY([ClientIdFK])
REFERENCES [Profile].[Clients] ([ClientId])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientDepartments]') AND name = 'UX_ClientDepartments_Client_DepartmentName')
    CREATE UNIQUE INDEX UX_ClientDepartments_Client_DepartmentName
    ON [Profile].[ClientDepartments]([ClientIdFK], [DepartmentName])
    WHERE [IsDeleted] = 0
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientDepartments]') AND name = 'IX_ClientDepartments_ClientIdFK')
    CREATE INDEX IX_ClientDepartments_ClientIdFK ON [Profile].[ClientDepartments]([ClientIdFK])
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientDepartments]') AND name = 'IX_ClientDepartments_IsActive')
    CREATE INDEX IX_ClientDepartments_IsActive ON [Profile].[ClientDepartments]([IsActive])
GO

-- [Profile].[ClientStaff] designation and primary department compatibility

IF OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
AND COL_LENGTH('Profile.ClientStaff', 'StaffDesignationIdFK') IS NULL
BEGIN
    ALTER TABLE [Profile].[ClientStaff] ADD [StaffDesignationIdFK] [uniqueidentifier] NULL;
END
GO

IF OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
AND COL_LENGTH('Profile.ClientStaff', 'PrimaryDepartmentIdFK') IS NULL
BEGIN
    ALTER TABLE [Profile].[ClientStaff] ADD [PrimaryDepartmentIdFK] [uniqueidentifier] NULL;
END
GO

IF OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[StaffDesignations]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ClientStaff_StaffDesignation')
BEGIN
    ALTER TABLE [Profile].[ClientStaff] WITH CHECK
    ADD CONSTRAINT [FK_ClientStaff_StaffDesignation]
    FOREIGN KEY([StaffDesignationIdFK]) REFERENCES [Profile].[StaffDesignations]([StaffDesignationId]);
END
GO

IF OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[ClientDepartments]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ClientStaff_PrimaryDepartment')
BEGIN
    ALTER TABLE [Profile].[ClientStaff] WITH CHECK
    ADD CONSTRAINT [FK_ClientStaff_PrimaryDepartment]
    FOREIGN KEY([PrimaryDepartmentIdFK]) REFERENCES [Profile].[ClientDepartments]([ClientDepartmentId]);
END
GO

IF OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
AND COL_LENGTH('Profile.ClientStaff', 'StaffDesignationIdFK') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientStaff]') AND name = 'IX_ClientStaff_StaffDesignationIdFK')
BEGIN
    CREATE INDEX IX_ClientStaff_StaffDesignationIdFK ON [Profile].[ClientStaff]([StaffDesignationIdFK]);
END
GO

IF OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
AND COL_LENGTH('Profile.ClientStaff', 'PrimaryDepartmentIdFK') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientStaff]') AND name = 'IX_ClientStaff_PrimaryDepartmentIdFK')
BEGIN
    CREATE INDEX IX_ClientStaff_PrimaryDepartmentIdFK ON [Profile].[ClientStaff]([PrimaryDepartmentIdFK]);
END
GO

-- [Location].[spGetCountries]

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Location].[spGetCountries]
(
    @CountryId INT = 0,
    @CountryName VARCHAR(250) = ''
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CAST(CountryId AS VARCHAR(250)) AS CountryIDFK,
        CountryName
    FROM Location.Countries
    WHERE (@CountryId = 0 OR CountryId = @CountryId)
      AND (@CountryName = '' OR CountryName LIKE @CountryName + '%')
    ORDER BY CountryName;

    SET NOCOUNT OFF;
END
GO

-- [Location].[spGetCities]

CREATE OR ALTER PROC [Location].[spGetCities]
(
    @CityIDFK INT = 0,
    @CityName VARCHAR(250) = ''
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CAST(CityId AS VARCHAR(250)) AS CityIDFK,
        CityName
    FROM Location.Cities
    WHERE (@CityIDFK = 0 OR CityId = @CityIDFK)
      AND (@CityName = '' OR CityName LIKE @CityName + '%')
    ORDER BY CityName;

    SET NOCOUNT OFF;
END
GO

-- [Location].[spGetProvinces]

CREATE OR ALTER PROC [Location].[spGetProvinces]
(
    @ProvinceId INT = 0,
    @ProvinceName VARCHAR(250) = ''
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CAST(ProvinceId AS VARCHAR(250)) AS ProvinceIDFK,
        ProvinceName
    FROM Location.Provinces
    WHERE (@ProvinceId = 0 OR ProvinceId = @ProvinceId)
      AND (@ProvinceName = '' OR ProvinceName LIKE @ProvinceName + '%')
    ORDER BY ProvinceName;

    SET NOCOUNT OFF;
END
GO

-- [Profile].[spGetGender]

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spGetGender]
(
    @GenderId INT = 0,
    @GenderDescription VARCHAR(250) = ''
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CAST(GenderId AS VARCHAR(250)) AS GenderIDFK,
        GenderDescription
    FROM Profile.Gender
    WHERE (@GenderId = 0 OR GenderId = @GenderId)
      AND (@GenderDescription = '' OR GenderDescription LIKE @GenderDescription + '%')
    ORDER BY GenderDescription;

    SET NOCOUNT OFF;
END
GO

-- [Profile].[spGetMaritalStatus]

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spGetMaritalStatus]
(
    @MaritalStatusId INT = 0,
    @MaritalStatusDescription VARCHAR(250) = ''
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CAST(MaritalStatusId AS VARCHAR(250)) AS MaritalStatusIDFK,
        MaritalStatusDescription
    FROM Profile.MaritalStatus
    WHERE (@MaritalStatusId = 0 OR MaritalStatusId = @MaritalStatusId)
      AND (@MaritalStatusDescription = '' OR MaritalStatusDescription LIKE @MaritalStatusDescription + '%')
    ORDER BY MaritalStatusDescription;

    SET NOCOUNT OFF;
END
GO

-- [Profile].[spAddPatient]

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spAddPatient]
(
    @FirstName VARCHAR(250) = '',
    @LastName VARCHAR(250) = '',
    @ID_Number VARCHAR(250) = '',
    @DateOfBirth DATETIME,
    @GenderIDFK INT = 0,
    @PhoneNumber VARCHAR(250) = '',
    @Email VARCHAR(250) = '',
    @Line1 VARCHAR(250) = '',
    @Line2 VARCHAR(250) = '',
    @CityIDFK INT = 0,
    @ProvinceIDFK INT = 0,
    @CountryIDFK INT = 0,
    @MaritalStatusIDFK INT = 0,
    @EmergencyName VARCHAR(250) = '',
    @EmergencyLastName VARCHAR(250) = '',
    @EmergencyPhoneNumber VARCHAR(250) = '',
    @Relationship VARCHAR(250) = '',
    @EmergancyDateOfBirth DATETIME,
    @MedicationList VARCHAR(MAX) = '',
    @Message VARCHAR(250) OUTPUT,
    @PatientIdOutput UNIQUEIDENTIFIER OUTPUT,
    @StatusCode INT OUTPUT,
    @ClientIdFK UNIQUEIDENTIFIER = NULL
)
AS
BEGIN
    DECLARE @DefaultDate DATETIME = GETDATE(),
            @AddressIDFK UNIQUEIDENTIFIER = NEWID(),
            @EmergencyIDFK UNIQUEIDENTIFIER = NEWID(),
            @PatientId UNIQUEIDENTIFIER = NEWID(),
            @EmailIDFK UNIQUEIDENTIFIER,
            @PhoneIDFK UNIQUEIDENTIFIER,
            @NormalizedPhone VARCHAR(50),
            @NormalizedEmergencyPhone VARCHAR(50),
            @FormattedPhone VARCHAR(15),
            @FormattedEmergencyPhone VARCHAR(15),
            @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME;

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @PatientIdOutput = NULL;
    SET @StatusCode = -1;

    IF LTRIM(RTRIM(@ID_Number)) = ''
    BEGIN
        SET @Message = 'ID number is required.';
        SET @StatusCode = 1;
        RETURN;
    END

    IF LTRIM(RTRIM(@FirstName)) = '' OR LTRIM(RTRIM(@LastName)) = ''
    BEGIN
        SET @Message = 'First name and last name are required.';
        SET @StatusCode = 1;
        RETURN;
    END

    IF @DateOfBirth IS NULL OR @DateOfBirth > GETDATE()
    BEGIN
        SET @Message = 'Invalid date of birth.';
        SET @StatusCode = 1;
        RETURN;
    END

    IF @GenderIDFK <= 0 OR @MaritalStatusIDFK <= 0 OR @CityIDFK <= 0
    BEGIN
        SET @Message = 'Gender, marital status and city are required.';
        SET @StatusCode = 1;
        RETURN;
    END

    IF LTRIM(RTRIM(@Email)) = '' OR @Email NOT LIKE '%_@_%._%'
    BEGIN
        SET @Message = 'A valid email address is required.';
        SET @StatusCode = 1;
        RETURN;
    END

    SET @NormalizedPhone = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@PhoneNumber)), '-', ''), ' ', ''), '+', ''), '(', ''), ')', '');
    SET @NormalizedEmergencyPhone = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@EmergencyPhoneNumber)), '-', ''), ' ', ''), '+', ''), '(', ''), ')', '');

    IF LEN(@NormalizedPhone) <> 10 OR @NormalizedPhone LIKE '%[^0-9]%'
    BEGIN
        SET @Message = 'Phone number must contain exactly 10 digits.';
        SET @StatusCode = 1;
        RETURN;
    END

    IF LEN(@NormalizedEmergencyPhone) <> 10 OR @NormalizedEmergencyPhone LIKE '%[^0-9]%'
    BEGIN
        SET @Message = 'Emergency phone number must contain exactly 10 digits.';
        SET @StatusCode = 1;
        RETURN;
    END

    IF @ProvinceIDFK > 0
    BEGIN
        IF NOT EXISTS
        (
            SELECT 1
            FROM Location.Cities C
            WHERE C.CityId = @CityIDFK
              AND C.ProvinceIDFK = @ProvinceIDFK
        )
        BEGIN
            SET @Message = 'City and province combination is invalid.';
            SET @StatusCode = 1;
            RETURN;
        END
    END

    IF @CountryIDFK > 0
    BEGIN
        IF NOT EXISTS
        (
            SELECT 1
            FROM Location.Cities C
            INNER JOIN Location.Provinces P ON P.ProvinceId = C.ProvinceIDFK
            WHERE C.CityId = @CityIDFK
              AND P.CountryIDFK = @CountryIDFK
        )
        BEGIN
            SET @Message = 'City and country combination is invalid.';
            SET @StatusCode = 1;
            RETURN;
        END
    END

    IF @ClientIdFK IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Profile.Clients WHERE ClientId = @ClientIdFK AND IsDeleted = 0)
    BEGIN
        SET @Message = 'Invalid ClientIdFK.';
        SET @StatusCode = 1;
        RETURN;
    END

    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
        BEGIN TRAN;

        IF EXISTS(SELECT 1 FROM Profile.Patient WITH (UPDLOCK, HOLDLOCK) WHERE ID_Number = @ID_Number AND IsDeleted = 0)
        BEGIN
            SET @Message = 'Sorry User ID Number: "' + @ID_Number + '" already exists, please validate and try again';
            SET @StatusCode = 2;
            ROLLBACK TRAN;
            SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
            RETURN;
        END

        SET @FormattedPhone =
            SUBSTRING(@NormalizedPhone, 1, 3) + '-' +
            SUBSTRING(@NormalizedPhone, 4, 3) + '-' +
            SUBSTRING(@NormalizedPhone, 7, 4);

        SET @FormattedEmergencyPhone =
            SUBSTRING(@NormalizedEmergencyPhone, 1, 3) + '-' +
            SUBSTRING(@NormalizedEmergencyPhone, 4, 3) + '-' +
            SUBSTRING(@NormalizedEmergencyPhone, 7, 4);

        SELECT @EmailIDFK = E.EmailId
        FROM Contacts.Emails E WITH (UPDLOCK, HOLDLOCK)
        WHERE E.Email = @Email;

        IF @EmailIDFK IS NULL
        BEGIN
            SET @EmailIDFK = NEWID();
            INSERT INTO Contacts.Emails (EmailId, Email, IsActive, UpdateDate)
            VALUES (@EmailIDFK, @Email, 1, @DefaultDate);
        END

        SELECT @PhoneIDFK = P.PhoneId
        FROM Contacts.Phones P WITH (UPDLOCK, HOLDLOCK)
        WHERE P.PhoneNumber = @FormattedPhone;

        IF @PhoneIDFK IS NULL
        BEGIN
            SET @PhoneIDFK = NEWID();
            INSERT INTO Contacts.Phones (PhoneId, PhoneNumber, IsActive, UpdateDate)
            VALUES (@PhoneIDFK, @FormattedPhone, 1, @DefaultDate);
        END

        INSERT INTO Location.Address (AddressId, Line1, Line2, CityIDFK, UpdateDate)
        VALUES (@AddressIDFK, @Line1, @Line2, @CityIDFK, @DefaultDate);

        INSERT INTO Contacts.EmergencyContacts
        (
            EmergencyId,
            FirstName,
            LastName,
            PhoneNumber,
            Relationship,
            DateOfBirth,
            IsActive,
            UpdateDate
        )
        VALUES
        (
            @EmergencyIDFK,
            @EmergencyName,
            @EmergencyLastName,
            @FormattedEmergencyPhone,
            @Relationship,
            @EmergancyDateOfBirth,
            1,
            @DefaultDate
        );

        INSERT INTO Profile.Patient
        (
            PatientId,
            FirstName,
            LastName,
            ID_Number,
            DateOfBirth,
            GenderIDFK,
            MedicationList,
            ClientIdFK,
            AddressIDFK,
            MaritalStatusIDFK,
            EmergencyIDFK
        )
        VALUES
        (
            @PatientId,
            @FirstName,
            @LastName,
            @ID_Number,
            @DateOfBirth,
            @GenderIDFK,
            @MedicationList,
            @ClientIdFK,
            @AddressIDFK,
            @MaritalStatusIDFK,
            @EmergencyIDFK
        );

        INSERT INTO Contacts.PatientEmails (PatientEmailId, PatientIdFK, EmailIdFK, IsPrimary, EmailType)
        VALUES (NEWID(), @PatientId, @EmailIDFK, 1, 'Primary');

        INSERT INTO Contacts.PatientPhones (PatientPhoneId, PatientIdFK, PhoneIdFK, IsPrimary, PhoneType)
        VALUES (NEWID(), @PatientId, @PhoneIDFK, 1, 'Primary');

        COMMIT TRAN;
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

        SET @PatientIdOutput = @PatientId;
        SET @StatusCode = 0;
        SET @Message = '';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName,
                        ErrorSchema,
                        ErrorProcedure,
                        ErrorNumber,
                        ErrorState,
                        ErrorSeverity,
                        ErrorLine,
                        ErrorMessage,
                        ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName,
                        @ErrorSchema,
                        @ErrorProc,
                        @ErrorNumber,
                        @ErrorState,
                        @ErrorSeverity,
                        @ErrorLine,
                        LEFT(@ErrorMessage, 500),
                        @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName,
                ErrorSchema,
                ErrorProcedure,
                ErrorNumber,
                ErrorState,
                ErrorSeverity,
                ErrorLine,
                ErrorMessage,
                ErrorDateTime
            )
            VALUES
            (
                @UserName,
                @ErrorSchema,
                @ErrorProc,
                @ErrorNumber,
                @ErrorState,
                @ErrorSeverity,
                @ErrorLine,
                LEFT(@ErrorMessage, 500),
                @ErrorDateTime
            );
        END

        IF @ErrorNumber IN (2601, 2627)
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'A duplicate patient, email or phone record was detected. Please verify input and try again.';
        END
        ELSE
        BEGIN
            SET @StatusCode = -1;
            SET @Message = 'Failed to add patient record.';
        END
    END CATCH

    SET NOCOUNT OFF;
END
GO

-- [Profile].[spGetPatient]

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spGetPatient]
(
    @PatientId UNIQUEIDENTIFIER = NULL,
    @IDNumber VARCHAR(250) = '',
    @IncludeDeleted BIT = 0,
    @FirstName VARCHAR(250) OUTPUT,
    @LastName VARCHAR(250) OUTPUT,
    @ID_Number VARCHAR(250) OUTPUT,
    @DateOfBirth DATETIME OUTPUT,
    @GenderIDFK INT OUTPUT,
    @PhoneNumber VARCHAR(250) OUTPUT,
    @Email VARCHAR(250) OUTPUT,
    @Line1 VARCHAR(250) OUTPUT,
    @Line2 VARCHAR(250) OUTPUT,
    @CityIDFK INT OUTPUT,
    @ProvinceIDFK INT OUTPUT,
    @CountryIDFK INT OUTPUT,
    @MaritalStatusIDFK INT OUTPUT,
    @MedicationList VARCHAR(MAX) OUTPUT,
    @EmergencyName VARCHAR(250) OUTPUT,
    @EmergencyLastName VARCHAR(250) OUTPUT,
    @EmergencyPhoneNumber VARCHAR(250) OUTPUT,
    @Relationship VARCHAR(250) OUTPUT,
    @EmergancyDateOfBirth DATETIME OUTPUT,
    @Message VARCHAR(250) OUTPUT,
    @ClientIdFK UNIQUEIDENTIFIER = NULL OUTPUT
)
AS
BEGIN
    DECLARE @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME;

	    SET NOCOUNT ON;

	    BEGIN TRY
            SET @FirstName = '';
            SET @LastName = '';
            SET @ID_Number = '';
            SET @ClientIdFK = NULL;
            SET @DateOfBirth = GETDATE();
            SET @GenderIDFK = 0;
            SET @PhoneNumber = '';
            SET @Email = '';
            SET @Line1 = '';
            SET @Line2 = '';
            SET @CityIDFK = 0;
            SET @ProvinceIDFK = 0;
            SET @CountryIDFK = 0;
            SET @MaritalStatusIDFK = 0;
            SET @MedicationList = '';
            SET @EmergencyName = '';
            SET @EmergencyLastName = '';
            SET @EmergencyPhoneNumber = '';
            SET @Relationship = '';
            SET @EmergancyDateOfBirth = GETDATE();
            SET @Message = '';

            IF @PatientId IS NULL AND LTRIM(RTRIM(@IDNumber)) = ''
            BEGIN
                SET @Message = 'PatientId or IDNumber is required.';
                RETURN;
            END

	        IF EXISTS
            (
                SELECT 1
                FROM Profile.Patient PP
                WHERE
                    (
                        (@PatientId IS NOT NULL AND PP.PatientId = @PatientId)
                        OR
                        (@PatientId IS NULL AND PP.ID_Number = @IDNumber)
                    )
                    AND (@IncludeDeleted = 1 OR PP.IsDeleted = 0)
            )
	        BEGIN
	            SELECT
                @FirstName = PP.FirstName,
                @LastName = PP.LastName,
                @ID_Number = PP.ID_Number,
                @ClientIdFK = PP.ClientIdFK,
                @DateOfBirth = PP.DateOfBirth,
                @GenderIDFK = PP.GenderIDFK,
                @PhoneNumber = CP.PhoneNumber,
                @Email = CE.Email,
                @Line1 = LA.Line1,
                @Line2 = LA.Line2,
                @CityIDFK = LC.CityId,
                @ProvinceIDFK = LP.ProvinceId,
                @CountryIDFK = LCO.CountryId,
                @MaritalStatusIDFK = PP.MaritalStatusIDFK,
                @MedicationList = PP.MedicationList,
                @EmergencyName = CEC.FirstName,
                @EmergencyLastName = CEC.LastName,
                @EmergencyPhoneNumber = CEC.PhoneNumber,
                @Relationship = CEC.Relationship,
                @EmergancyDateOfBirth = CEC.DateOfBirth
            FROM Profile.Patient AS PP
            LEFT JOIN Location.Address AS LA ON PP.AddressIDFK = LA.AddressId
            LEFT JOIN Location.Cities AS LC ON LA.CityIDFK = LC.CityId
            LEFT JOIN Location.Provinces AS LP ON LC.ProvinceIDFK = LP.ProvinceId
            LEFT JOIN Location.Countries AS LCO ON LP.CountryIDFK = LCO.CountryId
            LEFT JOIN Contacts.EmergencyContacts AS CEC ON PP.EmergencyIDFK = CEC.EmergencyId
            OUTER APPLY
            (
                SELECT TOP (1) PE.EmailIdFK
                FROM Contacts.PatientEmails PE
                WHERE PE.PatientIdFK = PP.PatientId
                ORDER BY PE.IsPrimary DESC, PE.CreatedDate DESC
            ) PE
            LEFT JOIN Contacts.Emails CE ON CE.EmailId = PE.EmailIdFK
            OUTER APPLY
            (
                SELECT TOP (1) PPX.PhoneIdFK
                FROM Contacts.PatientPhones PPX
                WHERE PPX.PatientIdFK = PP.PatientId
                ORDER BY PPX.IsPrimary DESC, PPX.CreatedDate DESC
            ) PH
	            LEFT JOIN Contacts.Phones CP ON CP.PhoneId = PH.PhoneIdFK
	            WHERE
                    (
                        (@PatientId IS NOT NULL AND PP.PatientId = @PatientId)
                        OR
                        (@PatientId IS NULL AND PP.ID_Number = @IDNumber)
                    )
                    AND (@IncludeDeleted = 1 OR PP.IsDeleted = 0);

	            SET @Message = '';
	        END
	        ELSE
	        BEGIN
                IF @PatientId IS NOT NULL
                    SET @Message = 'PatientId does not exist or is soft deleted.';
                ELSE
	                SET @Message = 'ID number does not exist or is soft deleted.';
	        END
	    END TRY
    BEGIN CATCH
        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName,
                        ErrorSchema,
                        ErrorProcedure,
                        ErrorNumber,
                        ErrorState,
                        ErrorSeverity,
                        ErrorLine,
                        ErrorMessage,
                        ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName,
                        @ErrorSchema,
                        @ErrorProc,
                        @ErrorNumber,
                        @ErrorState,
                        @ErrorSeverity,
                        @ErrorLine,
                        LEFT(@ErrorMessage, 500),
                        @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName,
                ErrorSchema,
                ErrorProcedure,
                ErrorNumber,
                ErrorState,
                ErrorSeverity,
                ErrorLine,
                ErrorMessage,
                ErrorDateTime
            )
            VALUES
            (
                @UserName,
                @ErrorSchema,
                @ErrorProc,
                @ErrorNumber,
                @ErrorState,
                @ErrorSeverity,
                @ErrorLine,
                LEFT(@ErrorMessage, 500),
                @ErrorDateTime
            );
        END

        SET @Message = 'Failed to retrieve patient record.';
    END CATCH

    SET NOCOUNT OFF;
END
GO

-- [Profile].[spUpdatePatient]

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spUpdatePatient]
(
    @FirstName VARCHAR(250) = '',
    @LastName VARCHAR(250) = '',
    @ID_Number VARCHAR(250) = '',
    @DateOfBirth DATETIME = NULL,
    @GenderIDFK INT = 0,
    @PhoneNumber VARCHAR(250) = '',
    @Email VARCHAR(250) = '',
    @Line1 VARCHAR(250) = '',
    @Line2 VARCHAR(250) = '',
    @CityIDFK INT = 0,
    @ProvinceIDFK INT = 0,
    @CountryIDFK INT = 0,
    @MaritalStatusIDFK INT = 0,
    @MedicationList VARCHAR(MAX) = '',
    @EmergencyName VARCHAR(250) = '',
    @EmergencyLastName VARCHAR(250) = '',
    @EmergencyPhoneNumber VARCHAR(250) = '',
    @Relationship VARCHAR(250) = '',
    @EmergancyDateOfBirth DATETIME = NULL,
    @Message VARCHAR(250) OUTPUT,
    @ClientIdFK UNIQUEIDENTIFIER = NULL
)
AS
BEGIN
    DECLARE @DefaultDate DATETIME = GETDATE(),
            @PatientId UNIQUEIDENTIFIER,
            @AddressId UNIQUEIDENTIFIER,
            @EmergencyId UNIQUEIDENTIFIER,
            @EmailId UNIQUEIDENTIFIER,
            @PhoneId UNIQUEIDENTIFIER,
            @NormalizedPhone VARCHAR(50),
            @NormalizedEmergencyPhone VARCHAR(50),
            @FormattedPhone VARCHAR(15),
            @FormattedEmergencyPhone VARCHAR(15),
            @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME;

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Validation parity with spAddPatient
    IF LTRIM(RTRIM(@ID_Number)) = ''
    BEGIN
        SET @Message = 'ID number is required.';
        RETURN;
    END

    IF LTRIM(RTRIM(@FirstName)) = '' OR LTRIM(RTRIM(@LastName)) = ''
    BEGIN
        SET @Message = 'First name and last name are required.';
        RETURN;
    END

    IF @DateOfBirth IS NULL OR @DateOfBirth > GETDATE()
    BEGIN
        SET @Message = 'Invalid date of birth.';
        RETURN;
    END

    IF @EmergancyDateOfBirth IS NULL OR @EmergancyDateOfBirth > GETDATE()
    BEGIN
        SET @Message = 'Invalid emergency contact date of birth.';
        RETURN;
    END

    IF @GenderIDFK <= 0 OR @MaritalStatusIDFK <= 0 OR @CityIDFK <= 0
    BEGIN
        SET @Message = 'Gender, marital status and city are required.';
        RETURN;
    END

    IF LTRIM(RTRIM(@Email)) = '' OR @Email NOT LIKE '%_@_%._%'
    BEGIN
        SET @Message = 'A valid email address is required.';
        RETURN;
    END

    SET @NormalizedPhone = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@PhoneNumber)), '-', ''), ' ', ''), '+', ''), '(', ''), ')', '');
    SET @NormalizedEmergencyPhone = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@EmergencyPhoneNumber)), '-', ''), ' ', ''), '+', ''), '(', ''), ')', '');

    IF LEN(@NormalizedPhone) <> 10 OR @NormalizedPhone LIKE '%[^0-9]%'
    BEGIN
        SET @Message = 'Phone number must contain exactly 10 digits.';
        RETURN;
    END

    IF LEN(@NormalizedEmergencyPhone) <> 10 OR @NormalizedEmergencyPhone LIKE '%[^0-9]%'
    BEGIN
        SET @Message = 'Emergency phone number must contain exactly 10 digits.';
        RETURN;
    END

    IF @ProvinceIDFK > 0
    BEGIN
        IF NOT EXISTS
        (
            SELECT 1
            FROM Location.Cities C
            WHERE C.CityId = @CityIDFK
              AND C.ProvinceIDFK = @ProvinceIDFK
        )
        BEGIN
            SET @Message = 'City and province combination is invalid.';
            RETURN;
        END
    END

    IF @CountryIDFK > 0
    BEGIN
        IF NOT EXISTS
        (
            SELECT 1
            FROM Location.Cities C
            INNER JOIN Location.Provinces P ON P.ProvinceId = C.ProvinceIDFK
            WHERE C.CityId = @CityIDFK
              AND P.CountryIDFK = @CountryIDFK
        )
        BEGIN
            SET @Message = 'City and country combination is invalid.';
            RETURN;
        END
    END

    IF @ClientIdFK IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Profile.Clients WHERE ClientId = @ClientIdFK AND IsDeleted = 0)
    BEGIN
        SET @Message = 'Invalid ClientIdFK.';
        RETURN;
    END

    BEGIN TRY
        BEGIN TRAN;

        SELECT
            @PatientId = PatientId,
            @AddressId = AddressIDFK,
            @EmergencyId = EmergencyIDFK
        FROM Profile.Patient
        WHERE ID_Number = @ID_Number
          AND IsDeleted = 0;

        IF @PatientId IS NULL
        BEGIN
            SET @Message = 'Sorry User [' + @ID_Number + '] does not exist, please verify and try again';
            ROLLBACK TRAN;
            RETURN;
        END

        SET @FormattedPhone =
            SUBSTRING(@NormalizedPhone, 1, 3) + '-' +
            SUBSTRING(@NormalizedPhone, 4, 3) + '-' +
            SUBSTRING(@NormalizedPhone, 7, 4);

        SET @FormattedEmergencyPhone =
            SUBSTRING(@NormalizedEmergencyPhone, 1, 3) + '-' +
            SUBSTRING(@NormalizedEmergencyPhone, 4, 3) + '-' +
            SUBSTRING(@NormalizedEmergencyPhone, 7, 4);

        IF @AddressId IS NULL
        BEGIN
            SET @AddressId = NEWID();
            INSERT INTO Location.Address (AddressId, Line1, Line2, CityIDFK, UpdateDate)
            VALUES (@AddressId, @Line1, @Line2, @CityIDFK, @DefaultDate);
        END
        ELSE
        BEGIN
            UPDATE Location.Address
            SET Line1 = @Line1,
                Line2 = @Line2,
                CityIDFK = @CityIDFK,
                UpdateDate = @DefaultDate,
                UpdatedBy = SUSER_SNAME()
            WHERE AddressId = @AddressId;
        END

        IF @EmergencyId IS NULL
        BEGIN
            SET @EmergencyId = NEWID();
            INSERT INTO Contacts.EmergencyContacts
            (
                EmergencyId,
                FirstName,
                LastName,
                PhoneNumber,
                Relationship,
                DateOfBirth,
                IsActive,
                UpdateDate
            )
            VALUES
            (
                @EmergencyId,
                @EmergencyName,
                @EmergencyLastName,
                @FormattedEmergencyPhone,
                @Relationship,
                @EmergancyDateOfBirth,
                1,
                @DefaultDate
            );
        END
        ELSE
        BEGIN
            UPDATE Contacts.EmergencyContacts
            SET FirstName = @EmergencyName,
                LastName = @EmergencyLastName,
                PhoneNumber = @FormattedEmergencyPhone,
                Relationship = @Relationship,
                DateOfBirth = @EmergancyDateOfBirth,
                UpdateDate = @DefaultDate
            WHERE EmergencyId = @EmergencyId;
        END

        SELECT @EmailId = E.EmailId FROM Contacts.Emails E WHERE E.Email = @Email;
        IF @EmailId IS NULL
        BEGIN
            SET @EmailId = NEWID();
            INSERT INTO Contacts.Emails (EmailId, Email, IsActive, UpdateDate)
            VALUES (@EmailId, @Email, 1, @DefaultDate);
        END

        SELECT @PhoneId = P.PhoneId FROM Contacts.Phones P WHERE P.PhoneNumber = @FormattedPhone;
        IF @PhoneId IS NULL
        BEGIN
            SET @PhoneId = NEWID();
            INSERT INTO Contacts.Phones (PhoneId, PhoneNumber, IsActive, UpdateDate)
            VALUES (@PhoneId, @FormattedPhone, 1, @DefaultDate);
        END

        IF NOT EXISTS (SELECT 1 FROM Contacts.PatientEmails WHERE PatientIdFK = @PatientId AND EmailIdFK = @EmailId)
        BEGIN
            INSERT INTO Contacts.PatientEmails (PatientEmailId, PatientIdFK, EmailIdFK, IsPrimary, EmailType)
            VALUES (NEWID(), @PatientId, @EmailId, 1, 'Primary');
        END

        UPDATE Contacts.PatientEmails
        SET IsPrimary = CASE WHEN EmailIdFK = @EmailId THEN 1 ELSE 0 END,
            UpdatedDate = @DefaultDate,
            UpdatedBy = SUSER_SNAME()
        WHERE PatientIdFK = @PatientId;

        IF NOT EXISTS (SELECT 1 FROM Contacts.PatientPhones WHERE PatientIdFK = @PatientId AND PhoneIdFK = @PhoneId)
        BEGIN
            INSERT INTO Contacts.PatientPhones (PatientPhoneId, PatientIdFK, PhoneIdFK, IsPrimary, PhoneType)
            VALUES (NEWID(), @PatientId, @PhoneId, 1, 'Primary');
        END

        UPDATE Contacts.PatientPhones
        SET IsPrimary = CASE WHEN PhoneIdFK = @PhoneId THEN 1 ELSE 0 END,
            UpdatedDate = @DefaultDate,
            UpdatedBy = SUSER_SNAME()
        WHERE PatientIdFK = @PatientId;

        UPDATE Profile.Patient
        SET FirstName = @FirstName,
            LastName = @LastName,
            DateOfBirth = @DateOfBirth,
            GenderIDFK = @GenderIDFK,
            MedicationList = @MedicationList,
            ClientIdFK = COALESCE(@ClientIdFK, ClientIdFK),
            AddressIDFK = @AddressId,
            MaritalStatusIDFK = @MaritalStatusIDFK,
            EmergencyIDFK = @EmergencyId,
            UpdatedDate = @DefaultDate,
            UpdatedBy = SUSER_SNAME()
        WHERE PatientId = @PatientId;

        COMMIT TRAN;
        SET @Message = '';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName,
                        ErrorSchema,
                        ErrorProcedure,
                        ErrorNumber,
                        ErrorState,
                        ErrorSeverity,
                        ErrorLine,
                        ErrorMessage,
                        ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName,
                        @ErrorSchema,
                        @ErrorProc,
                        @ErrorNumber,
                        @ErrorState,
                        @ErrorSeverity,
                        @ErrorLine,
                        LEFT(@ErrorMessage, 500),
                        @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName,
                ErrorSchema,
                ErrorProcedure,
                ErrorNumber,
                ErrorState,
                ErrorSeverity,
                ErrorLine,
                ErrorMessage,
                ErrorDateTime
            )
            VALUES
            (
                @UserName,
                @ErrorSchema,
                @ErrorProc,
                @ErrorNumber,
                @ErrorState,
                @ErrorSeverity,
                @ErrorLine,
                LEFT(@ErrorMessage, 500),
                @ErrorDateTime
            );
        END

        SET @Message = 'Failed to update patient record.';
    END CATCH

    SET NOCOUNT OFF;
END
GO

-- [Profile].[spDeletePatient]

CREATE OR ALTER PROC [Profile].[spDeletePatient]
(
    @IDNumber VARCHAR(250) = '',
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME;

    SET NOCOUNT ON;

    BEGIN TRY
        IF LTRIM(RTRIM(@IDNumber)) = ''
        BEGIN
            SET @Message = 'ID number is required.';
            RETURN;
        END

        IF EXISTS(SELECT 1 FROM Profile.Patient WHERE ID_Number = @IDNumber AND IsDeleted = 0)
        BEGIN
            UPDATE Profile.Patient
            SET IsDeleted = 1,
                UpdatedDate = GETDATE(),
                UpdatedBy = SUSER_SNAME()
            WHERE ID_Number = @IDNumber
              AND IsDeleted = 0;

            SET @Message = '';
        END
        ELSE
        BEGIN
            SET @Message = 'Sorry User ID:(' + @IDNumber + ') does not exist or is already deleted. Please verify and try again';
        END
    END TRY
    BEGIN CATCH
        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName,
                        ErrorSchema,
                        ErrorProcedure,
                        ErrorNumber,
                        ErrorState,
                        ErrorSeverity,
                        ErrorLine,
                        ErrorMessage,
                        ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName,
                        @ErrorSchema,
                        @ErrorProc,
                        @ErrorNumber,
                        @ErrorState,
                        @ErrorSeverity,
                        @ErrorLine,
                        LEFT(@ErrorMessage, 500),
                        @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName,
                ErrorSchema,
                ErrorProcedure,
                ErrorNumber,
                ErrorState,
                ErrorSeverity,
                ErrorLine,
                ErrorMessage,
                ErrorDateTime
            )
            VALUES
            (
                @UserName,
                @ErrorSchema,
                @ErrorProc,
                @ErrorNumber,
                @ErrorState,
                @ErrorSeverity,
                @ErrorLine,
                LEFT(@ErrorMessage, 500),
                @ErrorDateTime
            );
        END

        SET @Message = 'Failed to delete patient record.';
    END CATCH

    SET NOCOUNT OFF;
END
GO

-- ============================================================================================

-- ============================================================================================
-- ============================================================================================
-- Canonical Folder-Order Mirror (Normalized)
-- NOTE: Table and schema replay section removed to prevent duplicate CREATE TABLE/INDEX failures.
-- Kept canonical stored procedure and trigger definitions below.
-- ============================================================================================
-- BEGIN FILE: 006-stored-procedures/Location.spGetCities.sql

CREATE OR ALTER PROC [Location].[spGetCities]
(
    @CityIDFK INT = 0,
    @CityName VARCHAR(250) = ''
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CAST(CityId AS VARCHAR(250)) AS CityIDFK,
        CityName
    FROM Location.Cities
    WHERE (@CityIDFK = 0 OR CityId = @CityIDFK)
      AND (@CityName = '' OR CityName LIKE @CityName + '%')
    ORDER BY CityName;

    SET NOCOUNT OFF;
END
GO
-- END FILE: 006-stored-procedures/Location.spGetCities.sql


-- BEGIN FILE: 006-stored-procedures/Location.spGetProvinces.sql

CREATE OR ALTER PROC [Location].[spGetProvinces]
(
    @ProvinceId INT = 0,
    @ProvinceName VARCHAR(250) = ''
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CAST(ProvinceId AS VARCHAR(250)) AS ProvinceIDFK,
        ProvinceName
    FROM Location.Provinces
    WHERE (@ProvinceId = 0 OR ProvinceId = @ProvinceId)
      AND (@ProvinceName = '' OR ProvinceName LIKE @ProvinceName + '%')
    ORDER BY ProvinceName;

    SET NOCOUNT OFF;
END
GO
-- END FILE: 006-stored-procedures/Location.spGetProvinces.sql


-- BEGIN FILE: 006-stored-procedures/Profile.spDeletePatient.sql

CREATE OR ALTER PROC [Profile].[spDeletePatient]
(
    @IDNumber VARCHAR(250) = '',
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME;

    SET NOCOUNT ON;

    BEGIN TRY
        IF LTRIM(RTRIM(@IDNumber)) = ''
        BEGIN
            SET @Message = 'ID number is required.';
            RETURN;
        END

        IF EXISTS(SELECT 1 FROM Profile.Patient WHERE ID_Number = @IDNumber AND IsDeleted = 0)
        BEGIN
            UPDATE Profile.Patient
            SET IsDeleted = 1,
                UpdatedDate = GETDATE(),
                UpdatedBy = SUSER_SNAME()
            WHERE ID_Number = @IDNumber
              AND IsDeleted = 0;

            SET @Message = '';
        END
        ELSE
        BEGIN
            SET @Message = 'Sorry User ID:(' + @IDNumber + ') does not exist or is already deleted. Please verify and try again';
        END
    END TRY
    BEGIN CATCH
        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName,
                        ErrorSchema,
                        ErrorProcedure,
                        ErrorNumber,
                        ErrorState,
                        ErrorSeverity,
                        ErrorLine,
                        ErrorMessage,
                        ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName,
                        @ErrorSchema,
                        @ErrorProc,
                        @ErrorNumber,
                        @ErrorState,
                        @ErrorSeverity,
                        @ErrorLine,
                        LEFT(@ErrorMessage, 500),
                        @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName,
                ErrorSchema,
                ErrorProcedure,
                ErrorNumber,
                ErrorState,
                ErrorSeverity,
                ErrorLine,
                ErrorMessage,
                ErrorDateTime
            )
            VALUES
            (
                @UserName,
                @ErrorSchema,
                @ErrorProc,
                @ErrorNumber,
                @ErrorState,
                @ErrorSeverity,
                @ErrorLine,
                LEFT(@ErrorMessage, 500),
                @ErrorDateTime
            );
        END

        SET @Message = 'Failed to delete patient record.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
-- END FILE: 006-stored-procedures/Profile.spDeletePatient.sql


-- BEGIN FILE: 006-stored-procedures/Profile.spGetGender.sql

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spGetGender]
(
    @GenderId INT = 0,
    @GenderDescription VARCHAR(250) = ''
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CAST(GenderId AS VARCHAR(250)) AS GenderIDFK,
        GenderDescription
    FROM Profile.Gender
    WHERE (@GenderId = 0 OR GenderId = @GenderId)
      AND (@GenderDescription = '' OR GenderDescription LIKE @GenderDescription + '%')
    ORDER BY GenderDescription;

    SET NOCOUNT OFF;
END
GO
-- END FILE: 006-stored-procedures/Profile.spGetGender.sql


-- BEGIN FILE: 006-stored-procedures/[Exceptions].[spErrorHandling].sql

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Exceptions].[spErrorHandling]
(
    @UserName VARCHAR(200),
    @ErrorSchema VARCHAR(200),
    @ErrorProc VARCHAR(200),
    @ErrorNumber INT,
    @ErrorState INT,
    @ErrorSeverity INT,
    @ErrorLine INT,
    @ErrorMessage VARCHAR(MAX),
    @ErrorDateTime DATETIME
)
AS
BEGIN
    INSERT INTO Exceptions.Errors
    (
        UserName,
        ErrorSchema,
        ErrorProcedure,
        ErrorNumber,
        ErrorState,
        ErrorSeverity,
        ErrorLine,
        ErrorMessage,
        ErrorDateTime
    )
    VALUES
    (
        @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber, @ErrorState,
        @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
    );
END
GO
-- END FILE: 006-stored-procedures/[Exceptions].[spErrorHandling].sql


-- BEGIN FILE: 006-stored-procedures/[Location].[spGetCountries].sql

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Location].[spGetCountries]
(
    @CountryId INT = 0,
    @CountryName VARCHAR(250) = ''
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CAST(CountryId AS VARCHAR(250)) AS CountryIDFK,
        CountryName
    FROM Location.Countries
    WHERE (@CountryId = 0 OR CountryId = @CountryId)
      AND (@CountryName = '' OR CountryName LIKE @CountryName + '%')
    ORDER BY CountryName;

    SET NOCOUNT OFF;
END
GO
-- END FILE: 006-stored-procedures/[Location].[spGetCountries].sql


-- BEGIN FILE: 006-stored-procedures/[Profile].[spAddClientDepartment].sql

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spAddClientDepartment]
(
    @ClientIdFK UNIQUEIDENTIFIER,
    @DepartmentName VARCHAR(100),
    @DepartmentCode VARCHAR(50) = NULL,
    @DepartmentType VARCHAR(50) = 'Clinical',
    @CreatedBy VARCHAR(250) = NULL,
    @ClientDepartmentIdOutput UNIQUEIDENTIFIER OUTPUT,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE(),
            @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME;

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @ClientDepartmentIdOutput = NULL;
    SET @StatusCode = -1;
    SET @Message = '';

    IF @ClientIdFK IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientIdFK is required.';
        RETURN;
    END

    IF LTRIM(RTRIM(ISNULL(@DepartmentName, ''))) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'DepartmentName is required.';
        RETURN;
    END

    IF @DepartmentType NOT IN ('Clinical', 'Administrative', 'Support', 'Management', 'Allied')
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Invalid DepartmentType.';
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Profile.Clients WHERE ClientId = @ClientIdFK AND IsDeleted = 0)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Client does not exist or is deleted.';
        RETURN;
    END

    BEGIN TRY
        IF EXISTS
        (
            SELECT 1
            FROM Profile.ClientDepartments
            WHERE ClientIdFK = @ClientIdFK
              AND DepartmentName = LTRIM(RTRIM(@DepartmentName))
              AND IsDeleted = 0
        )
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'Department already exists for this client.';
            RETURN;
        END

        SET @ClientDepartmentIdOutput = NEWID();

        INSERT INTO Profile.ClientDepartments
        (
            ClientDepartmentId,
            ClientIdFK,
            DepartmentCode,
            DepartmentName,
            DepartmentType,
            IsActive,
            IsDeleted,
            CreatedDate,
            CreatedBy,
            UpdatedDate,
            UpdatedBy
        )
        VALUES
        (
            @ClientDepartmentIdOutput,
            @ClientIdFK,
            NULLIF(LTRIM(RTRIM(ISNULL(@DepartmentCode, ''))), ''),
            LTRIM(RTRIM(@DepartmentName)),
            @DepartmentType,
            1,
            0,
            @Now,
            COALESCE(NULLIF(@CreatedBy, ''), SUSER_SNAME()),
            @Now,
            COALESCE(NULLIF(@CreatedBy, ''), SUSER_SNAME())
        );

        SET @StatusCode = 0;
        SET @Message = '';
    END TRY
    BEGIN CATCH
        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                        ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                        @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
            )
            VALUES
            (
                @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
            );
        END

        SET @ClientDepartmentIdOutput = NULL;
        SET @StatusCode = -1;
        SET @Message = 'Failed to add client department.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
-- END FILE: 006-stored-procedures/[Profile].[spAddClientDepartment].sql


-- BEGIN FILE: 006-stored-procedures/[Profile].[spAddClientStaff].sql

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spAddClientStaff]
(
    @ClientIdFK UNIQUEIDENTIFIER,
    @RoleIdFK UNIQUEIDENTIFIER = NULL,
    @UserIdFK UNIQUEIDENTIFIER = NULL,
    @ProviderIdFK UNIQUEIDENTIFIER = NULL,
    @StaffCode VARCHAR(50),
    @FirstName VARCHAR(250),
    @LastName VARCHAR(250),
    @Email VARCHAR(250) = NULL,
    @PhoneNumber VARCHAR(25) = NULL,
    @JobTitle VARCHAR(150) = NULL,
    @Department VARCHAR(100) = NULL,
    @StaffType VARCHAR(50) = 'Administrative',
    @EmploymentType VARCHAR(50) = 'Full-Time',
    @HireDate DATETIME = NULL,
    @IsPrimaryContact BIT = 0,
    @CreatedBy VARCHAR(250) = NULL,
    @StaffDesignationIdFK UNIQUEIDENTIFIER = NULL,
    @PrimaryDepartmentIdFK UNIQUEIDENTIFIER = NULL,
    @ClientStaffIdOutput UNIQUEIDENTIFIER OUTPUT,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE(),
            @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME,
            @NormalizedPhone VARCHAR(25),
            @FormattedPhone VARCHAR(25);

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @ClientStaffIdOutput = NULL;
    SET @StatusCode = -1;
    SET @Message = '';

    IF @ClientIdFK IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientIdFK is required.';
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Profile.Clients WHERE ClientId = @ClientIdFK AND IsDeleted = 0)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Client does not exist or is deleted.';
        RETURN;
    END

    IF LTRIM(RTRIM(ISNULL(@StaffCode, ''))) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'StaffCode is required.';
        RETURN;
    END

    IF LTRIM(RTRIM(ISNULL(@FirstName, ''))) = '' OR LTRIM(RTRIM(ISNULL(@LastName, ''))) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'FirstName and LastName are required.';
        RETURN;
    END

    IF @RoleIdFK IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Auth.Roles WHERE RoleId = @RoleIdFK)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'RoleIdFK does not exist.';
        RETURN;
    END

    IF @UserIdFK IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Auth.Users WHERE UserId = @UserIdFK)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'UserIdFK does not exist.';
        RETURN;
    END

    IF @ProviderIdFK IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Profile.HealthcareProviders WHERE ProviderId = @ProviderIdFK)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ProviderIdFK does not exist.';
        RETURN;
    END

    IF @StaffDesignationIdFK IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Profile.StaffDesignations WHERE StaffDesignationId = @StaffDesignationIdFK AND IsActive = 1)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'StaffDesignationIdFK does not exist or is inactive.';
        RETURN;
    END

    IF @PrimaryDepartmentIdFK IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM Profile.ClientDepartments
           WHERE ClientDepartmentId = @PrimaryDepartmentIdFK
             AND ClientIdFK = @ClientIdFK
             AND IsDeleted = 0
       )
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'PrimaryDepartmentIdFK does not belong to this client.';
        RETURN;
    END

    IF NULLIF(LTRIM(RTRIM(ISNULL(@Email, ''))), '') IS NOT NULL
       AND @Email NOT LIKE '%_@_%._%'
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Invalid email format.';
        RETURN;
    END

    SET @NormalizedPhone = LTRIM(RTRIM(ISNULL(@PhoneNumber, '')));
    IF @NormalizedPhone <> ''
    BEGIN
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '-', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, ' ', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '+', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '(', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, ')', '');

        IF LEN(@NormalizedPhone) <> 10 OR @NormalizedPhone LIKE '%[^0-9]%'
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'PhoneNumber must contain exactly 10 digits.';
            RETURN;
        END

        SET @FormattedPhone = SUBSTRING(@NormalizedPhone, 1, 3) + '-' +
                              SUBSTRING(@NormalizedPhone, 4, 3) + '-' +
                              SUBSTRING(@NormalizedPhone, 7, 4);
    END
    ELSE
    BEGIN
        SET @FormattedPhone = NULL;
    END

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM Profile.ClientStaff WHERE StaffCode = @StaffCode)
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'StaffCode already exists.';
            RETURN;
        END

        IF NULLIF(LTRIM(RTRIM(ISNULL(@Email, ''))), '') IS NOT NULL
           AND EXISTS
           (
               SELECT 1
               FROM Profile.ClientStaff
               WHERE ClientIdFK = @ClientIdFK
                 AND Email = LTRIM(RTRIM(@Email))
                 AND IsDeleted = 0
           )
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'Email already exists for this client.';
            RETURN;
        END

        SET @ClientStaffIdOutput = NEWID();

        INSERT INTO Profile.ClientStaff
        (
            ClientStaffId, ClientIdFK, RoleIdFK, UserIdFK, ProviderIdFK,
            StaffCode, FirstName, LastName, Email, PhoneNumber,
            JobTitle, Department, StaffDesignationIdFK, PrimaryDepartmentIdFK, StaffType, EmploymentType, HireDate,
            IsPrimaryContact, IsActive, IsDeleted,
            CreatedDate, CreatedBy, UpdatedDate, UpdatedBy
        )
        VALUES
        (
            @ClientStaffIdOutput, @ClientIdFK, @RoleIdFK, @UserIdFK, @ProviderIdFK,
            @StaffCode, @FirstName, @LastName,
            NULLIF(LTRIM(RTRIM(ISNULL(@Email, ''))), ''), @FormattedPhone,
            NULLIF(LTRIM(RTRIM(ISNULL(@JobTitle, ''))), ''),
            NULLIF(LTRIM(RTRIM(ISNULL(@Department, ''))), ''),
            @StaffDesignationIdFK, @PrimaryDepartmentIdFK,
            @StaffType, @EmploymentType, @HireDate,
            @IsPrimaryContact, 1, 0,
            @Now, COALESCE(NULLIF(@CreatedBy, ''), SUSER_SNAME()), @Now, COALESCE(NULLIF(@CreatedBy, ''), SUSER_SNAME())
        );

        IF @IsPrimaryContact = 1
        BEGIN
            UPDATE Profile.ClientStaff
            SET IsPrimaryContact = CASE WHEN ClientStaffId = @ClientStaffIdOutput THEN 1 ELSE 0 END,
                UpdatedDate = @Now,
                UpdatedBy = COALESCE(NULLIF(@CreatedBy, ''), SUSER_SNAME())
            WHERE ClientIdFK = @ClientIdFK
              AND IsDeleted = 0;
        END

        SET @StatusCode = 0;
        SET @Message = '';
    END TRY
    BEGIN CATCH
        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                        ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                        @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
            )
            VALUES
            (
                @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
            );
        END

        SET @ClientStaffIdOutput = NULL;
        SET @StatusCode = -1;
        SET @Message = 'Failed to add client staff record.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
-- END FILE: 006-stored-procedures/[Profile].[spAddClientStaff].sql


-- BEGIN FILE: 006-stored-procedures/[Profile].[spAddClient].sql

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spAddClient]
(
    @ClientCode VARCHAR(50),
    @FirstName VARCHAR(250),
    @LastName VARCHAR(250),
    @DateOfBirth DATETIME = NULL,
    @ID_Number VARCHAR(250) = NULL,
    @Email VARCHAR(250) = NULL,
    @PhoneNumber VARCHAR(25) = NULL,
    @AddressIDFK UNIQUEIDENTIFIER = NULL,
    @PatientIdFK UNIQUEIDENTIFIER = NULL,
    @ClientClinicCategoryIDFK INT = NULL,
    @CreatedBy VARCHAR(250) = NULL,
    @ClientIdOutput UNIQUEIDENTIFIER OUTPUT,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE(),
            @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME,
            @NormalizedPhone VARCHAR(25),
            @FormattedPhone VARCHAR(25);

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @ClientIdOutput = NULL;
    SET @StatusCode = -1;
    SET @Message = '';

    IF LTRIM(RTRIM(ISNULL(@ClientCode, ''))) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientCode is required.';
        RETURN;
    END

    IF LTRIM(RTRIM(ISNULL(@FirstName, ''))) = '' OR LTRIM(RTRIM(ISNULL(@LastName, ''))) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'FirstName and LastName are required.';
        RETURN;
    END

    IF @DateOfBirth IS NOT NULL AND @DateOfBirth > GETDATE()
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'DateOfBirth cannot be in the future.';
        RETURN;
    END

    IF NULLIF(LTRIM(RTRIM(ISNULL(@Email, ''))), '') IS NOT NULL
       AND @Email NOT LIKE '%_@_%._%'
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Invalid email format.';
        RETURN;
    END

    IF @AddressIDFK IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Location.Address WHERE AddressId = @AddressIDFK)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'AddressIDFK does not exist.';
        RETURN;
    END

    IF @PatientIdFK IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Profile.Patient WHERE PatientId = @PatientIdFK)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'PatientIdFK does not exist.';
        RETURN;
    END

    IF @ClientClinicCategoryIDFK IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM Profile.ClientClinicCategories CCC
           WHERE CCC.ClientClinicCategoryId = @ClientClinicCategoryIDFK
             AND CCC.IsActive = 1
       )
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientClinicCategoryIDFK does not exist or is inactive.';
        RETURN;
    END

    SET @NormalizedPhone = LTRIM(RTRIM(ISNULL(@PhoneNumber, '')));
    IF @NormalizedPhone <> ''
    BEGIN
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '-', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, ' ', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '+', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '(', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, ')', '');

        IF LEN(@NormalizedPhone) <> 10 OR @NormalizedPhone LIKE '%[^0-9]%'
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'PhoneNumber must contain exactly 10 digits.';
            RETURN;
        END

        SET @FormattedPhone = SUBSTRING(@NormalizedPhone, 1, 3) + '-' +
                              SUBSTRING(@NormalizedPhone, 4, 3) + '-' +
                              SUBSTRING(@NormalizedPhone, 7, 4);
    END
    ELSE
    BEGIN
        SET @FormattedPhone = NULL;
    END

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM Profile.Clients WHERE ClientCode = @ClientCode)
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'ClientCode already exists.';
            RETURN;
        END

        IF @PatientIdFK IS NOT NULL
           AND EXISTS (SELECT 1 FROM Profile.Clients WHERE PatientIdFK = @PatientIdFK)
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'A client is already linked to this PatientIdFK.';
            RETURN;
        END

        SET @ClientIdOutput = NEWID();

        INSERT INTO Profile.Clients
        (
            ClientId, PatientIdFK, ClientClinicCategoryIDFK, ClientCode, FirstName, LastName,
            DateOfBirth, ID_Number, Email, PhoneNumber, AddressIDFK,
            IsActive, IsDeleted, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy
        )
        VALUES
        (
            @ClientIdOutput, @PatientIdFK, @ClientClinicCategoryIDFK, @ClientCode, @FirstName, @LastName,
            @DateOfBirth, NULLIF(LTRIM(RTRIM(ISNULL(@ID_Number, ''))), ''),
            NULLIF(LTRIM(RTRIM(ISNULL(@Email, ''))), ''), @FormattedPhone, @AddressIDFK,
            1, 0, @Now, COALESCE(NULLIF(@CreatedBy, ''), SUSER_SNAME()), @Now, COALESCE(NULLIF(@CreatedBy, ''), SUSER_SNAME())
        );

        SET @StatusCode = 0;
        SET @Message = '';
    END TRY
    BEGIN CATCH
        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                        ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                        @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
            )
            VALUES
            (
                @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
            );
        END

        SET @ClientIdOutput = NULL;
        SET @StatusCode = -1;
        SET @Message = 'Failed to add client record.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
-- END FILE: 006-stored-procedures/[Profile].[spAddClient].sql


-- BEGIN FILE: 006-stored-procedures/[Profile].[spAddPatient].sql

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spAddPatient]
(
    @FirstName VARCHAR(250) = '',
    @LastName VARCHAR(250) = '',
    @ID_Number VARCHAR(250) = '',
    @DateOfBirth DATETIME,
    @GenderIDFK INT = 0,
    @PhoneNumber VARCHAR(250) = '',
    @Email VARCHAR(250) = '',
    @Line1 VARCHAR(250) = '',
    @Line2 VARCHAR(250) = '',
    @CityIDFK INT = 0,
    @ProvinceIDFK INT = 0,
    @CountryIDFK INT = 0,
    @MaritalStatusIDFK INT = 0,
    @EmergencyName VARCHAR(250) = '',
    @EmergencyLastName VARCHAR(250) = '',
    @EmergencyPhoneNumber VARCHAR(250) = '',
    @Relationship VARCHAR(250) = '',
    @EmergancyDateOfBirth DATETIME,
    @MedicationList VARCHAR(MAX) = '',
    @Message VARCHAR(250) OUTPUT,
    @PatientIdOutput UNIQUEIDENTIFIER OUTPUT,
    @StatusCode INT OUTPUT,
    @ClientIdFK UNIQUEIDENTIFIER = NULL
)
AS
BEGIN
    DECLARE @DefaultDate DATETIME = GETDATE(),
            @AddressIDFK UNIQUEIDENTIFIER = NEWID(),
            @EmergencyIDFK UNIQUEIDENTIFIER = NEWID(),
            @PatientId UNIQUEIDENTIFIER = NEWID(),
            @EmailIDFK UNIQUEIDENTIFIER,
            @PhoneIDFK UNIQUEIDENTIFIER,
            @NormalizedPhone VARCHAR(50),
            @NormalizedEmergencyPhone VARCHAR(50),
            @FormattedPhone VARCHAR(15),
            @FormattedEmergencyPhone VARCHAR(15),
            @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME;

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @PatientIdOutput = NULL;
    SET @StatusCode = -1;

    IF LTRIM(RTRIM(@ID_Number)) = ''
    BEGIN
        SET @Message = 'ID number is required.';
        SET @StatusCode = 1;
        RETURN;
    END

    IF LTRIM(RTRIM(@FirstName)) = '' OR LTRIM(RTRIM(@LastName)) = ''
    BEGIN
        SET @Message = 'First name and last name are required.';
        SET @StatusCode = 1;
        RETURN;
    END

    IF @DateOfBirth IS NULL OR @DateOfBirth > GETDATE()
    BEGIN
        SET @Message = 'Invalid date of birth.';
        SET @StatusCode = 1;
        RETURN;
    END

    IF @GenderIDFK <= 0 OR @MaritalStatusIDFK <= 0 OR @CityIDFK <= 0
    BEGIN
        SET @Message = 'Gender, marital status and city are required.';
        SET @StatusCode = 1;
        RETURN;
    END

    IF LTRIM(RTRIM(@Email)) = '' OR @Email NOT LIKE '%_@_%._%'
    BEGIN
        SET @Message = 'A valid email address is required.';
        SET @StatusCode = 1;
        RETURN;
    END

    SET @NormalizedPhone = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@PhoneNumber)), '-', ''), ' ', ''), '+', ''), '(', ''), ')', '');
    SET @NormalizedEmergencyPhone = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@EmergencyPhoneNumber)), '-', ''), ' ', ''), '+', ''), '(', ''), ')', '');

    IF LEN(@NormalizedPhone) <> 10 OR @NormalizedPhone LIKE '%[^0-9]%'
    BEGIN
        SET @Message = 'Phone number must contain exactly 10 digits.';
        SET @StatusCode = 1;
        RETURN;
    END

    IF LEN(@NormalizedEmergencyPhone) <> 10 OR @NormalizedEmergencyPhone LIKE '%[^0-9]%'
    BEGIN
        SET @Message = 'Emergency phone number must contain exactly 10 digits.';
        SET @StatusCode = 1;
        RETURN;
    END

    IF @ProvinceIDFK > 0
    BEGIN
        IF NOT EXISTS
        (
            SELECT 1
            FROM Location.Cities C
            WHERE C.CityId = @CityIDFK
              AND C.ProvinceIDFK = @ProvinceIDFK
        )
        BEGIN
            SET @Message = 'City and province combination is invalid.';
            SET @StatusCode = 1;
            RETURN;
        END
    END

    IF @CountryIDFK > 0
    BEGIN
        IF NOT EXISTS
        (
            SELECT 1
            FROM Location.Cities C
            INNER JOIN Location.Provinces P ON P.ProvinceId = C.ProvinceIDFK
            WHERE C.CityId = @CityIDFK
              AND P.CountryIDFK = @CountryIDFK
        )
        BEGIN
            SET @Message = 'City and country combination is invalid.';
            SET @StatusCode = 1;
            RETURN;
        END
    END

    IF @ClientIdFK IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Profile.Clients WHERE ClientId = @ClientIdFK AND IsDeleted = 0)
    BEGIN
        SET @Message = 'Invalid ClientIdFK.';
        SET @StatusCode = 1;
        RETURN;
    END

    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
        BEGIN TRAN;

        IF EXISTS(SELECT 1 FROM Profile.Patient WITH (UPDLOCK, HOLDLOCK) WHERE ID_Number = @ID_Number AND IsDeleted = 0)
        BEGIN
            SET @Message = 'Sorry User ID Number: "' + @ID_Number + '" already exists, please validate and try again';
            SET @StatusCode = 2;
            ROLLBACK TRAN;
            SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
            RETURN;
        END

        SET @FormattedPhone =
            SUBSTRING(@NormalizedPhone, 1, 3) + '-' +
            SUBSTRING(@NormalizedPhone, 4, 3) + '-' +
            SUBSTRING(@NormalizedPhone, 7, 4);

        SET @FormattedEmergencyPhone =
            SUBSTRING(@NormalizedEmergencyPhone, 1, 3) + '-' +
            SUBSTRING(@NormalizedEmergencyPhone, 4, 3) + '-' +
            SUBSTRING(@NormalizedEmergencyPhone, 7, 4);

        SELECT @EmailIDFK = E.EmailId
        FROM Contacts.Emails E WITH (UPDLOCK, HOLDLOCK)
        WHERE E.Email = @Email;

        IF @EmailIDFK IS NULL
        BEGIN
            SET @EmailIDFK = NEWID();
            INSERT INTO Contacts.Emails (EmailId, Email, IsActive, UpdateDate)
            VALUES (@EmailIDFK, @Email, 1, @DefaultDate);
        END

        SELECT @PhoneIDFK = P.PhoneId
        FROM Contacts.Phones P WITH (UPDLOCK, HOLDLOCK)
        WHERE P.PhoneNumber = @FormattedPhone;

        IF @PhoneIDFK IS NULL
        BEGIN
            SET @PhoneIDFK = NEWID();
            INSERT INTO Contacts.Phones (PhoneId, PhoneNumber, IsActive, UpdateDate)
            VALUES (@PhoneIDFK, @FormattedPhone, 1, @DefaultDate);
        END

        INSERT INTO Location.Address (AddressId, Line1, Line2, CityIDFK, UpdateDate)
        VALUES (@AddressIDFK, @Line1, @Line2, @CityIDFK, @DefaultDate);

        INSERT INTO Contacts.EmergencyContacts
        (
            EmergencyId,
            FirstName,
            LastName,
            PhoneNumber,
            Relationship,
            DateOfBirth,
            IsActive,
            UpdateDate
        )
        VALUES
        (
            @EmergencyIDFK,
            @EmergencyName,
            @EmergencyLastName,
            @FormattedEmergencyPhone,
            @Relationship,
            @EmergancyDateOfBirth,
            1,
            @DefaultDate
        );

        INSERT INTO Profile.Patient
        (
            PatientId,
            FirstName,
            LastName,
            ID_Number,
            DateOfBirth,
            GenderIDFK,
            MedicationList,
            ClientIdFK,
            AddressIDFK,
            MaritalStatusIDFK,
            EmergencyIDFK
        )
        VALUES
        (
            @PatientId,
            @FirstName,
            @LastName,
            @ID_Number,
            @DateOfBirth,
            @GenderIDFK,
            @MedicationList,
            @ClientIdFK,
            @AddressIDFK,
            @MaritalStatusIDFK,
            @EmergencyIDFK
        );

        INSERT INTO Contacts.PatientEmails (PatientEmailId, PatientIdFK, EmailIdFK, IsPrimary, EmailType)
        VALUES (NEWID(), @PatientId, @EmailIDFK, 1, 'Primary');

        INSERT INTO Contacts.PatientPhones (PatientPhoneId, PatientIdFK, PhoneIdFK, IsPrimary, PhoneType)
        VALUES (NEWID(), @PatientId, @PhoneIDFK, 1, 'Primary');

        COMMIT TRAN;
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

        SET @PatientIdOutput = @PatientId;
        SET @StatusCode = 0;
        SET @Message = '';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName,
                        ErrorSchema,
                        ErrorProcedure,
                        ErrorNumber,
                        ErrorState,
                        ErrorSeverity,
                        ErrorLine,
                        ErrorMessage,
                        ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName,
                        @ErrorSchema,
                        @ErrorProc,
                        @ErrorNumber,
                        @ErrorState,
                        @ErrorSeverity,
                        @ErrorLine,
                        LEFT(@ErrorMessage, 500),
                        @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName,
                ErrorSchema,
                ErrorProcedure,
                ErrorNumber,
                ErrorState,
                ErrorSeverity,
                ErrorLine,
                ErrorMessage,
                ErrorDateTime
            )
            VALUES
            (
                @UserName,
                @ErrorSchema,
                @ErrorProc,
                @ErrorNumber,
                @ErrorState,
                @ErrorSeverity,
                @ErrorLine,
                LEFT(@ErrorMessage, 500),
                @ErrorDateTime
            );
        END

        IF @ErrorNumber IN (2601, 2627)
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'A duplicate patient, email or phone record was detected. Please verify input and try again.';
        END
        ELSE
        BEGIN
            SET @StatusCode = -1;
            SET @Message = 'Failed to add patient record.';
        END
    END CATCH

    SET NOCOUNT OFF;
END
GO
-- END FILE: 006-stored-procedures/[Profile].[spAddPatient].sql


-- BEGIN FILE: 006-stored-procedures/[Profile].[spAssignClientClinicCategory].sql

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spAssignClientClinicCategory]
(
    @ClientId UNIQUEIDENTIFIER = NULL,
    @ClientCode VARCHAR(50) = '',
    @ClientClinicCategoryIDFK INT,
    @UpdatedBy VARCHAR(250) = NULL,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE(),
            @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME;

    SET NOCOUNT ON;

    SET @StatusCode = -1;
    SET @Message = '';

    BEGIN TRY
        IF @ClientId IS NULL AND LTRIM(RTRIM(@ClientCode)) = ''
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'ClientId or ClientCode is required.';
            RETURN;
        END

        IF @ClientClinicCategoryIDFK IS NULL
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'ClientClinicCategoryIDFK is required.';
            RETURN;
        END

        IF NOT EXISTS
        (
            SELECT 1
            FROM Profile.ClientClinicCategories CCC
            WHERE CCC.ClientClinicCategoryId = @ClientClinicCategoryIDFK
              AND CCC.IsActive = 1
        )
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'ClientClinicCategoryIDFK does not exist or is inactive.';
            RETURN;
        END

        IF EXISTS
        (
            SELECT 1
            FROM Profile.Clients C
            WHERE
                ((@ClientId IS NOT NULL AND C.ClientId = @ClientId)
                 OR (@ClientId IS NULL AND C.ClientCode = @ClientCode))
                AND C.IsDeleted = 0
        )
        BEGIN
            UPDATE C
            SET C.ClientClinicCategoryIDFK = @ClientClinicCategoryIDFK,
                C.UpdatedDate = @Now,
                C.UpdatedBy = COALESCE(NULLIF(@UpdatedBy, ''), SUSER_SNAME())
            FROM Profile.Clients C
            WHERE
                ((@ClientId IS NOT NULL AND C.ClientId = @ClientId)
                 OR (@ClientId IS NULL AND C.ClientCode = @ClientCode))
                AND C.IsDeleted = 0;

            SET @StatusCode = 0;
            SET @Message = '';
        END
        ELSE
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'Client does not exist or is deleted.';
        END
    END TRY
    BEGIN CATCH
        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                        ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                        @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
            )
            VALUES
            (
                @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
            );
        END

        SET @StatusCode = -1;
        SET @Message = 'Failed to assign clinic category to client.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
-- END FILE: 006-stored-procedures/[Profile].[spAssignClientClinicCategory].sql


-- BEGIN FILE: 006-stored-procedures/[Profile].[spDeleteClientDepartment].sql

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spDeleteClientDepartment]
(
    @ClientDepartmentId UNIQUEIDENTIFIER,
    @UpdatedBy VARCHAR(250) = NULL,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE(),
            @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME;

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @StatusCode = -1;
    SET @Message = '';

    IF @ClientDepartmentId IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientDepartmentId is required.';
        RETURN;
    END

    IF NOT EXISTS
    (
        SELECT 1
        FROM Profile.ClientDepartments
        WHERE ClientDepartmentId = @ClientDepartmentId
          AND IsDeleted = 0
    )
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Client department not found or already deleted.';
        RETURN;
    END

    DECLARE @HasAssignedStaff BIT = 0;
    IF COL_LENGTH('Profile.ClientStaff', 'PrimaryDepartmentIdFK') IS NOT NULL
    BEGIN
        DECLARE @CheckSql NVARCHAR(MAX) = N'
            IF EXISTS
            (
                SELECT 1
                FROM Profile.ClientStaff
                WHERE PrimaryDepartmentIdFK = @DeptId
                  AND IsDeleted = 0
            )
                SET @HasAssignedStaffOut = 1;';

        EXEC sp_executesql
            @CheckSql,
            N'@DeptId UNIQUEIDENTIFIER, @HasAssignedStaffOut BIT OUTPUT',
            @DeptId = @ClientDepartmentId,
            @HasAssignedStaffOut = @HasAssignedStaff OUTPUT;
    END

    IF @HasAssignedStaff = 1
    BEGIN
        SET @StatusCode = 2;
        SET @Message = 'Department cannot be deleted while staff are assigned to it.';
        RETURN;
    END

    BEGIN TRY
        UPDATE Profile.ClientDepartments
        SET IsDeleted = 1,
            IsActive = 0,
            UpdatedDate = @Now,
            UpdatedBy = COALESCE(NULLIF(@UpdatedBy, ''), SUSER_SNAME())
        WHERE ClientDepartmentId = @ClientDepartmentId
          AND IsDeleted = 0;

        SET @StatusCode = 0;
        SET @Message = '';
    END TRY
    BEGIN CATCH
        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                        ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                        @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
            )
            VALUES
            (
                @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
            );
        END

        SET @StatusCode = -1;
        SET @Message = 'Failed to delete client department.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
-- END FILE: 006-stored-procedures/[Profile].[spDeleteClientDepartment].sql


-- BEGIN FILE: 006-stored-procedures/[Profile].[spDeleteClientStaff].sql

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spDeleteClientStaff]
(
    @ClientStaffId UNIQUEIDENTIFIER = NULL,
    @StaffCode VARCHAR(50) = '',
    @UpdatedBy VARCHAR(250) = NULL,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @StatusCode = -1;
    SET @Message = '';

    IF @ClientStaffId IS NULL AND LTRIM(RTRIM(@StaffCode)) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientStaffId or StaffCode is required.';
        RETURN;
    END

    IF EXISTS
    (
        SELECT 1
        FROM Profile.ClientStaff
        WHERE ((@ClientStaffId IS NOT NULL AND ClientStaffId = @ClientStaffId)
               OR (@ClientStaffId IS NULL AND StaffCode = @StaffCode))
          AND IsDeleted = 0
    )
    BEGIN
        UPDATE Profile.ClientStaff
        SET IsDeleted = 1,
            IsActive = 0,
            IsPrimaryContact = 0,
            UpdatedDate = GETDATE(),
            UpdatedBy = COALESCE(NULLIF(@UpdatedBy, ''), SUSER_SNAME())
        WHERE ((@ClientStaffId IS NOT NULL AND ClientStaffId = @ClientStaffId)
               OR (@ClientStaffId IS NULL AND StaffCode = @StaffCode))
          AND IsDeleted = 0;

        SET @StatusCode = 0;
        SET @Message = '';
    END
    ELSE
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Client staff not found or already deleted.';
    END

    SET NOCOUNT OFF;
END
GO
-- END FILE: 006-stored-procedures/[Profile].[spDeleteClientStaff].sql


-- BEGIN FILE: 006-stored-procedures/[Profile].[spDeleteClient].sql

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spDeleteClient]
(
    @ClientId UNIQUEIDENTIFIER = NULL,
    @ClientCode VARCHAR(50) = '',
    @UpdatedBy VARCHAR(250) = NULL,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE(),
            @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME;

    SET NOCOUNT ON;

    SET @StatusCode = -1;
    SET @Message = '';

    BEGIN TRY
        IF @ClientId IS NULL AND LTRIM(RTRIM(@ClientCode)) = ''
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'ClientId or ClientCode is required.';
            RETURN;
        END

        IF EXISTS
        (
            SELECT 1
            FROM Profile.Clients C
            WHERE
                ((@ClientId IS NOT NULL AND C.ClientId = @ClientId)
                 OR (@ClientId IS NULL AND C.ClientCode = @ClientCode))
                AND C.IsDeleted = 0
        )
        BEGIN
            UPDATE C
            SET IsDeleted = 1,
                IsActive = 0,
                UpdatedDate = @Now,
                UpdatedBy = COALESCE(NULLIF(@UpdatedBy, ''), SUSER_SNAME())
            FROM Profile.Clients C
            WHERE
                ((@ClientId IS NOT NULL AND C.ClientId = @ClientId)
                 OR (@ClientId IS NULL AND C.ClientCode = @ClientCode))
                AND C.IsDeleted = 0;

            SET @StatusCode = 0;
            SET @Message = '';
        END
        ELSE
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'Client does not exist or is already deleted.';
        END
    END TRY
    BEGIN CATCH
        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                        ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                        @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
            )
            VALUES
            (
                @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
            );
        END

        SET @StatusCode = -1;
        SET @Message = 'Failed to delete client record.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
-- END FILE: 006-stored-procedures/[Profile].[spDeleteClient].sql


-- BEGIN FILE: 006-stored-procedures/[Profile].[spGetClientClinicCategories].sql

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spGetClientClinicCategories]
(
    @ClientClinicCategoryId INT = 0,
    @IsActive BIT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CCC.ClientClinicCategoryId,
        CCC.CategoryName,
        CCC.ClinicSize,
        CCC.OwnershipType,
        CCC.IsActive,
        CCC.CreatedDate,
        CCC.UpdatedDate
    FROM Profile.ClientClinicCategories CCC
    WHERE (@ClientClinicCategoryId = 0 OR CCC.ClientClinicCategoryId = @ClientClinicCategoryId)
      AND (@IsActive IS NULL OR CCC.IsActive = @IsActive)
    ORDER BY CCC.CategoryName;

    SET NOCOUNT OFF;
END
GO
-- END FILE: 006-stored-procedures/[Profile].[spGetClientClinicCategories].sql


-- BEGIN FILE: 006-stored-procedures/[Profile].[spGetClientStaff].sql

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spGetClientStaff]
(
    @ClientStaffId UNIQUEIDENTIFIER = NULL,
    @StaffCode VARCHAR(50) = '',
    @IncludeDeleted BIT = 0,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET @Message = '';

    IF @ClientStaffId IS NULL AND LTRIM(RTRIM(@StaffCode)) = ''
    BEGIN
        SET @Message = 'ClientStaffId or StaffCode is required.';
        RETURN;
    END

    IF EXISTS
    (
        SELECT 1
        FROM Profile.ClientStaff CS
        WHERE ((@ClientStaffId IS NOT NULL AND CS.ClientStaffId = @ClientStaffId)
               OR (@ClientStaffId IS NULL AND CS.StaffCode = @StaffCode))
          AND (@IncludeDeleted = 1 OR CS.IsDeleted = 0)
    )
    BEGIN
        SELECT
            CS.ClientStaffId,
            CS.ClientIdFK,
            C.ClientCode,
            CS.RoleIdFK,
            R.RoleName,
            CS.UserIdFK,
            U.Username,
            CS.ProviderIdFK,
            CS.StaffCode,
            CS.FirstName,
            CS.LastName,
            CS.Email,
            CS.PhoneNumber,
            CS.JobTitle,
            CS.Department,
            CS.StaffDesignationIdFK,
            SD.DesignationName AS StaffDesignation,
            CS.PrimaryDepartmentIdFK,
            CD.DepartmentName AS PrimaryDepartmentName,
            CS.StaffType,
            CS.EmploymentType,
            CS.HireDate,
            CS.TerminationDate,
            CS.IsPrimaryContact,
            CS.IsActive,
            CS.IsDeleted,
            CS.CreatedDate,
            CS.CreatedBy,
            CS.UpdatedDate,
            CS.UpdatedBy
        FROM Profile.ClientStaff CS
        INNER JOIN Profile.Clients C ON C.ClientId = CS.ClientIdFK
        LEFT JOIN Auth.Roles R ON R.RoleId = CS.RoleIdFK
        LEFT JOIN Auth.Users U ON U.UserId = CS.UserIdFK
        LEFT JOIN Profile.StaffDesignations SD ON SD.StaffDesignationId = CS.StaffDesignationIdFK
        LEFT JOIN Profile.ClientDepartments CD ON CD.ClientDepartmentId = CS.PrimaryDepartmentIdFK
        WHERE ((@ClientStaffId IS NOT NULL AND CS.ClientStaffId = @ClientStaffId)
               OR (@ClientStaffId IS NULL AND CS.StaffCode = @StaffCode))
          AND (@IncludeDeleted = 1 OR CS.IsDeleted = 0);

        SET @Message = '';
    END
    ELSE
    BEGIN
        SET @Message = 'Client staff not found.';
    END

    SET NOCOUNT OFF;
END
GO
-- END FILE: 006-stored-procedures/[Profile].[spGetClientStaff].sql


-- BEGIN FILE: 006-stored-procedures/[Profile].[spGetClient].sql

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spGetClient]
(
    @ClientId UNIQUEIDENTIFIER = NULL,
    @ClientCode VARCHAR(50) = '',
    @IncludeDeleted BIT = 0,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME;

    SET NOCOUNT ON;
    SET @Message = '';

    BEGIN TRY
        IF @ClientId IS NULL AND LTRIM(RTRIM(@ClientCode)) = ''
        BEGIN
            SET @Message = 'ClientId or ClientCode is required.';
            RETURN;
        END

        IF EXISTS
        (
            SELECT 1
            FROM Profile.Clients C
            WHERE
                ((@ClientId IS NOT NULL AND C.ClientId = @ClientId)
                 OR (@ClientId IS NULL AND C.ClientCode = @ClientCode))
                AND (@IncludeDeleted = 1 OR C.IsDeleted = 0)
        )
        BEGIN
            SELECT
                C.ClientId,
                C.PatientIdFK,
                C.ClientClinicCategoryIDFK,
                CCC.CategoryName AS ClientClinicCategoryName,
                CCC.ClinicSize,
                CCC.OwnershipType,
                C.ClientCode,
                C.FirstName,
                C.LastName,
                C.DateOfBirth,
                C.ID_Number,
                C.Email,
                C.PhoneNumber,
                C.AddressIDFK,
                LA.Line1,
                LA.Line2,
                LA.CityIDFK,
                C.IsActive,
                C.IsDeleted,
                C.CreatedDate,
                C.CreatedBy,
                C.UpdatedDate,
                C.UpdatedBy
            FROM Profile.Clients C
            LEFT JOIN Location.Address LA ON LA.AddressId = C.AddressIDFK
            LEFT JOIN Profile.ClientClinicCategories CCC ON CCC.ClientClinicCategoryId = C.ClientClinicCategoryIDFK
            WHERE
                ((@ClientId IS NOT NULL AND C.ClientId = @ClientId)
                 OR (@ClientId IS NULL AND C.ClientCode = @ClientCode))
                AND (@IncludeDeleted = 1 OR C.IsDeleted = 0);

            SET @Message = '';
        END
        ELSE
        BEGIN
            SET @Message = 'Client not found.';
        END
    END TRY
    BEGIN CATCH
        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                        ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                        @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
            )
            VALUES
            (
                @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
            );
        END

        SET @Message = 'Failed to retrieve client record.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
-- END FILE: 006-stored-procedures/[Profile].[spGetClient].sql


-- BEGIN FILE: 006-stored-procedures/[Profile].[spGetMaritalStatus].sql

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spGetMaritalStatus]
(
    @MaritalStatusId INT = 0,
    @MaritalStatusDescription VARCHAR(250) = ''
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CAST(MaritalStatusId AS VARCHAR(250)) AS MaritalStatusIDFK,
        MaritalStatusDescription
    FROM Profile.MaritalStatus
    WHERE (@MaritalStatusId = 0 OR MaritalStatusId = @MaritalStatusId)
      AND (@MaritalStatusDescription = '' OR MaritalStatusDescription LIKE @MaritalStatusDescription + '%')
    ORDER BY MaritalStatusDescription;

    SET NOCOUNT OFF;
END
GO
-- END FILE: 006-stored-procedures/[Profile].[spGetMaritalStatus].sql


-- BEGIN FILE: 006-stored-procedures/[Profile].[spGetPatient].sql

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spGetPatient]
(
    @PatientId UNIQUEIDENTIFIER = NULL,
    @IDNumber VARCHAR(250) = '',
    @IncludeDeleted BIT = 0,
    @FirstName VARCHAR(250) OUTPUT,
    @LastName VARCHAR(250) OUTPUT,
    @ID_Number VARCHAR(250) OUTPUT,
    @DateOfBirth DATETIME OUTPUT,
    @GenderIDFK INT OUTPUT,
    @PhoneNumber VARCHAR(250) OUTPUT,
    @Email VARCHAR(250) OUTPUT,
    @Line1 VARCHAR(250) OUTPUT,
    @Line2 VARCHAR(250) OUTPUT,
    @CityIDFK INT OUTPUT,
    @ProvinceIDFK INT OUTPUT,
    @CountryIDFK INT OUTPUT,
    @MaritalStatusIDFK INT OUTPUT,
    @MedicationList VARCHAR(MAX) OUTPUT,
    @EmergencyName VARCHAR(250) OUTPUT,
    @EmergencyLastName VARCHAR(250) OUTPUT,
    @EmergencyPhoneNumber VARCHAR(250) OUTPUT,
    @Relationship VARCHAR(250) OUTPUT,
    @EmergancyDateOfBirth DATETIME OUTPUT,
    @Message VARCHAR(250) OUTPUT,
    @ClientIdFK UNIQUEIDENTIFIER = NULL OUTPUT
)
AS
BEGIN
    DECLARE @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME;

	    SET NOCOUNT ON;

	    BEGIN TRY
            SET @FirstName = '';
            SET @LastName = '';
            SET @ID_Number = '';
            SET @ClientIdFK = NULL;
            SET @DateOfBirth = GETDATE();
            SET @GenderIDFK = 0;
            SET @PhoneNumber = '';
            SET @Email = '';
            SET @Line1 = '';
            SET @Line2 = '';
            SET @CityIDFK = 0;
            SET @ProvinceIDFK = 0;
            SET @CountryIDFK = 0;
            SET @MaritalStatusIDFK = 0;
            SET @MedicationList = '';
            SET @EmergencyName = '';
            SET @EmergencyLastName = '';
            SET @EmergencyPhoneNumber = '';
            SET @Relationship = '';
            SET @EmergancyDateOfBirth = GETDATE();
            SET @Message = '';

            IF @PatientId IS NULL AND LTRIM(RTRIM(@IDNumber)) = ''
            BEGIN
                SET @Message = 'PatientId or IDNumber is required.';
                RETURN;
            END

	        IF EXISTS
            (
                SELECT 1
                FROM Profile.Patient PP
                WHERE
                    (
                        (@PatientId IS NOT NULL AND PP.PatientId = @PatientId)
                        OR
                        (@PatientId IS NULL AND PP.ID_Number = @IDNumber)
                    )
                    AND (@IncludeDeleted = 1 OR PP.IsDeleted = 0)
            )
	        BEGIN
	            SELECT
                @FirstName = PP.FirstName,
                @LastName = PP.LastName,
                @ID_Number = PP.ID_Number,
                @ClientIdFK = PP.ClientIdFK,
                @DateOfBirth = PP.DateOfBirth,
                @GenderIDFK = PP.GenderIDFK,
                @PhoneNumber = CP.PhoneNumber,
                @Email = CE.Email,
                @Line1 = LA.Line1,
                @Line2 = LA.Line2,
                @CityIDFK = LC.CityId,
                @ProvinceIDFK = LP.ProvinceId,
                @CountryIDFK = LCO.CountryId,
                @MaritalStatusIDFK = PP.MaritalStatusIDFK,
                @MedicationList = PP.MedicationList,
                @EmergencyName = CEC.FirstName,
                @EmergencyLastName = CEC.LastName,
                @EmergencyPhoneNumber = CEC.PhoneNumber,
                @Relationship = CEC.Relationship,
                @EmergancyDateOfBirth = CEC.DateOfBirth
            FROM Profile.Patient AS PP
            LEFT JOIN Location.Address AS LA ON PP.AddressIDFK = LA.AddressId
            LEFT JOIN Location.Cities AS LC ON LA.CityIDFK = LC.CityId
            LEFT JOIN Location.Provinces AS LP ON LC.ProvinceIDFK = LP.ProvinceId
            LEFT JOIN Location.Countries AS LCO ON LP.CountryIDFK = LCO.CountryId
            LEFT JOIN Contacts.EmergencyContacts AS CEC ON PP.EmergencyIDFK = CEC.EmergencyId
            OUTER APPLY
            (
                SELECT TOP (1) PE.EmailIdFK
                FROM Contacts.PatientEmails PE
                WHERE PE.PatientIdFK = PP.PatientId
                ORDER BY PE.IsPrimary DESC, PE.CreatedDate DESC
            ) PE
            LEFT JOIN Contacts.Emails CE ON CE.EmailId = PE.EmailIdFK
            OUTER APPLY
            (
                SELECT TOP (1) PPX.PhoneIdFK
                FROM Contacts.PatientPhones PPX
                WHERE PPX.PatientIdFK = PP.PatientId
                ORDER BY PPX.IsPrimary DESC, PPX.CreatedDate DESC
            ) PH
	            LEFT JOIN Contacts.Phones CP ON CP.PhoneId = PH.PhoneIdFK
	            WHERE
                    (
                        (@PatientId IS NOT NULL AND PP.PatientId = @PatientId)
                        OR
                        (@PatientId IS NULL AND PP.ID_Number = @IDNumber)
                    )
                    AND (@IncludeDeleted = 1 OR PP.IsDeleted = 0);

	            SET @Message = '';
	        END
	        ELSE
	        BEGIN
                IF @PatientId IS NOT NULL
                    SET @Message = 'PatientId does not exist or is soft deleted.';
                ELSE
	                SET @Message = 'ID number does not exist or is soft deleted.';
	        END
	    END TRY
    BEGIN CATCH
        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName,
                        ErrorSchema,
                        ErrorProcedure,
                        ErrorNumber,
                        ErrorState,
                        ErrorSeverity,
                        ErrorLine,
                        ErrorMessage,
                        ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName,
                        @ErrorSchema,
                        @ErrorProc,
                        @ErrorNumber,
                        @ErrorState,
                        @ErrorSeverity,
                        @ErrorLine,
                        LEFT(@ErrorMessage, 500),
                        @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName,
                ErrorSchema,
                ErrorProcedure,
                ErrorNumber,
                ErrorState,
                ErrorSeverity,
                ErrorLine,
                ErrorMessage,
                ErrorDateTime
            )
            VALUES
            (
                @UserName,
                @ErrorSchema,
                @ErrorProc,
                @ErrorNumber,
                @ErrorState,
                @ErrorSeverity,
                @ErrorLine,
                LEFT(@ErrorMessage, 500),
                @ErrorDateTime
            );
        END

        SET @Message = 'Failed to retrieve patient record.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
-- END FILE: 006-stored-procedures/[Profile].[spGetPatient].sql


-- BEGIN FILE: 006-stored-procedures/[Profile].[spListClientDepartments].sql

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spListClientDepartments]
(
    @ClientIdFK UNIQUEIDENTIFIER = NULL,
    @DepartmentType VARCHAR(50) = '',
    @SearchTerm VARCHAR(100) = '',
    @IsActive BIT = NULL,
    @IsDeleted BIT = 0,
    @PageNumber INT = 1,
    @PageSize INT = 25,
    @TotalRecords INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Offset INT,
            @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME;

    SET NOCOUNT ON;

    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize < 1 SET @PageSize = 25;
    IF @PageSize > 200 SET @PageSize = 200;

    IF @DepartmentType <> ''
       AND @DepartmentType NOT IN ('Clinical', 'Administrative', 'Support', 'Management', 'Allied')
    BEGIN
        SET @TotalRecords = 0;
        SET @Message = 'Invalid DepartmentType.';
        RETURN;
    END

    SET @Offset = (@PageNumber - 1) * @PageSize;
    SET @TotalRecords = 0;
    SET @Message = '';

    BEGIN TRY
        ;WITH Base AS
        (
            SELECT
                CD.ClientDepartmentId,
                CD.ClientIdFK,
                C.ClientCode,
                C.FirstName AS ClientFirstName,
                C.LastName AS ClientLastName,
                CD.DepartmentCode,
                CD.DepartmentName,
                CD.DepartmentType,
                CD.IsActive,
                CD.IsDeleted,
                CD.CreatedDate,
                CD.CreatedBy,
                CD.UpdatedDate,
                CD.UpdatedBy
            FROM Profile.ClientDepartments CD
            INNER JOIN Profile.Clients C ON C.ClientId = CD.ClientIdFK
            WHERE (@ClientIdFK IS NULL OR CD.ClientIdFK = @ClientIdFK)
              AND (@DepartmentType = '' OR CD.DepartmentType = @DepartmentType)
              AND (@IsActive IS NULL OR CD.IsActive = @IsActive)
              AND (@IsDeleted IS NULL OR CD.IsDeleted = @IsDeleted)
              AND
              (
                    @SearchTerm = ''
                    OR CD.DepartmentName LIKE '%' + @SearchTerm + '%'
                    OR ISNULL(CD.DepartmentCode, '') LIKE '%' + @SearchTerm + '%'
                    OR C.ClientCode LIKE '%' + @SearchTerm + '%'
              )
        ),
        Numbered AS
        (
            SELECT
                B.*,
                COUNT(1) OVER () AS TotalRows,
                ROW_NUMBER() OVER (ORDER BY B.DepartmentName ASC, B.ClientDepartmentId ASC) AS RowNum
            FROM Base B
        )
        SELECT
            ClientDepartmentId,
            ClientIdFK,
            ClientCode,
            ClientFirstName,
            ClientLastName,
            DepartmentCode,
            DepartmentName,
            DepartmentType,
            IsActive,
            IsDeleted,
            CreatedDate,
            CreatedBy,
            UpdatedDate,
            UpdatedBy
        FROM Numbered
        WHERE RowNum > @Offset
          AND RowNum <= (@Offset + @PageSize)
        ORDER BY RowNum;

        SELECT @TotalRecords = ISNULL(MAX(TotalRows), 0)
        FROM Numbered;

        SET @Message = '';
    END TRY
    BEGIN CATCH
        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                        ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                        @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
            )
            VALUES
            (
                @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
            );
        END

        SET @TotalRecords = 0;
        SET @Message = 'Failed to list client departments.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
-- END FILE: 006-stored-procedures/[Profile].[spListClientDepartments].sql


-- BEGIN FILE: 006-stored-procedures/[Profile].[spListClientStaff].sql

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spListClientStaff]
(
    @ClientIdFK UNIQUEIDENTIFIER = NULL,
    @SearchTerm VARCHAR(250) = '',
    @RoleIdFK UNIQUEIDENTIFIER = NULL,
    @StaffType VARCHAR(50) = '',
    @IsActive BIT = NULL,
    @IsDeleted BIT = 0,
    @PageNumber INT = 1,
    @PageSize INT = 25,
    @TotalRecords INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize < 1 SET @PageSize = 25;
    IF @PageSize > 200 SET @PageSize = 200;

    SET @TotalRecords = 0;
    SET @Message = '';

    ;WITH Base AS
    (
        SELECT
            CS.ClientStaffId,
            CS.ClientIdFK,
            C.ClientCode,
            CS.RoleIdFK,
            R.RoleName,
            CS.UserIdFK,
            U.Username,
            CS.ProviderIdFK,
            CS.StaffCode,
            CS.FirstName,
            CS.LastName,
            CS.Email,
            CS.PhoneNumber,
            CS.JobTitle,
            CS.Department,
            CS.StaffDesignationIdFK,
            SD.DesignationName AS StaffDesignation,
            CS.PrimaryDepartmentIdFK,
            CD.DepartmentName AS PrimaryDepartmentName,
            CS.StaffType,
            CS.EmploymentType,
            CS.HireDate,
            CS.TerminationDate,
            CS.IsPrimaryContact,
            CS.IsActive,
            CS.IsDeleted,
            CS.CreatedDate,
            CS.UpdatedDate
        FROM Profile.ClientStaff CS
        INNER JOIN Profile.Clients C ON C.ClientId = CS.ClientIdFK
        LEFT JOIN Auth.Roles R ON R.RoleId = CS.RoleIdFK
        LEFT JOIN Auth.Users U ON U.UserId = CS.UserIdFK
        LEFT JOIN Profile.StaffDesignations SD ON SD.StaffDesignationId = CS.StaffDesignationIdFK
        LEFT JOIN Profile.ClientDepartments CD ON CD.ClientDepartmentId = CS.PrimaryDepartmentIdFK
        WHERE (@ClientIdFK IS NULL OR CS.ClientIdFK = @ClientIdFK)
          AND (@RoleIdFK IS NULL OR CS.RoleIdFK = @RoleIdFK)
          AND (@StaffType = '' OR CS.StaffType = @StaffType)
          AND (@IsActive IS NULL OR CS.IsActive = @IsActive)
          AND (@IsDeleted IS NULL OR CS.IsDeleted = @IsDeleted)
          AND (
                @SearchTerm = ''
                OR CS.StaffCode LIKE '%' + @SearchTerm + '%'
                OR CS.FirstName LIKE '%' + @SearchTerm + '%'
                OR CS.LastName LIKE '%' + @SearchTerm + '%'
                OR ISNULL(CS.Email, '') LIKE '%' + @SearchTerm + '%'
                OR ISNULL(CS.PhoneNumber, '') LIKE '%' + @SearchTerm + '%'
                OR ISNULL(CS.JobTitle, '') LIKE '%' + @SearchTerm + '%'
              )
    ),
    Numbered AS
    (
        SELECT
            B.*,
            COUNT(1) OVER () AS TotalRows,
            ROW_NUMBER() OVER (ORDER BY B.LastName ASC, B.FirstName ASC, B.ClientStaffId ASC) AS RowNum
        FROM Base B
    )
    SELECT
        ClientStaffId,
        ClientIdFK,
        ClientCode,
        RoleIdFK,
        RoleName,
        UserIdFK,
        Username,
        ProviderIdFK,
        StaffCode,
        FirstName,
        LastName,
        Email,
        PhoneNumber,
        JobTitle,
        Department,
        StaffDesignationIdFK,
        StaffDesignation,
        PrimaryDepartmentIdFK,
        PrimaryDepartmentName,
        StaffType,
        EmploymentType,
        HireDate,
        TerminationDate,
        IsPrimaryContact,
        IsActive,
        IsDeleted,
        CreatedDate,
        UpdatedDate
    FROM Numbered
    WHERE RowNum > ((@PageNumber - 1) * @PageSize)
      AND RowNum <= ((@PageNumber - 1) * @PageSize + @PageSize)
    ORDER BY RowNum;

    SELECT @TotalRecords = ISNULL(MAX(TotalRows), 0)
    FROM Numbered;

    SET NOCOUNT OFF;
END
GO
-- END FILE: 006-stored-procedures/[Profile].[spListClientStaff].sql


-- BEGIN FILE: 006-stored-procedures/[Profile].[spListClients].sql

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spListClients]
(
    @SearchTerm VARCHAR(250) = '',
    @ClientClinicCategoryIDFK INT = 0,
    @ClinicSize VARCHAR(20) = '',
    @OwnershipType VARCHAR(20) = '',
    @IsActive BIT = NULL,
    @IsDeleted BIT = 0,
    @PageNumber INT = 1,
    @PageSize INT = 25,
    @TotalRecords INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Offset INT,
            @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME;

    SET NOCOUNT ON;

    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize < 1 SET @PageSize = 25;
    IF @PageSize > 200 SET @PageSize = 200;

    SET @Offset = (@PageNumber - 1) * @PageSize;
    SET @TotalRecords = 0;
    SET @Message = '';

    BEGIN TRY
        ;WITH Base AS
        (
            SELECT
                C.ClientId,
                C.PatientIdFK,
                C.ClientClinicCategoryIDFK,
                CCC.CategoryName AS ClientClinicCategoryName,
                CCC.ClinicSize,
                CCC.OwnershipType,
                C.ClientCode,
                C.FirstName,
                C.LastName,
                C.DateOfBirth,
                C.ID_Number,
                C.Email,
                C.PhoneNumber,
                C.AddressIDFK,
                C.IsActive,
                C.IsDeleted,
                C.CreatedDate,
                C.UpdatedDate,
                LA.Line1,
                LA.Line2,
                LA.CityIDFK
            FROM Profile.Clients C
            LEFT JOIN Location.Address LA ON LA.AddressId = C.AddressIDFK
            LEFT JOIN Profile.ClientClinicCategories CCC ON CCC.ClientClinicCategoryId = C.ClientClinicCategoryIDFK
            WHERE
                (
                    @SearchTerm = ''
                    OR C.ClientCode LIKE '%' + @SearchTerm + '%'
                    OR C.FirstName LIKE '%' + @SearchTerm + '%'
                    OR C.LastName LIKE '%' + @SearchTerm + '%'
                    OR ISNULL(C.ID_Number, '') LIKE '%' + @SearchTerm + '%'
                    OR ISNULL(C.Email, '') LIKE '%' + @SearchTerm + '%'
                    OR ISNULL(C.PhoneNumber, '') LIKE '%' + @SearchTerm + '%'
                )
                AND (@ClientClinicCategoryIDFK = 0 OR C.ClientClinicCategoryIDFK = @ClientClinicCategoryIDFK)
                AND (@ClinicSize = '' OR ISNULL(CCC.ClinicSize, '') = @ClinicSize)
                AND (@OwnershipType = '' OR ISNULL(CCC.OwnershipType, '') = @OwnershipType)
                AND (@IsActive IS NULL OR C.IsActive = @IsActive)
                AND (@IsDeleted IS NULL OR C.IsDeleted = @IsDeleted)
        ),
        Numbered AS
        (
            SELECT
                B.*,
                COUNT(1) OVER () AS TotalRows,
                ROW_NUMBER() OVER (ORDER BY B.LastName ASC, B.FirstName ASC, B.ClientId ASC) AS RowNum
            FROM Base B
        )
        SELECT
            ClientId,
            PatientIdFK,
            ClientClinicCategoryIDFK,
            ClientClinicCategoryName,
            ClinicSize,
            OwnershipType,
            ClientCode,
            FirstName,
            LastName,
            DateOfBirth,
            ID_Number,
            Email,
            PhoneNumber,
            AddressIDFK,
            Line1,
            Line2,
            CityIDFK,
            IsActive,
            IsDeleted,
            CreatedDate,
            UpdatedDate
        FROM Numbered
        WHERE RowNum > @Offset
          AND RowNum <= (@Offset + @PageSize)
        ORDER BY RowNum;

        SELECT @TotalRecords = ISNULL(MAX(TotalRows), 0)
        FROM Numbered;

        SET @Message = '';
    END TRY
    BEGIN CATCH
        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                        ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                        @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
            )
            VALUES
            (
                @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
            );
        END

        SET @TotalRecords = 0;
        SET @Message = 'Failed to retrieve clients list.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
-- END FILE: 006-stored-procedures/[Profile].[spListClients].sql


-- BEGIN FILE: 006-stored-procedures/[Profile].[spListPatients].sql

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spListPatients]
(
    @SearchTerm VARCHAR(250) = '',
    @GenderIDFK INT = 0,
    @MaritalStatusIDFK INT = 0,
    @CityIDFK INT = 0,
    @IsDeleted BIT = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 25,
    @TotalRecords INT OUTPUT,
    @Message VARCHAR(250) OUTPUT,
    @ClientIdFK UNIQUEIDENTIFIER = NULL
)
AS
BEGIN
    DECLARE @Offset INT,
            @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME;

    SET NOCOUNT ON;

    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize < 1 SET @PageSize = 25;
    IF @PageSize > 200 SET @PageSize = 200;

    SET @Offset = (@PageNumber - 1) * @PageSize;
    SET @TotalRecords = 0;
    SET @Message = '';

    BEGIN TRY
        ;WITH PatientBase AS
        (
            SELECT
                P.PatientId,
                P.FirstName,
                P.LastName,
                P.ID_Number,
                P.DateOfBirth,
                P.GenderIDFK,
                P.MaritalStatusIDFK,
                P.ClientIdFK,
                P.MedicationList,
                P.IsDeleted,
                P.CreatedDate,
                P.UpdatedDate,
                CE.Email,
                CP.PhoneNumber,
                LA.Line1,
                LA.Line2,
                LC.CityId,
                LC.CityName,
                LP.ProvinceId,
                LP.ProvinceName,
                LCO.CountryId,
                LCO.CountryName
            FROM Profile.Patient P
            LEFT JOIN Location.Address LA ON LA.AddressId = P.AddressIDFK
            LEFT JOIN Location.Cities LC ON LC.CityId = LA.CityIDFK
            LEFT JOIN Location.Provinces LP ON LP.ProvinceId = LC.ProvinceIDFK
            LEFT JOIN Location.Countries LCO ON LCO.CountryId = LP.CountryIDFK
            OUTER APPLY
            (
                SELECT TOP (1) PE.EmailIdFK
                FROM Contacts.PatientEmails PE
                WHERE PE.PatientIdFK = P.PatientId
                ORDER BY PE.IsPrimary DESC, PE.CreatedDate DESC
            ) PE1
            LEFT JOIN Contacts.Emails CE ON CE.EmailId = PE1.EmailIdFK
            OUTER APPLY
            (
                SELECT TOP (1) PP.PhoneIdFK
                FROM Contacts.PatientPhones PP
                WHERE PP.PatientIdFK = P.PatientId
                ORDER BY PP.IsPrimary DESC, PP.CreatedDate DESC
            ) PP1
            LEFT JOIN Contacts.Phones CP ON CP.PhoneId = PP1.PhoneIdFK
            WHERE
                (
                    @SearchTerm = ''
                    OR P.FirstName LIKE '%' + @SearchTerm + '%'
                    OR P.LastName LIKE '%' + @SearchTerm + '%'
                    OR P.ID_Number LIKE '%' + @SearchTerm + '%'
                    OR ISNULL(CE.Email, '') LIKE '%' + @SearchTerm + '%'
                    OR ISNULL(CP.PhoneNumber, '') LIKE '%' + @SearchTerm + '%'
                )
                AND (@ClientIdFK IS NULL OR P.ClientIdFK = @ClientIdFK)
                AND (@GenderIDFK = 0 OR P.GenderIDFK = @GenderIDFK)
                AND (@MaritalStatusIDFK = 0 OR P.MaritalStatusIDFK = @MaritalStatusIDFK)
                AND (@CityIDFK = 0 OR LC.CityId = @CityIDFK)
                AND (@IsDeleted IS NULL OR P.IsDeleted = @IsDeleted)
        ),
        Numbered AS
        (
            SELECT
                PB.*,
                COUNT(1) OVER () AS TotalRows,
                ROW_NUMBER() OVER (ORDER BY PB.LastName ASC, PB.FirstName ASC, PB.PatientId ASC) AS RowNum
            FROM PatientBase PB
        )
        SELECT
            PatientId,
            FirstName,
            LastName,
            ID_Number,
            DateOfBirth,
            GenderIDFK,
            MaritalStatusIDFK,
            ClientIdFK,
            MedicationList,
            IsDeleted,
            Email,
            PhoneNumber,
            Line1,
            Line2,
            CityId,
            CityName,
            ProvinceId,
            ProvinceName,
            CountryId,
            CountryName,
            CreatedDate,
            UpdatedDate
        FROM Numbered
        WHERE RowNum > @Offset
          AND RowNum <= (@Offset + @PageSize)
        ORDER BY RowNum;

        SELECT @TotalRecords = ISNULL(MAX(TotalRows), 0)
        FROM Numbered;

        SET @Message = '';
    END TRY
    BEGIN CATCH
        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName,
                        ErrorSchema,
                        ErrorProcedure,
                        ErrorNumber,
                        ErrorState,
                        ErrorSeverity,
                        ErrorLine,
                        ErrorMessage,
                        ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName,
                        @ErrorSchema,
                        @ErrorProc,
                        @ErrorNumber,
                        @ErrorState,
                        @ErrorSeverity,
                        @ErrorLine,
                        LEFT(@ErrorMessage, 500),
                        @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName,
                ErrorSchema,
                ErrorProcedure,
                ErrorNumber,
                ErrorState,
                ErrorSeverity,
                ErrorLine,
                ErrorMessage,
                ErrorDateTime
            )
            VALUES
            (
                @UserName,
                @ErrorSchema,
                @ErrorProc,
                @ErrorNumber,
                @ErrorState,
                @ErrorSeverity,
                @ErrorLine,
                LEFT(@ErrorMessage, 500),
                @ErrorDateTime
            );
        END

        SET @TotalRecords = 0;
        SET @Message = 'Failed to retrieve patient list.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
-- END FILE: 006-stored-procedures/[Profile].[spListPatients].sql


-- BEGIN FILE: 006-stored-procedures/[Profile].[spRestorePatient].sql

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spRestorePatient]
(
    @IDNumber VARCHAR(250) = '',
    @Message VARCHAR(250) OUTPUT,
    @StatusCode INT OUTPUT
)
AS
BEGIN
    DECLARE @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME;

    SET NOCOUNT ON;

    SET @StatusCode = -1;
    SET @Message = '';

    BEGIN TRY
        IF LTRIM(RTRIM(@IDNumber)) = ''
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'ID number is required.';
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM Profile.Patient WHERE ID_Number = @IDNumber AND IsDeleted = 0)
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'Patient is already active.';
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM Profile.Patient WHERE ID_Number = @IDNumber AND IsDeleted = 1)
        BEGIN
            UPDATE Profile.Patient
            SET IsDeleted = 0,
                UpdatedDate = GETDATE(),
                UpdatedBy = SUSER_SNAME()
            WHERE ID_Number = @IDNumber
              AND IsDeleted = 1;

            SET @StatusCode = 0;
            SET @Message = '';
            RETURN;
        END

        SET @StatusCode = 1;
        SET @Message = 'Patient does not exist.';
    END TRY
    BEGIN CATCH
        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName,
                        ErrorSchema,
                        ErrorProcedure,
                        ErrorNumber,
                        ErrorState,
                        ErrorSeverity,
                        ErrorLine,
                        ErrorMessage,
                        ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName,
                        @ErrorSchema,
                        @ErrorProc,
                        @ErrorNumber,
                        @ErrorState,
                        @ErrorSeverity,
                        @ErrorLine,
                        LEFT(@ErrorMessage, 500),
                        @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName,
                ErrorSchema,
                ErrorProcedure,
                ErrorNumber,
                ErrorState,
                ErrorSeverity,
                ErrorLine,
                ErrorMessage,
                ErrorDateTime
            )
            VALUES
            (
                @UserName,
                @ErrorSchema,
                @ErrorProc,
                @ErrorNumber,
                @ErrorState,
                @ErrorSeverity,
                @ErrorLine,
                LEFT(@ErrorMessage, 500),
                @ErrorDateTime
            );
        END

        SET @StatusCode = -1;
        SET @Message = 'Failed to restore patient record.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
-- END FILE: 006-stored-procedures/[Profile].[spRestorePatient].sql


-- BEGIN FILE: 006-stored-procedures/[Profile].[spUpdateClientDepartment].sql

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spUpdateClientDepartment]
(
    @ClientDepartmentId UNIQUEIDENTIFIER,
    @DepartmentName VARCHAR(100),
    @DepartmentCode VARCHAR(50) = NULL,
    @DepartmentType VARCHAR(50),
    @IsActive BIT = 1,
    @UpdatedBy VARCHAR(250) = NULL,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE(),
            @ClientIdFK UNIQUEIDENTIFIER,
            @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME;

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @StatusCode = -1;
    SET @Message = '';

    IF @ClientDepartmentId IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientDepartmentId is required.';
        RETURN;
    END

    IF LTRIM(RTRIM(ISNULL(@DepartmentName, ''))) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'DepartmentName is required.';
        RETURN;
    END

    IF @DepartmentType NOT IN ('Clinical', 'Administrative', 'Support', 'Management', 'Allied')
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Invalid DepartmentType.';
        RETURN;
    END

    SELECT @ClientIdFK = ClientIdFK
    FROM Profile.ClientDepartments
    WHERE ClientDepartmentId = @ClientDepartmentId
      AND IsDeleted = 0;

    IF @ClientIdFK IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Client department not found or already deleted.';
        RETURN;
    END

    BEGIN TRY
        IF EXISTS
        (
            SELECT 1
            FROM Profile.ClientDepartments
            WHERE ClientIdFK = @ClientIdFK
              AND DepartmentName = LTRIM(RTRIM(@DepartmentName))
              AND ClientDepartmentId <> @ClientDepartmentId
              AND IsDeleted = 0
        )
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'Department name already exists for this client.';
            RETURN;
        END

        UPDATE Profile.ClientDepartments
        SET DepartmentCode = NULLIF(LTRIM(RTRIM(ISNULL(@DepartmentCode, ''))), ''),
            DepartmentName = LTRIM(RTRIM(@DepartmentName)),
            DepartmentType = @DepartmentType,
            IsActive = @IsActive,
            UpdatedDate = @Now,
            UpdatedBy = COALESCE(NULLIF(@UpdatedBy, ''), SUSER_SNAME())
        WHERE ClientDepartmentId = @ClientDepartmentId
          AND IsDeleted = 0;

        SET @StatusCode = 0;
        SET @Message = '';
    END TRY
    BEGIN CATCH
        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                        ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                        @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
            )
            VALUES
            (
                @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
            );
        END

        SET @StatusCode = -1;
        SET @Message = 'Failed to update client department.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
-- END FILE: 006-stored-procedures/[Profile].[spUpdateClientDepartment].sql


-- BEGIN FILE: 006-stored-procedures/[Profile].[spUpdateClientStaff].sql

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spUpdateClientStaff]
(
    @ClientStaffId UNIQUEIDENTIFIER,
    @RoleIdFK UNIQUEIDENTIFIER = NULL,
    @UserIdFK UNIQUEIDENTIFIER = NULL,
    @ProviderIdFK UNIQUEIDENTIFIER = NULL,
    @StaffCode VARCHAR(50),
    @FirstName VARCHAR(250),
    @LastName VARCHAR(250),
    @Email VARCHAR(250) = NULL,
    @PhoneNumber VARCHAR(25) = NULL,
    @JobTitle VARCHAR(150) = NULL,
    @Department VARCHAR(100) = NULL,
    @StaffType VARCHAR(50),
    @EmploymentType VARCHAR(50),
    @HireDate DATETIME = NULL,
    @TerminationDate DATETIME = NULL,
    @IsPrimaryContact BIT = 0,
    @IsActive BIT = 1,
    @UpdatedBy VARCHAR(250) = NULL,
    @StaffDesignationIdFK UNIQUEIDENTIFIER = NULL,
    @PrimaryDepartmentIdFK UNIQUEIDENTIFIER = NULL,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE(),
            @ClientIdFK UNIQUEIDENTIFIER,
            @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME,
            @NormalizedPhone VARCHAR(25),
            @FormattedPhone VARCHAR(25);

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @StatusCode = -1;
    SET @Message = '';

    IF @ClientStaffId IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientStaffId is required.';
        RETURN;
    END

    IF LTRIM(RTRIM(ISNULL(@StaffCode, ''))) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'StaffCode is required.';
        RETURN;
    END

    IF LTRIM(RTRIM(ISNULL(@FirstName, ''))) = '' OR LTRIM(RTRIM(ISNULL(@LastName, ''))) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'FirstName and LastName are required.';
        RETURN;
    END

    IF @TerminationDate IS NOT NULL AND @HireDate IS NOT NULL AND @TerminationDate < @HireDate
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'TerminationDate cannot be before HireDate.';
        RETURN;
    END

    SELECT @ClientIdFK = ClientIdFK
    FROM Profile.ClientStaff
    WHERE ClientStaffId = @ClientStaffId
      AND IsDeleted = 0;

    IF @ClientIdFK IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Client staff not found or already deleted.';
        RETURN;
    END

    IF @RoleIdFK IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Auth.Roles WHERE RoleId = @RoleIdFK)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'RoleIdFK does not exist.';
        RETURN;
    END

    IF @UserIdFK IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Auth.Users WHERE UserId = @UserIdFK)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'UserIdFK does not exist.';
        RETURN;
    END

    IF @ProviderIdFK IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Profile.HealthcareProviders WHERE ProviderId = @ProviderIdFK)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ProviderIdFK does not exist.';
        RETURN;
    END

    IF @StaffDesignationIdFK IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Profile.StaffDesignations WHERE StaffDesignationId = @StaffDesignationIdFK AND IsActive = 1)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'StaffDesignationIdFK does not exist or is inactive.';
        RETURN;
    END

    IF @PrimaryDepartmentIdFK IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM Profile.ClientDepartments
           WHERE ClientDepartmentId = @PrimaryDepartmentIdFK
             AND ClientIdFK = @ClientIdFK
             AND IsDeleted = 0
       )
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'PrimaryDepartmentIdFK does not belong to this client.';
        RETURN;
    END

    IF NULLIF(LTRIM(RTRIM(ISNULL(@Email, ''))), '') IS NOT NULL
       AND @Email NOT LIKE '%_@_%._%'
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Invalid email format.';
        RETURN;
    END

    SET @NormalizedPhone = LTRIM(RTRIM(ISNULL(@PhoneNumber, '')));
    IF @NormalizedPhone <> ''
    BEGIN
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '-', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, ' ', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '+', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '(', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, ')', '');

        IF LEN(@NormalizedPhone) <> 10 OR @NormalizedPhone LIKE '%[^0-9]%'
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'PhoneNumber must contain exactly 10 digits.';
            RETURN;
        END

        SET @FormattedPhone = SUBSTRING(@NormalizedPhone, 1, 3) + '-' +
                              SUBSTRING(@NormalizedPhone, 4, 3) + '-' +
                              SUBSTRING(@NormalizedPhone, 7, 4);
    END
    ELSE
    BEGIN
        SET @FormattedPhone = NULL;
    END

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM Profile.ClientStaff WHERE StaffCode = @StaffCode AND ClientStaffId <> @ClientStaffId)
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'StaffCode already exists.';
            RETURN;
        END

        IF NULLIF(LTRIM(RTRIM(ISNULL(@Email, ''))), '') IS NOT NULL
           AND EXISTS
           (
               SELECT 1
               FROM Profile.ClientStaff
               WHERE ClientIdFK = @ClientIdFK
                 AND Email = LTRIM(RTRIM(@Email))
                 AND IsDeleted = 0
                 AND ClientStaffId <> @ClientStaffId
           )
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'Email already exists for this client.';
            RETURN;
        END

        UPDATE Profile.ClientStaff
        SET RoleIdFK = @RoleIdFK,
            UserIdFK = @UserIdFK,
            ProviderIdFK = @ProviderIdFK,
            StaffCode = @StaffCode,
            FirstName = @FirstName,
            LastName = @LastName,
            Email = NULLIF(LTRIM(RTRIM(ISNULL(@Email, ''))), ''),
            PhoneNumber = @FormattedPhone,
            JobTitle = NULLIF(LTRIM(RTRIM(ISNULL(@JobTitle, ''))), ''),
            Department = NULLIF(LTRIM(RTRIM(ISNULL(@Department, ''))), ''),
            StaffDesignationIdFK = COALESCE(@StaffDesignationIdFK, StaffDesignationIdFK),
            PrimaryDepartmentIdFK = COALESCE(@PrimaryDepartmentIdFK, PrimaryDepartmentIdFK),
            StaffType = @StaffType,
            EmploymentType = @EmploymentType,
            HireDate = @HireDate,
            TerminationDate = @TerminationDate,
            IsPrimaryContact = @IsPrimaryContact,
            IsActive = @IsActive,
            UpdatedDate = @Now,
            UpdatedBy = COALESCE(NULLIF(@UpdatedBy, ''), SUSER_SNAME())
        WHERE ClientStaffId = @ClientStaffId
          AND IsDeleted = 0;

        IF @IsPrimaryContact = 1
        BEGIN
            UPDATE Profile.ClientStaff
            SET IsPrimaryContact = CASE WHEN ClientStaffId = @ClientStaffId THEN 1 ELSE 0 END,
                UpdatedDate = @Now,
                UpdatedBy = COALESCE(NULLIF(@UpdatedBy, ''), SUSER_SNAME())
            WHERE ClientIdFK = @ClientIdFK
              AND IsDeleted = 0;
        END

        SET @StatusCode = 0;
        SET @Message = '';
    END TRY
    BEGIN CATCH
        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                        ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                        @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
            )
            VALUES
            (
                @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
            );
        END

        SET @StatusCode = -1;
        SET @Message = 'Failed to update client staff record.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
-- END FILE: 006-stored-procedures/[Profile].[spUpdateClientStaff].sql


-- BEGIN FILE: 006-stored-procedures/[Profile].[spUpdateClient].sql

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spUpdateClient]
(
    @ClientId UNIQUEIDENTIFIER,
    @ClientCode VARCHAR(50),
    @FirstName VARCHAR(250),
    @LastName VARCHAR(250),
    @DateOfBirth DATETIME = NULL,
    @ID_Number VARCHAR(250) = NULL,
    @Email VARCHAR(250) = NULL,
    @PhoneNumber VARCHAR(25) = NULL,
    @AddressIDFK UNIQUEIDENTIFIER = NULL,
    @PatientIdFK UNIQUEIDENTIFIER = NULL,
    @ClientClinicCategoryIDFK INT = NULL,
    @IsActive BIT = 1,
    @UpdatedBy VARCHAR(250) = NULL,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE(),
            @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME,
            @NormalizedPhone VARCHAR(25),
            @FormattedPhone VARCHAR(25);

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @StatusCode = -1;
    SET @Message = '';

    IF @ClientId IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientId is required.';
        RETURN;
    END

    IF LTRIM(RTRIM(ISNULL(@ClientCode, ''))) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientCode is required.';
        RETURN;
    END

    IF LTRIM(RTRIM(ISNULL(@FirstName, ''))) = '' OR LTRIM(RTRIM(ISNULL(@LastName, ''))) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'FirstName and LastName are required.';
        RETURN;
    END

    IF @DateOfBirth IS NOT NULL AND @DateOfBirth > GETDATE()
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'DateOfBirth cannot be in the future.';
        RETURN;
    END

    IF NULLIF(LTRIM(RTRIM(ISNULL(@Email, ''))), '') IS NOT NULL
       AND @Email NOT LIKE '%_@_%._%'
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Invalid email format.';
        RETURN;
    END

    IF @AddressIDFK IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Location.Address WHERE AddressId = @AddressIDFK)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'AddressIDFK does not exist.';
        RETURN;
    END

    IF @PatientIdFK IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Profile.Patient WHERE PatientId = @PatientIdFK)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'PatientIdFK does not exist.';
        RETURN;
    END

    IF @ClientClinicCategoryIDFK IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM Profile.ClientClinicCategories CCC
           WHERE CCC.ClientClinicCategoryId = @ClientClinicCategoryIDFK
             AND CCC.IsActive = 1
       )
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientClinicCategoryIDFK does not exist or is inactive.';
        RETURN;
    END

    SET @NormalizedPhone = LTRIM(RTRIM(ISNULL(@PhoneNumber, '')));
    IF @NormalizedPhone <> ''
    BEGIN
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '-', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, ' ', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '+', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '(', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, ')', '');

        IF LEN(@NormalizedPhone) <> 10 OR @NormalizedPhone LIKE '%[^0-9]%'
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'PhoneNumber must contain exactly 10 digits.';
            RETURN;
        END

        SET @FormattedPhone = SUBSTRING(@NormalizedPhone, 1, 3) + '-' +
                              SUBSTRING(@NormalizedPhone, 4, 3) + '-' +
                              SUBSTRING(@NormalizedPhone, 7, 4);
    END
    ELSE
    BEGIN
        SET @FormattedPhone = NULL;
    END

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Profile.Clients WHERE ClientId = @ClientId AND IsDeleted = 0)
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'Client not found or already deleted.';
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM Profile.Clients WHERE ClientCode = @ClientCode AND ClientId <> @ClientId)
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'ClientCode already exists.';
            RETURN;
        END

        IF @PatientIdFK IS NOT NULL
           AND EXISTS (SELECT 1 FROM Profile.Clients WHERE PatientIdFK = @PatientIdFK AND ClientId <> @ClientId)
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'A client is already linked to this PatientIdFK.';
            RETURN;
        END

        UPDATE Profile.Clients
        SET ClientCode = @ClientCode,
            FirstName = @FirstName,
            LastName = @LastName,
            DateOfBirth = @DateOfBirth,
            ID_Number = NULLIF(LTRIM(RTRIM(ISNULL(@ID_Number, ''))), ''),
            Email = NULLIF(LTRIM(RTRIM(ISNULL(@Email, ''))), ''),
            PhoneNumber = @FormattedPhone,
            AddressIDFK = @AddressIDFK,
            PatientIdFK = @PatientIdFK,
            ClientClinicCategoryIDFK = @ClientClinicCategoryIDFK,
            IsActive = @IsActive,
            UpdatedDate = @Now,
            UpdatedBy = COALESCE(NULLIF(@UpdatedBy, ''), SUSER_SNAME())
        WHERE ClientId = @ClientId
          AND IsDeleted = 0;

        SET @StatusCode = 0;
        SET @Message = '';
    END TRY
    BEGIN CATCH
        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                        ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                        @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
            )
            VALUES
            (
                @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
            );
        END

        SET @StatusCode = -1;
        SET @Message = 'Failed to update client record.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
-- END FILE: 006-stored-procedures/[Profile].[spUpdateClient].sql


-- BEGIN FILE: 006-stored-procedures/[Profile].[spUpdatePatient].sql

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spUpdatePatient]
(
    @FirstName VARCHAR(250) = '',
    @LastName VARCHAR(250) = '',
    @ID_Number VARCHAR(250) = '',
    @DateOfBirth DATETIME = NULL,
    @GenderIDFK INT = 0,
    @PhoneNumber VARCHAR(250) = '',
    @Email VARCHAR(250) = '',
    @Line1 VARCHAR(250) = '',
    @Line2 VARCHAR(250) = '',
    @CityIDFK INT = 0,
    @ProvinceIDFK INT = 0,
    @CountryIDFK INT = 0,
    @MaritalStatusIDFK INT = 0,
    @MedicationList VARCHAR(MAX) = '',
    @EmergencyName VARCHAR(250) = '',
    @EmergencyLastName VARCHAR(250) = '',
    @EmergencyPhoneNumber VARCHAR(250) = '',
    @Relationship VARCHAR(250) = '',
    @EmergancyDateOfBirth DATETIME = NULL,
    @Message VARCHAR(250) OUTPUT,
    @ClientIdFK UNIQUEIDENTIFIER = NULL
)
AS
BEGIN
    DECLARE @DefaultDate DATETIME = GETDATE(),
            @PatientId UNIQUEIDENTIFIER,
            @AddressId UNIQUEIDENTIFIER,
            @EmergencyId UNIQUEIDENTIFIER,
            @EmailId UNIQUEIDENTIFIER,
            @PhoneId UNIQUEIDENTIFIER,
            @NormalizedPhone VARCHAR(50),
            @NormalizedEmergencyPhone VARCHAR(50),
            @FormattedPhone VARCHAR(15),
            @FormattedEmergencyPhone VARCHAR(15),
            @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME;

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Validation parity with spAddPatient
    IF LTRIM(RTRIM(@ID_Number)) = ''
    BEGIN
        SET @Message = 'ID number is required.';
        RETURN;
    END

    IF LTRIM(RTRIM(@FirstName)) = '' OR LTRIM(RTRIM(@LastName)) = ''
    BEGIN
        SET @Message = 'First name and last name are required.';
        RETURN;
    END

    IF @DateOfBirth IS NULL OR @DateOfBirth > GETDATE()
    BEGIN
        SET @Message = 'Invalid date of birth.';
        RETURN;
    END

    IF @EmergancyDateOfBirth IS NULL OR @EmergancyDateOfBirth > GETDATE()
    BEGIN
        SET @Message = 'Invalid emergency contact date of birth.';
        RETURN;
    END

    IF @GenderIDFK <= 0 OR @MaritalStatusIDFK <= 0 OR @CityIDFK <= 0
    BEGIN
        SET @Message = 'Gender, marital status and city are required.';
        RETURN;
    END

    IF LTRIM(RTRIM(@Email)) = '' OR @Email NOT LIKE '%_@_%._%'
    BEGIN
        SET @Message = 'A valid email address is required.';
        RETURN;
    END

    SET @NormalizedPhone = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@PhoneNumber)), '-', ''), ' ', ''), '+', ''), '(', ''), ')', '');
    SET @NormalizedEmergencyPhone = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@EmergencyPhoneNumber)), '-', ''), ' ', ''), '+', ''), '(', ''), ')', '');

    IF LEN(@NormalizedPhone) <> 10 OR @NormalizedPhone LIKE '%[^0-9]%'
    BEGIN
        SET @Message = 'Phone number must contain exactly 10 digits.';
        RETURN;
    END

    IF LEN(@NormalizedEmergencyPhone) <> 10 OR @NormalizedEmergencyPhone LIKE '%[^0-9]%'
    BEGIN
        SET @Message = 'Emergency phone number must contain exactly 10 digits.';
        RETURN;
    END

    IF @ProvinceIDFK > 0
    BEGIN
        IF NOT EXISTS
        (
            SELECT 1
            FROM Location.Cities C
            WHERE C.CityId = @CityIDFK
              AND C.ProvinceIDFK = @ProvinceIDFK
        )
        BEGIN
            SET @Message = 'City and province combination is invalid.';
            RETURN;
        END
    END

    IF @CountryIDFK > 0
    BEGIN
        IF NOT EXISTS
        (
            SELECT 1
            FROM Location.Cities C
            INNER JOIN Location.Provinces P ON P.ProvinceId = C.ProvinceIDFK
            WHERE C.CityId = @CityIDFK
              AND P.CountryIDFK = @CountryIDFK
        )
        BEGIN
            SET @Message = 'City and country combination is invalid.';
            RETURN;
        END
    END

    IF @ClientIdFK IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Profile.Clients WHERE ClientId = @ClientIdFK AND IsDeleted = 0)
    BEGIN
        SET @Message = 'Invalid ClientIdFK.';
        RETURN;
    END

    BEGIN TRY
        BEGIN TRAN;

        SELECT
            @PatientId = PatientId,
            @AddressId = AddressIDFK,
            @EmergencyId = EmergencyIDFK
        FROM Profile.Patient
        WHERE ID_Number = @ID_Number
          AND IsDeleted = 0;

        IF @PatientId IS NULL
        BEGIN
            SET @Message = 'Sorry User [' + @ID_Number + '] does not exist, please verify and try again';
            ROLLBACK TRAN;
            RETURN;
        END

        SET @FormattedPhone =
            SUBSTRING(@NormalizedPhone, 1, 3) + '-' +
            SUBSTRING(@NormalizedPhone, 4, 3) + '-' +
            SUBSTRING(@NormalizedPhone, 7, 4);

        SET @FormattedEmergencyPhone =
            SUBSTRING(@NormalizedEmergencyPhone, 1, 3) + '-' +
            SUBSTRING(@NormalizedEmergencyPhone, 4, 3) + '-' +
            SUBSTRING(@NormalizedEmergencyPhone, 7, 4);

        IF @AddressId IS NULL
        BEGIN
            SET @AddressId = NEWID();
            INSERT INTO Location.Address (AddressId, Line1, Line2, CityIDFK, UpdateDate)
            VALUES (@AddressId, @Line1, @Line2, @CityIDFK, @DefaultDate);
        END
        ELSE
        BEGIN
            UPDATE Location.Address
            SET Line1 = @Line1,
                Line2 = @Line2,
                CityIDFK = @CityIDFK,
                UpdateDate = @DefaultDate,
                UpdatedBy = SUSER_SNAME()
            WHERE AddressId = @AddressId;
        END

        IF @EmergencyId IS NULL
        BEGIN
            SET @EmergencyId = NEWID();
            INSERT INTO Contacts.EmergencyContacts
            (
                EmergencyId,
                FirstName,
                LastName,
                PhoneNumber,
                Relationship,
                DateOfBirth,
                IsActive,
                UpdateDate
            )
            VALUES
            (
                @EmergencyId,
                @EmergencyName,
                @EmergencyLastName,
                @FormattedEmergencyPhone,
                @Relationship,
                @EmergancyDateOfBirth,
                1,
                @DefaultDate
            );
        END
        ELSE
        BEGIN
            UPDATE Contacts.EmergencyContacts
            SET FirstName = @EmergencyName,
                LastName = @EmergencyLastName,
                PhoneNumber = @FormattedEmergencyPhone,
                Relationship = @Relationship,
                DateOfBirth = @EmergancyDateOfBirth,
                UpdateDate = @DefaultDate
            WHERE EmergencyId = @EmergencyId;
        END

        SELECT @EmailId = E.EmailId FROM Contacts.Emails E WHERE E.Email = @Email;
        IF @EmailId IS NULL
        BEGIN
            SET @EmailId = NEWID();
            INSERT INTO Contacts.Emails (EmailId, Email, IsActive, UpdateDate)
            VALUES (@EmailId, @Email, 1, @DefaultDate);
        END

        SELECT @PhoneId = P.PhoneId FROM Contacts.Phones P WHERE P.PhoneNumber = @FormattedPhone;
        IF @PhoneId IS NULL
        BEGIN
            SET @PhoneId = NEWID();
            INSERT INTO Contacts.Phones (PhoneId, PhoneNumber, IsActive, UpdateDate)
            VALUES (@PhoneId, @FormattedPhone, 1, @DefaultDate);
        END

        IF NOT EXISTS (SELECT 1 FROM Contacts.PatientEmails WHERE PatientIdFK = @PatientId AND EmailIdFK = @EmailId)
        BEGIN
            INSERT INTO Contacts.PatientEmails (PatientEmailId, PatientIdFK, EmailIdFK, IsPrimary, EmailType)
            VALUES (NEWID(), @PatientId, @EmailId, 1, 'Primary');
        END

        UPDATE Contacts.PatientEmails
        SET IsPrimary = CASE WHEN EmailIdFK = @EmailId THEN 1 ELSE 0 END,
            UpdatedDate = @DefaultDate,
            UpdatedBy = SUSER_SNAME()
        WHERE PatientIdFK = @PatientId;

        IF NOT EXISTS (SELECT 1 FROM Contacts.PatientPhones WHERE PatientIdFK = @PatientId AND PhoneIdFK = @PhoneId)
        BEGIN
            INSERT INTO Contacts.PatientPhones (PatientPhoneId, PatientIdFK, PhoneIdFK, IsPrimary, PhoneType)
            VALUES (NEWID(), @PatientId, @PhoneId, 1, 'Primary');
        END

        UPDATE Contacts.PatientPhones
        SET IsPrimary = CASE WHEN PhoneIdFK = @PhoneId THEN 1 ELSE 0 END,
            UpdatedDate = @DefaultDate,
            UpdatedBy = SUSER_SNAME()
        WHERE PatientIdFK = @PatientId;

        UPDATE Profile.Patient
        SET FirstName = @FirstName,
            LastName = @LastName,
            DateOfBirth = @DateOfBirth,
            GenderIDFK = @GenderIDFK,
            MedicationList = @MedicationList,
            ClientIdFK = COALESCE(@ClientIdFK, ClientIdFK),
            AddressIDFK = @AddressId,
            MaritalStatusIDFK = @MaritalStatusIDFK,
            EmergencyIDFK = @EmergencyId,
            UpdatedDate = @DefaultDate,
            UpdatedBy = SUSER_SNAME()
        WHERE PatientId = @PatientId;

        COMMIT TRAN;
        SET @Message = '';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName,
                        ErrorSchema,
                        ErrorProcedure,
                        ErrorNumber,
                        ErrorState,
                        ErrorSeverity,
                        ErrorLine,
                        ErrorMessage,
                        ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName,
                        @ErrorSchema,
                        @ErrorProc,
                        @ErrorNumber,
                        @ErrorState,
                        @ErrorSeverity,
                        @ErrorLine,
                        LEFT(@ErrorMessage, 500),
                        @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName,
                ErrorSchema,
                ErrorProcedure,
                ErrorNumber,
                ErrorState,
                ErrorSeverity,
                ErrorLine,
                ErrorMessage,
                ErrorDateTime
            )
            VALUES
            (
                @UserName,
                @ErrorSchema,
                @ErrorProc,
                @ErrorNumber,
                @ErrorState,
                @ErrorSeverity,
                @ErrorLine,
                LEFT(@ErrorMessage, 500),
                @ErrorDateTime
            );
        END

        SET @Message = 'Failed to update patient record.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
-- END FILE: 006-stored-procedures/[Profile].[spUpdatePatient].sql


-- BEGIN FILE: 007-triggers-functions/Capitalize first letter body.sql

CREATE OR ALTER FUNCTION [dbo].[CapitalizeFirstLetterBody]
(
    @InputString VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
AS
BEGIN
    IF @InputString IS NULL
        RETURN NULL;

    DECLARE @Index INT,
            @Char CHAR(1),
            @PrevChar CHAR(1),
            @OutputString VARCHAR(MAX);

    SET @OutputString = LOWER(@InputString);
    SET @Index = 1;

    WHILE @Index <= LEN(@InputString)
    BEGIN
        SET @Char = SUBSTRING(@InputString, @Index, 1);
        SET @PrevChar = CASE WHEN @Index = 1 THEN ' '
                             ELSE SUBSTRING(@InputString, @Index - 1, 1)
                        END;

        IF @PrevChar IN (';', ':', '!', '?', ',', '.', '_', '-', '/', '&', '''', '(')
        BEGIN
            IF @PrevChar <> ''''
                SET @OutputString = STUFF(@OutputString, @Index, 1, UPPER(@Char));
        END

        SET @Index = @Index + 1;
    END

    RETURN @OutputString;
END
GO
-- END FILE: 007-triggers-functions/Capitalize first letter body.sql


-- BEGIN FILE: 007-triggers-functions/Capitalize first letter.sql

CREATE OR ALTER FUNCTION [dbo].[CapitalizeFirstLetter]
(
    @InputString VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
AS
BEGIN
    IF @InputString IS NULL
        RETURN NULL;

    DECLARE @Index INT,
            @Char CHAR(1),
            @PrevChar CHAR(1),
            @OutputString VARCHAR(MAX);

    SET @OutputString = LOWER(@InputString);
    SET @Index = 1;

    WHILE @Index <= LEN(@InputString)
    BEGIN
        SET @Char = SUBSTRING(@InputString, @Index, 1);
        SET @PrevChar = CASE WHEN @Index = 1 THEN ' '
                             ELSE SUBSTRING(@InputString, @Index - 1, 1)
                        END;

        IF @PrevChar IN (' ', ';', ':', '!', '?', ',', '.', '_', '-', '/', '&', '''', '(')
        BEGIN
            IF @PrevChar <> ''''
                SET @OutputString = STUFF(@OutputString, @Index, 1, UPPER(@Char));
        END

        SET @Index = @Index + 1;
    END

    RETURN @OutputString;
END
GO
-- END FILE: 007-triggers-functions/Capitalize first letter.sql


-- BEGIN FILE: 007-triggers-functions/Contacts.tr_EnforceSinglePrimaryPatientEmail.sql

CREATE OR ALTER TRIGGER [Contacts].[tr_EnforceSinglePrimaryPatientEmail]
ON [Contacts].[PatientEmails]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    SET NOCOUNT ON;

    ;WITH AffectedPatients AS
    (
        SELECT DISTINCT PatientIdFK FROM inserted
        UNION
        SELECT DISTINCT PatientIdFK FROM deleted
    ),
    PrimaryRows AS
    (
        SELECT
            PE.PatientEmailId,
            PE.PatientIdFK,
            ROW_NUMBER() OVER
            (
                PARTITION BY PE.PatientIdFK
                ORDER BY
                    CASE WHEN PE.IsPrimary = 1 THEN 0 ELSE 1 END,
                    ISNULL(PE.UpdatedDate, PE.CreatedDate) DESC,
                    PE.PatientEmailId DESC
            ) AS RN,
            SUM(CASE WHEN PE.IsPrimary = 1 THEN 1 ELSE 0 END)
                OVER (PARTITION BY PE.PatientIdFK) AS PrimaryCount
        FROM Contacts.PatientEmails PE
        INNER JOIN AffectedPatients AP ON AP.PatientIdFK = PE.PatientIdFK
    )
    UPDATE PE
    SET
        IsPrimary = CASE WHEN PR.RN = 1 THEN 1 ELSE 0 END,
        UpdatedDate = GETDATE(),
        UpdatedBy = SYSTEM_USER
    FROM Contacts.PatientEmails PE
    INNER JOIN PrimaryRows PR ON PR.PatientEmailId = PE.PatientEmailId
    WHERE
        (PR.PrimaryCount = 0 OR PR.PrimaryCount > 1)
        OR (PR.RN = 1 AND PE.IsPrimary = 0)
        OR (PR.RN > 1 AND PE.IsPrimary = 1);
END
GO
-- END FILE: 007-triggers-functions/Contacts.tr_EnforceSinglePrimaryPatientEmail.sql


-- BEGIN FILE: 007-triggers-functions/Contacts.tr_EnforceSinglePrimaryPatientPhone.sql

CREATE OR ALTER TRIGGER [Contacts].[tr_EnforceSinglePrimaryPatientPhone]
ON [Contacts].[PatientPhones]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    SET NOCOUNT ON;

    ;WITH AffectedPatients AS
    (
        SELECT DISTINCT PatientIdFK FROM inserted
        UNION
        SELECT DISTINCT PatientIdFK FROM deleted
    ),
    PrimaryRows AS
    (
        SELECT
            PP.PatientPhoneId,
            PP.PatientIdFK,
            ROW_NUMBER() OVER
            (
                PARTITION BY PP.PatientIdFK
                ORDER BY
                    CASE WHEN PP.IsPrimary = 1 THEN 0 ELSE 1 END,
                    ISNULL(PP.UpdatedDate, PP.CreatedDate) DESC,
                    PP.PatientPhoneId DESC
            ) AS RN,
            SUM(CASE WHEN PP.IsPrimary = 1 THEN 1 ELSE 0 END)
                OVER (PARTITION BY PP.PatientIdFK) AS PrimaryCount
        FROM Contacts.PatientPhones PP
        INNER JOIN AffectedPatients AP ON AP.PatientIdFK = PP.PatientIdFK
    )
    UPDATE PP
    SET
        IsPrimary = CASE WHEN PR.RN = 1 THEN 1 ELSE 0 END,
        UpdatedDate = GETDATE(),
        UpdatedBy = SYSTEM_USER
    FROM Contacts.PatientPhones PP
    INNER JOIN PrimaryRows PR ON PR.PatientPhoneId = PP.PatientPhoneId
    WHERE
        (PR.PrimaryCount = 0 OR PR.PrimaryCount > 1)
        OR (PR.RN = 1 AND PP.IsPrimary = 0)
        OR (PR.RN > 1 AND PP.IsPrimary = 1);
END
GO
-- END FILE: 007-triggers-functions/Contacts.tr_EnforceSinglePrimaryPatientPhone.sql


-- BEGIN FILE: 007-triggers-functions/Contacts.tr_NormalizeAndValidateEmail.sql

CREATE OR ALTER TRIGGER [Contacts].[tr_NormalizeAndValidateEmail]
ON [Contacts].[Emails]
AFTER INSERT, UPDATE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    SET NOCOUNT ON;

    DECLARE @Normalized TABLE
    (
        EmailId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        NormalizedEmail VARCHAR(250) NOT NULL
    );

    INSERT INTO @Normalized (EmailId, NormalizedEmail)
    SELECT
        I.EmailId,
        LTRIM(RTRIM(LOWER(I.Email)))
    FROM inserted I;

    IF EXISTS
    (
        SELECT 1
        FROM @Normalized N
        WHERE N.NormalizedEmail = ''
           OR N.NormalizedEmail LIKE '% %'
           OR N.NormalizedEmail NOT LIKE '%_@_%._%'
    )
    BEGIN
        RAISERROR('Invalid email address format.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    UPDATE E
    SET
        E.Email = N.NormalizedEmail,
        E.UpdateDate = GETDATE(),
        E.UpdatedBy = SYSTEM_USER
    FROM Contacts.Emails E
    INNER JOIN @Normalized N ON N.EmailId = E.EmailId
    WHERE ISNULL(E.Email, '') <> ISNULL(N.NormalizedEmail, '');
END
GO
-- END FILE: 007-triggers-functions/Contacts.tr_NormalizeAndValidateEmail.sql


-- BEGIN FILE: 007-triggers-functions/Contacts.tr_NormalizeAndValidatePhoneNumber.sql

CREATE OR ALTER TRIGGER [Contacts].[tr_NormalizeAndValidatePhoneNumber]
ON [Contacts].[Phones]
AFTER INSERT, UPDATE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    SET NOCOUNT ON;

    DECLARE @Normalized TABLE
    (
        PhoneId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        FormattedPhone VARCHAR(12) NULL
    );

    INSERT INTO @Normalized (PhoneId, FormattedPhone)
    SELECT
        I.PhoneId,
        [Contacts].[FormatPhoneNumber](I.PhoneNumber)
    FROM inserted I;

    IF EXISTS
    (
        SELECT 1
        FROM @Normalized N
        WHERE N.FormattedPhone IS NULL
    )
    BEGIN
        RAISERROR('Invalid phone number format. Use a 10-digit phone number.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    UPDATE P
    SET
        P.PhoneNumber = N.FormattedPhone,
        P.UpdateDate = GETDATE(),
        P.UpdatedBy = SYSTEM_USER
    FROM Contacts.Phones P
    INNER JOIN @Normalized N ON N.PhoneId = P.PhoneId
    WHERE ISNULL(P.PhoneNumber, '') <> ISNULL(N.FormattedPhone, '');
END
GO
-- END FILE: 007-triggers-functions/Contacts.tr_NormalizeAndValidatePhoneNumber.sql


-- BEGIN FILE: 007-triggers-functions/Format Phone Contact.sql

CREATE OR ALTER FUNCTION [Contacts].[FormatPhoneNumber]
(
    @PhoneNumber VARCHAR(25)
)
RETURNS VARCHAR(12)
AS
BEGIN
    DECLARE @Normalized VARCHAR(25);

    IF @PhoneNumber IS NULL
        RETURN NULL;

    SET @Normalized = LTRIM(RTRIM(@PhoneNumber));
    SET @Normalized = REPLACE(@Normalized, '-', '');
    SET @Normalized = REPLACE(@Normalized, ' ', '');
    SET @Normalized = REPLACE(@Normalized, '+', '');
    SET @Normalized = REPLACE(@Normalized, '(', '');
    SET @Normalized = REPLACE(@Normalized, ')', '');

    IF LEN(@Normalized) <> 10 OR @Normalized LIKE '%[^0-9]%'
        RETURN NULL;

    RETURN SUBSTRING(@Normalized, 1, 3) + '-' +
           SUBSTRING(@Normalized, 4, 3) + '-' +
           SUBSTRING(@Normalized, 7, 4);
END
GO
-- END FILE: 007-triggers-functions/Format Phone Contact.sql


-- BEGIN FILE: 007-triggers-functions/Profile.tr_ADeletePatient.sql

CREATE OR ALTER TRIGGER [Profile].[tr_ADeletePatient]
ON [Profile].[Patient]
INSTEAD OF DELETE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    SET NOCOUNT ON;

    INSERT INTO Auth.AuditLog
    (
        ModifiedTime,
        ModifiedBy,
        Operation,
        SchemaName,
        TableName,
        TableID,
        LogData
    )
    SELECT
        GETDATE(),
        SYSTEM_USER,
        'DeleteBlocked',
        'Profile',
        'Patient',
        D.PatientId,
        J.LogData
    FROM deleted D
    CROSS APPLY
    (
        SELECT LogData =
        (
            SELECT
                D.PatientId,
                D.FirstName,
                D.LastName,
                D.ID_Number,
                D.DateOfBirth,
                D.GenderIDFK,
                D.MedicationList,
                D.AddressIDFK,
                D.MaritalStatusIDFK,
                D.EmergencyIDFK,
                D.IsDeleted,
                D.CreatedDate,
                D.CreatedBy,
                D.UpdatedDate,
                D.UpdatedBy
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    ) J;

    RAISERROR('Hard delete is not allowed on Profile.Patient. Use soft delete (IsDeleted = 1).', 16, 1);
    ROLLBACK TRANSACTION;
    RETURN;
END
GO
-- END FILE: 007-triggers-functions/Profile.tr_ADeletePatient.sql


-- BEGIN FILE: 007-triggers-functions/Profile.tr_AUpdatePatient.sql

CREATE OR ALTER TRIGGER [Profile].[tr_AUpdatePatient]
ON [Profile].[Patient]
AFTER UPDATE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    SET NOCOUNT ON;

    ;WITH ChangedRows AS
    (
        SELECT I.*, D.PatientId AS DPatientId,
               D.FirstName AS DFirstName,
               D.LastName AS DLastName,
               D.ID_Number AS DID_Number,
               D.DateOfBirth AS DDateOfBirth,
               D.GenderIDFK AS DGenderIDFK,
               D.MedicationList AS DMedicationList,
               D.AddressIDFK AS DAddressIDFK,
               D.MaritalStatusIDFK AS DMaritalStatusIDFK,
               D.EmergencyIDFK AS DEmergencyIDFK,
               D.IsDeleted AS DIsDeleted,
               D.CreatedDate AS DCreatedDate,
               D.CreatedBy AS DCreatedBy,
               D.UpdatedDate AS DUpdatedDate,
               D.UpdatedBy AS DUpdatedBy
        FROM inserted I
        INNER JOIN deleted D ON D.PatientId = I.PatientId
        WHERE
            ISNULL(D.FirstName, '') <> ISNULL(I.FirstName, '') OR
            ISNULL(D.LastName, '') <> ISNULL(I.LastName, '') OR
            ISNULL(D.ID_Number, '') <> ISNULL(I.ID_Number, '') OR
            ISNULL(CONVERT(VARCHAR(30), D.DateOfBirth, 126), '') <> ISNULL(CONVERT(VARCHAR(30), I.DateOfBirth, 126), '') OR
            ISNULL(D.GenderIDFK, -1) <> ISNULL(I.GenderIDFK, -1) OR
            ISNULL(D.MedicationList, '') <> ISNULL(I.MedicationList, '') OR
            ISNULL(CONVERT(VARCHAR(36), D.AddressIDFK), '') <> ISNULL(CONVERT(VARCHAR(36), I.AddressIDFK), '') OR
            ISNULL(D.MaritalStatusIDFK, -1) <> ISNULL(I.MaritalStatusIDFK, -1) OR
            ISNULL(CONVERT(VARCHAR(36), D.EmergencyIDFK), '') <> ISNULL(CONVERT(VARCHAR(36), I.EmergencyIDFK), '') OR
            ISNULL(D.IsDeleted, 0) <> ISNULL(I.IsDeleted, 0) OR
            ISNULL(CONVERT(VARCHAR(30), D.CreatedDate, 126), '') <> ISNULL(CONVERT(VARCHAR(30), I.CreatedDate, 126), '') OR
            ISNULL(D.CreatedBy, '') <> ISNULL(I.CreatedBy, '') OR
            ISNULL(CONVERT(VARCHAR(30), D.UpdatedDate, 126), '') <> ISNULL(CONVERT(VARCHAR(30), I.UpdatedDate, 126), '') OR
            ISNULL(D.UpdatedBy, '') <> ISNULL(I.UpdatedBy, '')
    )
    INSERT INTO Auth.AuditLog
    (
        ModifiedTime,
        ModifiedBy,
        Operation,
        SchemaName,
        TableName,
        TableID,
        LogData
    )
    SELECT
        GETDATE(),
        SYSTEM_USER,
        'Updated',
        'Profile',
        'Patient',
        C.PatientId,
        J.LogData
    FROM ChangedRows C
    CROSS APPLY
    (
        SELECT LogData =
        (
            SELECT
                [Old] =
                (
                    SELECT
                        C.DPatientId AS PatientId,
                        C.DFirstName AS FirstName,
                        C.DLastName AS LastName,
                        C.DID_Number AS ID_Number,
                        C.DDateOfBirth AS DateOfBirth,
                        C.DGenderIDFK AS GenderIDFK,
                        C.DMedicationList AS MedicationList,
                        C.DAddressIDFK AS AddressIDFK,
                        C.DMaritalStatusIDFK AS MaritalStatusIDFK,
                        C.DEmergencyIDFK AS EmergencyIDFK,
                        C.DIsDeleted AS IsDeleted,
                        C.DCreatedDate AS CreatedDate,
                        C.DCreatedBy AS CreatedBy,
                        C.DUpdatedDate AS UpdatedDate,
                        C.DUpdatedBy AS UpdatedBy
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ),
                [New] =
                (
                    SELECT
                        C.PatientId,
                        C.FirstName,
                        C.LastName,
                        C.ID_Number,
                        C.DateOfBirth,
                        C.GenderIDFK,
                        C.MedicationList,
                        C.AddressIDFK,
                        C.MaritalStatusIDFK,
                        C.EmergencyIDFK,
                        C.IsDeleted,
                        C.CreatedDate,
                        C.CreatedBy,
                        C.UpdatedDate,
                        C.UpdatedBy
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                )
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    ) J;
END
GO
-- END FILE: 007-triggers-functions/Profile.tr_AUpdatePatient.sql


-- BEGIN FILE: 007-triggers-functions/Profile.tr_AfterInsertPatient.sql

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER TRIGGER [Profile].[tr_AfterInsertPatient]
ON [Profile].[Patient]
AFTER INSERT
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    SET NOCOUNT ON;

    INSERT INTO Auth.AuditLog
    (
        ModifiedTime,
        ModifiedBy,
        Operation,
        SchemaName,
        TableName,
        TableID,
        LogData
    )
    SELECT
        GETDATE(),
        SYSTEM_USER,
        'Inserted',
        'Profile',
        'Patient',
        I.PatientId,
        J.LogData
    FROM inserted I
    CROSS APPLY
    (
        SELECT LogData =
        (
            SELECT
                I.PatientId,
                I.FirstName,
                I.LastName,
                I.ID_Number,
                I.DateOfBirth,
                I.GenderIDFK,
                I.MedicationList,
                I.AddressIDFK,
                I.MaritalStatusIDFK,
                I.EmergencyIDFK,
                I.IsDeleted,
                I.CreatedDate,
                I.CreatedBy,
                I.UpdatedDate,
                I.UpdatedBy
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    ) J;
END
GO
-- END FILE: 007-triggers-functions/Profile.tr_AfterInsertPatient.sql


-- BEGIN FILE: 007-triggers-functions/Profile.tr_BlockPatientIDNumberUpdate.sql

CREATE OR ALTER TRIGGER [Profile].[tr_BlockPatientIDNumberUpdate]
ON [Profile].[Patient]
AFTER UPDATE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        INNER JOIN deleted D ON D.PatientId = I.PatientId
        WHERE ISNULL(I.ID_Number, '') <> ISNULL(D.ID_Number, '')
    )
    BEGIN
        RAISERROR('Updating Profile.Patient.ID_Number is not allowed.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO
-- END FILE: 007-triggers-functions/Profile.tr_BlockPatientIDNumberUpdate.sql


-- BEGIN FILE: 007-triggers-functions/Profile.tr_ValidateAppointmentStatusTransition.sql

CREATE OR ALTER TRIGGER [Profile].[tr_ValidateAppointmentStatusTransition]
ON [Profile].[Appointments]
AFTER UPDATE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    SET NOCOUNT ON;

    -- Prevent invalid status values.
    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        WHERE I.Status NOT IN ('Scheduled', 'In Progress', 'Completed', 'Cancelled', 'No-show', 'Rescheduled')
    )
    BEGIN
        RAISERROR('Invalid appointment status value.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Do not allow moving away from terminal statuses.
    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        INNER JOIN deleted D ON D.AppointmentId = I.AppointmentId
        WHERE D.Status IN ('Completed', 'Cancelled', 'No-show')
          AND I.Status <> D.Status
    )
    BEGIN
        RAISERROR('Cannot transition from terminal appointment status.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Require cancellation metadata when cancelling.
    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        INNER JOIN deleted D ON D.AppointmentId = I.AppointmentId
        WHERE I.Status = 'Cancelled'
          AND D.Status <> 'Cancelled'
          AND (NULLIF(LTRIM(RTRIM(ISNULL(I.CancellationReason, ''))), '') IS NULL
               OR NULLIF(LTRIM(RTRIM(ISNULL(I.CancelledBy, ''))), '') IS NULL
               OR I.CancelledDate IS NULL)
    )
    BEGIN
        RAISERROR('Cancelled appointments require CancellationReason, CancelledBy and CancelledDate.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO
-- END FILE: 007-triggers-functions/Profile.tr_ValidateAppointmentStatusTransition.sql
