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
    ALTER DATABASE HealthcareForm 
      MODIFY FILEGROUP PatientDataGroup DEFAULT;
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
CREATE TABLE Auth.AuditLog
(
	AuditLogID INT NOT NULL PRIMARY KEY IDENTITY (1,1),
	ModifiedTime DATETIME NOT NULL,
	ModifiedBy VARCHAR(250) NOT NULL,
	Operation VARCHAR(250) NOT NULL,
	SchemaName VARCHAR(250) NOT NULL,
	TableName VARCHAR(250) NOT NULL,
	TableID UNIQUEIDENTIFIER NOT NULL,
	LogData VARCHAR(MAX) NOT NULL,
)
GO

-- Auth.Permissions
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Auth].[Permissions](
	-- (Legacy duplicate seed block removed. The canonical, DDL-matching
	-- seed block (uses Alpha2Code / Alpha3Code / UpdateDate) is present
	-- further down in this file and will execute instead.)

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
GO
ALTER TABLE [Auth].[UserRoles] ADD DEFAULT (newid()) FOR [UserRoleId]
GO

-- Auth.Users
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
ALTER TABLE [Auth].[Users] ADD DEFAULT (newid()) FOR [UserId]
GO
CREATE INDEX IX_Users_Username ON [Auth].[Users]([Username])
GO
CREATE INDEX IX_Users_Email ON [Auth].[Users]([Email])
GO

-- Contacts.Emails
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
ALTER TABLE [Contacts].[Emails] ADD  DEFAULT (newid()) FOR [EmailId]
GO
CREATE INDEX IX_Emails_Email ON [Contacts].[Emails]([Email])
GO

-- Contacts.EmergencyContacts
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
ALTER TABLE [Contacts].[EmergencyContacts] ADD  DEFAULT (newid()) FOR [EmergencyId]
GO

-- Contacts.FormAttachments
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
ALTER TABLE [Contacts].[FormAttachments] ADD DEFAULT (newid()) FOR [FormAttachmentId]
GO
-- Foreign key: FormSubmissionIdFK -> Contacts.FormSubmissions will be added later
CREATE INDEX IX_FormAttachments_FormSubmissionIdFK ON [Contacts].[FormAttachments]([FormSubmissionIdFK])
GO
CREATE INDEX IX_FormAttachments_DocumentType ON [Contacts].[FormAttachments]([DocumentType])
GO
CREATE INDEX IX_FormAttachments_UploadedDate ON [Contacts].[FormAttachments]([UploadedDate])
GO

-- Contacts.FormFieldValues
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
ALTER TABLE [Contacts].[FormFieldValues] ADD DEFAULT (newid()) FOR [FormFieldValueId]
GO
CREATE INDEX IX_FormFieldValues_FormSubmissionIdFK ON [Contacts].[FormFieldValues]([FormSubmissionIdFK])
GO
CREATE INDEX IX_FormFieldValues_FieldName ON [Contacts].[FormFieldValues]([FieldName])
GO

-- Contacts.FormSubmissions
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
ALTER TABLE [Contacts].[FormSubmissions] ADD DEFAULT (newid()) FOR [FormSubmissionId]
GO
CREATE INDEX IX_FormSubmissions_PatientIdFK ON [Contacts].[FormSubmissions]([PatientIdFK])
GO
CREATE INDEX IX_FormSubmissions_FormTemplateIdFK ON [Contacts].[FormSubmissions]([FormTemplateIdFK])
GO
CREATE INDEX IX_FormSubmissions_Status ON [Contacts].[FormSubmissions]([Status])
GO
CREATE INDEX IX_FormSubmissions_SubmissionDate ON [Contacts].[FormSubmissions]([SubmissionDate])
GO

-- Contacts.FormTemplates
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
ALTER TABLE [Contacts].[FormTemplates] ADD DEFAULT (newid()) FOR [FormTemplateId]
GO

-- Contacts.PatientEmails
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
ALTER TABLE [Contacts].[PatientEmails] ADD DEFAULT (newid()) FOR [PatientEmailId]
GO
CREATE UNIQUE INDEX UX_PatientEmails_Unique ON [Contacts].[PatientEmails]([PatientIdFK], [EmailIdFK])
GO

-- Contacts.PatientPhones
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
ALTER TABLE [Contacts].[PatientPhones] ADD DEFAULT (newid()) FOR [PatientPhoneId]
GO
CREATE UNIQUE INDEX UX_PatientPhones_Unique ON [Contacts].[PatientPhones]([PatientIdFK], [PhoneIdFK])
GO

-- Contacts.Phones
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
ALTER TABLE [Contacts].[Phones] ADD  DEFAULT (newid()) FOR [PhoneId]
GO
CREATE INDEX IX_Phones_PhoneNumber ON [Contacts].[Phones]([PhoneNumber])
GO

-- Exceptions.Errors
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
GO

-- Location.Address
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
ALTER TABLE [Location].[Address] ADD  DEFAULT (newid()) FOR [AddressId]
GO
CREATE INDEX IX_Address_CityIDFK ON [Location].[Address]([CityIDFK])
GO

-- Location.Cities
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO

-- Location.Countries
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO

-- Location.Provinces
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO

-- Profile.Allergies
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
ALTER TABLE [Profile].[Allergies] ADD DEFAULT (newid()) FOR [AllergyId]
GO
CREATE INDEX IX_Allergies_PatientIdFK ON [Profile].[Allergies]([PatientIdFK])
GO

-- Profile.Appointments
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
ALTER TABLE [Profile].[Appointments] ADD DEFAULT (newid()) FOR [AppointmentId]
GO
CREATE INDEX IX_Appointments_PatientIdFK ON [Profile].[Appointments]([PatientIdFK])
GO

-- Profile.BillingCodes
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
ALTER TABLE [Profile].[BillingCodes] ADD DEFAULT (newid()) FOR [BillingCodeId]
GO

-- Profile.ConsultationNotes
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
ALTER TABLE [Profile].[ConsultationNotes] ADD DEFAULT (newid()) FOR [ConsultationNoteId]
GO

-- Profile.Gender
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO

-- Profile.HealthcareProviders
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
ALTER TABLE [Profile].[HealthcareProviders] ADD DEFAULT (newid()) FOR [ProviderId]
GO

-- Profile.InsuranceProviders
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
ALTER TABLE [Profile].[InsuranceProviders] ADD DEFAULT (newid()) FOR [InsuranceProviderId]
GO

-- Profile.Invoices
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
ALTER TABLE [Profile].[Invoices] ADD DEFAULT (newid()) FOR [InvoiceId]
GO

-- Profile.LabResults
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
ALTER TABLE [Profile].[LabResults] ADD DEFAULT (newid()) FOR [LabResultId]
GO

-- Profile.MaritalStatus
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO

-- Profile.MedicalHistory
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
ALTER TABLE [Profile].[MedicalHistory] ADD DEFAULT (newid()) FOR [MedicalHistoryId]
GO

-- Profile.Medications
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
ALTER TABLE [Profile].[Medications] ADD DEFAULT (newid()) FOR [MedicationId]
GO

-- Profile.PatientInsurance
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
ALTER TABLE [Profile].[PatientInsurance] ADD DEFAULT (newid()) FOR [PatientInsuranceId]
GO

-- Profile.Patient
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
ALTER TABLE [Profile].[Patient] ADD  DEFAULT (newid()) FOR [PatientId]
GO
CREATE INDEX IX_Patient_IDNumber ON [Profile].[Patient]([ID_Number])
GO
CREATE INDEX IX_Patient_LastName ON [Profile].[Patient]([LastName])
GO

-- Profile.Referrals
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
ALTER TABLE [Profile].[Referrals] ADD DEFAULT (newid()) FOR [ReferralId]
GO

-- Profile.Vaccinations
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
ALTER TABLE [Profile].[Vaccinations] ADD DEFAULT (newid()) FOR [VaccinationId]
GO

-- Auth.DB_Errors (legacy)
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
-- For brevity this master includes stored objects that are low-risk; complex SPs may be applied separately.
-- =================================================================================================
-- (If you want I can inline all stored procedures and triggers here as well.)

-- =================================================================================================
-- 7) Seed Lookup & Reference Data (inlined)
-- =================================================================================================
-- (Seed section consolidated further down; legacy duplicates removed.)

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
VALUES ('Male', 1, @GenderDate),
	   ('Female', 1, @GenderDate),
	   ('Other', 1, @GenderDate),
	   ('Prefer Not to Say', 1, @GenderDate)

PRINT 'Gender lookup table populated successfully'
GO

PRINT '[5/11] Initializing Marital Status lookup...'
-- Inlined: Insert Marital Status (adapted)
DECLARE @MaritalDate DATETIME = GETDATE()

INSERT INTO Profile.MaritalStatus (MaritalStatusDescription, IsActive, UpdateDate)
VALUES ('Single', 1, @MaritalDate),
	   ('Married', 1, @MaritalDate),
	   ('Widowed', 1, @MaritalDate),
	   ('Divorced', 1, @MaritalDate),
	   ('Separated', 1, @MaritalDate),
	   ('Domestic Partnership', 1, @MaritalDate)

PRINT 'Marital status lookup table populated successfully'
GO

-- Step 3: Initialize Auth roles and permissions
PRINT '[6/11] Initializing Auth Roles...'
DECLARE @RolesDate DATETIME = GETDATE()

INSERT INTO Auth.Roles (RoleName, Description, IsActive, CreatedDate, CreatedBy)
VALUES
	('ADMIN', 'System Administrator - Full system access', 1, @RolesDate, 'SYSTEM'),
	('DOCTOR', 'Medical Doctor - Patient care and clinical decision making', 1, @RolesDate, 'SYSTEM'),
	('NURSE', 'Registered Nurse - Patient care and monitoring', 1, @RolesDate, 'SYSTEM'),
	('RECEPTIONIST', 'Receptionist - Appointment scheduling and patient check-in', 1, @RolesDate, 'SYSTEM'),
	('PATIENT', 'Patient - Access own health records and appointment booking', 1, @RolesDate, 'SYSTEM'),
	('BILLING', 'Billing Administrator - Invoice and payment management', 1, @RolesDate, 'SYSTEM'),
	('PHARMACIST', 'Pharmacist - Medication management and dispensing', 1, @RolesDate, 'SYSTEM')

PRINT 'Auth roles inserted successfully'
GO

PRINT '[7/11] Initializing Auth Permissions...'
DECLARE @PermDate DATETIME = GETDATE()

INSERT INTO Auth.Permissions (PermissionId, PermissionName, Description, Category, Module, ActionType, IsActive, CreatedDate, CreatedBy)
VALUES
	-- Patient Management
	(NEWID(), 'Patient_Create', 'Create new patient record', 'PATIENT', 'CORE', 'CREATE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Patient_Read', 'View patient information', 'PATIENT', 'CORE', 'READ', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Patient_Update', 'Modify patient information', 'PATIENT', 'CORE', 'UPDATE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Patient_Delete', 'Delete patient record', 'PATIENT', 'CORE', 'DELETE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Patient_ViewAll', 'View all patients in system', 'PATIENT', 'CORE', 'READ', 1, @PermDate, 'SYSTEM'),

	-- Medical History
	(NEWID(), 'MedicalHistory_Create', 'Add medical history entry', 'CLINICAL', 'MEDICAL_HISTORY', 'CREATE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'MedicalHistory_Read', 'View medical history', 'CLINICAL', 'MEDICAL_HISTORY', 'READ', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'MedicalHistory_Update', 'Modify medical history', 'CLINICAL', 'MEDICAL_HISTORY', 'UPDATE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'MedicalHistory_Delete', 'Delete medical history entry', 'CLINICAL', 'MEDICAL_HISTORY', 'DELETE', 1, @PermDate, 'SYSTEM'),

	-- Appointments
	(NEWID(), 'Appointment_Create', 'Create appointment', 'CLINICAL', 'APPOINTMENTS', 'CREATE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Appointment_Read', 'View appointments', 'CLINICAL', 'APPOINTMENTS', 'READ', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Appointment_Update', 'Modify appointment', 'CLINICAL', 'APPOINTMENTS', 'UPDATE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Appointment_Cancel', 'Cancel appointment', 'CLINICAL', 'APPOINTMENTS', 'UPDATE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Appointment_ViewAll', 'View all appointments', 'CLINICAL', 'APPOINTMENTS', 'READ', 1, @PermDate, 'SYSTEM'),

	-- Medications
	(NEWID(), 'Medication_Create', 'Add medication record', 'CLINICAL', 'MEDICATIONS', 'CREATE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Medication_Read', 'View medication history', 'CLINICAL', 'MEDICATIONS', 'READ', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Medication_Update', 'Modify medication record', 'CLINICAL', 'MEDICATIONS', 'UPDATE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Medication_Delete', 'Remove medication record', 'CLINICAL', 'MEDICATIONS', 'DELETE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Medication_Manage', 'Manage all medications in system', 'CLINICAL', 'MEDICATIONS', 'MANAGE', 1, @PermDate, 'SYSTEM'),

	-- Consultation Notes
	(NEWID(), 'ConsultationNotes_Create', 'Create consultation notes', 'CLINICAL', 'NOTES', 'CREATE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'ConsultationNotes_Read', 'View consultation notes', 'CLINICAL', 'NOTES', 'READ', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'ConsultationNotes_Update', 'Modify consultation notes', 'CLINICAL', 'NOTES', 'UPDATE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'ConsultationNotes_Delete', 'Delete consultation notes', 'CLINICAL', 'NOTES', 'DELETE', 1, @PermDate, 'SYSTEM'),

	-- Forms
	(NEWID(), 'Form_Create', 'Create form template', 'WORKFLOW', 'FORMS', 'CREATE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Form_Read', 'View forms', 'WORKFLOW', 'FORMS', 'READ', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Form_Update', 'Modify form template', 'WORKFLOW', 'FORMS', 'UPDATE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Form_Delete', 'Delete form', 'WORKFLOW', 'FORMS', 'DELETE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Form_Submit', 'Submit form', 'WORKFLOW', 'FORMS', 'SUBMIT', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Form_Review', 'Review submitted forms', 'WORKFLOW', 'FORMS', 'REVIEW', 1, @PermDate, 'SYSTEM'),

	-- Invoices/Payments
	(NEWID(), 'Invoice_Create', 'Create invoice', 'BILLING', 'BILLING', 'CREATE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Invoice_Read', 'View invoices', 'BILLING', 'BILLING', 'READ', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Invoice_Update', 'Modify invoice', 'BILLING', 'BILLING', 'UPDATE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Invoice_Delete', 'Delete invoice', 'BILLING', 'BILLING', 'DELETE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Payment_Process', 'Process payment', 'BILLING', 'PAYMENTS', 'EXECUTE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Payment_View', 'View payment history', 'BILLING', 'PAYMENTS', 'READ', 1, @PermDate, 'SYSTEM'),

	-- Insurance
	(NEWID(), 'Insurance_Create', 'Create insurance record', 'BILLING', 'INSURANCE', 'CREATE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Insurance_Read', 'View insurance information', 'BILLING', 'INSURANCE', 'READ', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Insurance_Update', 'Modify insurance record', 'BILLING', 'INSURANCE', 'UPDATE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Insurance_Delete', 'Delete insurance record', 'BILLING', 'INSURANCE', 'DELETE', 1, @PermDate, 'SYSTEM'),

	-- Allergy
	(NEWID(), 'Allergy_Create', 'Add allergy record', 'CLINICAL', 'ALLERGY', 'CREATE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Allergy_Read', 'View allergy information', 'CLINICAL', 'ALLERGY', 'READ', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Allergy_Update', 'Modify allergy record', 'CLINICAL', 'ALLERGY', 'UPDATE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Allergy_Delete', 'Delete allergy record', 'CLINICAL', 'ALLERGY', 'DELETE', 1, @PermDate, 'SYSTEM'),

	-- Lab Results
	(NEWID(), 'LabResults_Create', 'Create lab results', 'CLINICAL', 'LABS', 'CREATE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'LabResults_Read', 'View lab results', 'CLINICAL', 'LABS', 'READ', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'LabResults_Update', 'Modify lab results', 'CLINICAL', 'LABS', 'UPDATE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'LabResults_Delete', 'Delete lab results', 'CLINICAL', 'LABS', 'DELETE', 1, @PermDate, 'SYSTEM'),

	-- System Admin & Referral
	(NEWID(), 'SystemAdmin_User', 'Manage users and roles', 'ADMIN', 'SYSTEM', 'MANAGE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'SystemAdmin_Audit', 'View audit logs', 'ADMIN', 'SYSTEM', 'READ', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'SystemAdmin_Reports', 'Generate system reports', 'ADMIN', 'SYSTEM', 'EXECUTE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'SystemAdmin_Settings', 'Modify system settings', 'ADMIN', 'SYSTEM', 'UPDATE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'SystemAdmin_Database', 'Database administration', 'ADMIN', 'SYSTEM', 'ADMIN', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Referral_Create', 'Create referral', 'CLINICAL', 'REFERRALS', 'CREATE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Referral_Read', 'View referrals', 'CLINICAL', 'REFERRALS', 'READ', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Referral_Update', 'Update referral status', 'CLINICAL', 'REFERRALS', 'UPDATE', 1, @PermDate, 'SYSTEM'),
	(NEWID(), 'Referral_Delete', 'Delete referral', 'CLINICAL', 'REFERRALS', 'DELETE', 1, @PermDate, 'SYSTEM')

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
SELECT NEWID(), @RoleId_ADMIN, PermissionId, @MapDate, 'SYSTEM' FROM Auth.Permissions

UNION ALL

SELECT NEWID(), @RoleId_DOCTOR, PermissionId, @MapDate, 'SYSTEM' FROM Auth.Permissions
WHERE PermissionName IN (
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

SELECT NEWID(), @RoleId_NURSE, PermissionId, @MapDate, 'SYSTEM' FROM Auth.Permissions
WHERE PermissionName IN (
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

SELECT NEWID(), @RoleId_RECEPTIONIST, PermissionId, @MapDate, 'SYSTEM' FROM Auth.Permissions
WHERE PermissionName IN (
	'Patient_Create', 'Patient_Read', 'Patient_Update', 'Patient_ViewAll',
	'Appointment_Create', 'Appointment_Read', 'Appointment_Update', 'Appointment_Cancel', 'Appointment_ViewAll',
	'Form_Read', 'Form_Submit',
	'Payment_View'
)

UNION ALL

SELECT NEWID(), @RoleId_PATIENT, PermissionId, @MapDate, 'SYSTEM' FROM Auth.Permissions
WHERE PermissionName IN (
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

SELECT NEWID(), @RoleId_BILLING, PermissionId, @MapDate, 'SYSTEM' FROM Auth.Permissions
WHERE PermissionName IN (
	'Patient_Read', 'Patient_ViewAll',
	'Appointment_Read', 'Appointment_ViewAll',
	'Invoice_Create', 'Invoice_Read', 'Invoice_Update', 'Invoice_Delete',
	'Payment_Process', 'Payment_View',
	'Insurance_Create', 'Insurance_Read', 'Insurance_Update', 'Insurance_Delete'
)

UNION ALL

SELECT NEWID(), @RoleId_PHARMACIST, PermissionId, @MapDate, 'SYSTEM' FROM Auth.Permissions
WHERE PermissionName IN (
	'Patient_Read', 'Patient_ViewAll',
	'Medication_Create', 'Medication_Read', 'Medication_Update', 'Medication_Delete', 'Medication_Manage',
	'Prescription_Read',
	'Allergy_Read'
)

PRINT 'Role permissions mapped successfully'
GO

PRINT '[9/11] Creating initial admin user...'
-- Create admin user and assign role (use GUIDs)
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
GO

-- Step 4: Initialize Billing Codes (adapted to Profile schema)
PRINT '[10/11] Initializing Billing Codes...'
DECLARE @BillingDefaultDate DATETIME = GETDATE()

INSERT INTO Profile.BillingCodes (BillingCodeId, CodeType, Code, Description, Category, Cost, EffectiveDate, IsActive, CreatedDate, CreatedBy)
VALUES
	-- ICD-10 Common Diagnoses
	(NEWID(), 'ICD-10', 'E10.9', 'Type 1 diabetes mellitus without complications', 'ENDOCRINE', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'ICD-10', 'E11.9', 'Type 2 diabetes mellitus without complications', 'ENDOCRINE', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'ICD-10', 'E78.5', 'Hyperlipidemia, unspecified', 'METABOLIC', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'ICD-10', 'I10', 'Essential (primary) hypertension', 'CARDIOVASCULAR', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'ICD-10', 'I21.9', 'ST elevation (STEMI) and non-ST elevation (NSTEMI) of unspecified site', 'CARDIOVASCULAR', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'ICD-10', 'I50.9', 'Heart failure, unspecified', 'CARDIOVASCULAR', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'ICD-10', 'J45.901', 'Unspecified asthma with (acute) exacerbation', 'RESPIRATORY', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'ICD-10', 'J06.9', 'Acute upper respiratory infection, unspecified', 'RESPIRATORY', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'ICD-10', 'J44.9', 'Chronic obstructive pulmonary disease, unspecified', 'RESPIRATORY', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'ICD-10', 'F41.1', 'Generalized anxiety disorder', 'PSYCHIATRIC', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'ICD-10', 'F32.9', 'Major depressive disorder, single episode, unspecified', 'PSYCHIATRIC', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'ICD-10', 'F33.9', 'Major depressive disorder, recurrent, unspecified', 'PSYCHIATRIC', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'ICD-10', 'K21.9', 'Unspecified gastro-esophageal reflux disease', 'GASTROINTESTINAL', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'ICD-10', 'K29.7', 'Gastritis, unspecified', 'GASTROINTESTINAL', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'ICD-10', 'K80.9', 'Unspecified cholelithiasis', 'GASTROINTESTINAL', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'ICD-10', 'M79.3', 'Panniculitis, unspecified', 'MUSCULOSKELETAL', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'ICD-10', 'M15.9', 'Unspecified osteoarthritis', 'MUSCULOSKELETAL', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'ICD-10', 'M17.11', 'Primary osteoarthritis, right knee', 'MUSCULOSKELETAL', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'ICD-10', 'M54.5', 'Low back pain', 'MUSCULOSKELETAL', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'ICD-10', 'N39.0', 'Urinary tract infection, site not specified', 'GENITOURINARY', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),

	-- CPT Procedure Codes
	(NEWID(), 'CPT', '99213', 'Office visit for established patient - low complexity', 'CONSULTATION', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'CPT', '99214', 'Office visit for established patient - moderate complexity', 'CONSULTATION', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'CPT', '99215', 'Office visit for established patient - high complexity', 'CONSULTATION', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'CPT', '99232', 'Inpatient hospital visit - established patient - low complexity', 'INPATIENT', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'CPT', '93000', 'Electrocardiogram - complete', 'DIAGNOSTIC', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'CPT', '70450', 'Computed tomography, head or brain - without contrast', 'DIAGNOSTIC', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'CPT', '71020', 'Chest X-ray - 2 views', 'DIAGNOSTIC', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'CPT', '80053', 'Comprehensive metabolic panel', 'LABORATORY', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'CPT', '85025', 'Complete blood count - automated', 'LABORATORY', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'CPT', '80061', 'Lipid panel', 'LABORATORY', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'CPT', '92004', 'Comprehensive eye exam - new patient', 'SPECIALTY', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'CPT', '29881', 'Arthroscopy, knee - diagnostic', 'SURGICAL', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'CPT', '49505', 'Repair initial inguinal hernia', 'SURGICAL', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'CPT', '47562', 'Laparoscopic cholecystectomy', 'SURGICAL', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),

	-- HCPCS Service Codes
	(NEWID(), 'HCPCS', 'J1100', 'Injection, dexamethasone sodium phosphate - 4mg', 'INJECTION', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'HCPCS', 'J1110', 'Injection, dihydroergotamine mesylate - per 1mg', 'INJECTION', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'HCPCS', 'J3301', 'Triamcinolone acetonide, preservative-free', 'INJECTION', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'HCPCS', 'E0781', 'Ambulatory infusion pump - stationary or single speed', 'EQUIPMENT', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM'),
	(NEWID(), 'HCPCS', 'E1390', 'Oxygen concentrator, portable - rental', 'EQUIPMENT', 0.00, @BillingDefaultDate, 1, @BillingDefaultDate, 'SYSTEM')

PRINT 'Billing codes inserted successfully'
GO

PRINT '[11/11] Initializing Healthcare Providers and Insurance...'
-- Healthcare providers (map ProviderName -> FirstName)
DECLARE @ProvidersDefaultDate DATETIME = GETDATE()

INSERT INTO Profile.HealthcareProviders (ProviderId, FirstName, LastName, Title, Specialization, LicenseNumber, RegistrationBody, ProviderType, Qualifications, YearsOfExperience, OfficeAddressIdFK, IsActive, CreatedDate, CreatedBy)
VALUES
	(NEWID(), 'Dr. Thabo Mthembu', '', NULL, 'GP', 'ZA-MP-0012345', 'N/A', 'GENERAL_PRACTITIONER', NULL, NULL, NULL, 1, @ProvidersDefaultDate, 'SYSTEM'),
	(NEWID(), 'Dr. Naledi Johnson', '', NULL, 'CARDIOLOGY', 'ZA-MP-0054321', 'N/A', 'CARDIOLOGIST', NULL, NULL, NULL, 1, @ProvidersDefaultDate, 'SYSTEM'),
	(NEWID(), 'Dr. Amira Hassan', '', NULL, 'NEUROLOGY', 'ZA-MP-0098765', 'N/A', 'NEUROLOGIST', NULL, NULL, NULL, 1, @ProvidersDefaultDate, 'SYSTEM'),
	(NEWID(), 'Dr. Kevin Smith', '', NULL, 'ORTHOPEDICS', 'ZA-MP-0011111', 'N/A', 'ORTHOPEDIC_SURGEON', NULL, NULL, NULL, 1, @ProvidersDefaultDate, 'SYSTEM'),
	(NEWID(), 'Dr. Patricia Ndlovu', '', NULL, 'PEDIATRICS', 'ZA-MP-0022222', 'N/A', 'PEDIATRICIAN', NULL, NULL, NULL, 1, @ProvidersDefaultDate, 'SYSTEM'),
	(NEWID(), 'Dr. Michael Chen', '', NULL, 'PSYCHIATRY', 'ZA-MP-0033333', 'N/A', 'PSYCHIATRIST', NULL, NULL, NULL, 1, @ProvidersDefaultDate, 'SYSTEM'),
	(NEWID(), 'Dr. Sarah Botha', '', NULL, 'ENDOCRINOLOGY', 'ZA-MP-0044444', 'N/A', 'ENDOCRINOLOGIST', NULL, NULL, NULL, 1, @ProvidersDefaultDate, 'SYSTEM'),
	(NEWID(), 'Dr. James Okafor', '', NULL, 'PULMONOLOGY', 'ZA-MP-0055555', 'N/A', 'PULMONOLOGIST', NULL, NULL, NULL, 1, @ProvidersDefaultDate, 'SYSTEM'),
	(NEWID(), 'Dr. Kavya Patel', '', NULL, 'GASTROENTEROLOGY', 'ZA-MP-0066666', 'N/A', 'GASTROENTEROLOGIST', NULL, NULL, NULL, 1, @ProvidersDefaultDate, 'SYSTEM'),
	(NEWID(), 'Dr. Robert Mendes', '', NULL, 'UROLOGY', 'ZA-MP-0077777', 'N/A', 'UROLOGIST', NULL, NULL, NULL, 1, @ProvidersDefaultDate, 'SYSTEM')

PRINT 'Healthcare providers inserted successfully'
GO

-- Insurance providers (map to Profile.InsuranceProviders)
DECLARE @InsuranceDefaultDate DATETIME = GETDATE()

INSERT INTO Profile.InsuranceProviders (InsuranceProviderId, ProviderName, RegistrationNumber, ContactPerson, AddressIdFK, PhoneNumber, Email, WebsiteUrl, BillingCode, IsActive, Notes, CreatedDate, CreatedBy)
VALUES
	(NEWID(), 'Discovery Health', 'REG001', NULL, NULL, '+27 11 799 8000', 'inquiry@discovery.co.za', NULL, NULL, 1, NULL, @InsuranceDefaultDate, 'SYSTEM'),
	(NEWID(), 'Momentum Health Solutions', 'REG002', NULL, NULL, '+27 11 408 6600', 'support@momentum.co.za', NULL, NULL, 1, NULL, @InsuranceDefaultDate, 'SYSTEM'),
	(NEWID(), 'Medshelf Medical Scheme', 'REG003', NULL, NULL, '+27 10 020 2020', 'membercare@medshelf.co.za', NULL, NULL, 1, NULL, @InsuranceDefaultDate, 'SYSTEM'),
	(NEWID(), 'Bonitas', 'REG004', NULL, NULL, '+27 11 407 5000', 'support@bonitas.co.za', NULL, NULL, 1, NULL, @InsuranceDefaultDate, 'SYSTEM'),
	(NEWID(), 'Polmed', 'REG005', NULL, NULL, '+27 11 386 4800', 'info@polmed.co.za', NULL, NULL, 1, NULL, @InsuranceDefaultDate, 'SYSTEM'),
	(NEWID(), 'GEMS (Government Employees Medical Scheme)', 'REG006', NULL, NULL, '+27 12 307 9000', 'support@gems.gov.za', NULL, NULL, 1, NULL, @InsuranceDefaultDate, 'SYSTEM'),
	(NEWID(), 'Sizwe Medical Scheme', 'REG007', NULL, NULL, '+27 11 287 8000', 'member@sizwehealth.co.za', NULL, NULL, 1, NULL, @InsuranceDefaultDate, 'SYSTEM'),
	(NEWID(), 'Umkhulu Medical Scheme', 'REG008', NULL, NULL, '+27 31 328 6000', 'support@umkhulu.co.za', NULL, NULL, 1, NULL, @InsuranceDefaultDate, 'SYSTEM')

PRINT 'Insurance providers inserted successfully'
GO

-- Lookup schema: reference allergy & medication lists (keeps reference data separate from patient records)
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Lookup')
	EXEC('CREATE SCHEMA Lookup')
GO

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
GO

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
GO

-- Insert common allergies (from original seed)
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

GO
DECLARE @AllMedDefaultDate DATETIME = GETDATE()
-- Insert common reference medications
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
PRINT '   Password: HealthcareAdmin@2026! (CHANGE IMMEDIATELY ON FIRST LOGIN)'
PRINT '3. Create application users and assign appropriate roles'
PRINT '4. Test appointment scheduling and patient form submission workflows'
PRINT '5. Configure backup and maintenance schedules'
PRINT ''

GO
