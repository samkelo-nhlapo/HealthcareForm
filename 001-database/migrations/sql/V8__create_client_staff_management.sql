-- V8__create_client_staff_management.sql
-- Adds client-linked staff management table for clinic operations.

USE HealthcareForm;
GO

IF OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NULL
BEGIN
    CREATE TABLE [Profile].[ClientStaff]
    (
        [ClientStaffId] [uniqueidentifier] NOT NULL,
        [ClientIdFK] [uniqueidentifier] NOT NULL,
        [RoleIdFK] [uniqueidentifier] NULL,
        [UserIdFK] [uniqueidentifier] NULL,
        [ProviderIdFK] [uniqueidentifier] NULL,
        [StaffCode] [varchar](50) NOT NULL,
        [FirstName] [varchar](250) NOT NULL,
        [LastName] [varchar](250) NOT NULL,
        [Email] [varchar](250) NULL,
        [PhoneNumber] [varchar](25) NULL,
        [JobTitle] [varchar](150) NULL,
        [Department] [varchar](100) NULL,
        [StaffType] [varchar](50) NOT NULL CONSTRAINT DF_ClientStaff_StaffType DEFAULT 'Administrative',
        [EmploymentType] [varchar](50) NOT NULL CONSTRAINT DF_ClientStaff_EmploymentType DEFAULT 'Full-Time',
        [HireDate] [datetime] NULL,
        [TerminationDate] [datetime] NULL,
        [IsPrimaryContact] [bit] NOT NULL CONSTRAINT DF_ClientStaff_IsPrimaryContact DEFAULT 0,
        [IsActive] [bit] NOT NULL CONSTRAINT DF_ClientStaff_IsActive DEFAULT 1,
        [IsDeleted] [bit] NOT NULL CONSTRAINT DF_ClientStaff_IsDeleted DEFAULT 0,
        [CreatedDate] [datetime] NOT NULL CONSTRAINT DF_ClientStaff_CreatedDate DEFAULT GETDATE(),
        [CreatedBy] [varchar](250) NULL,
        [UpdatedDate] [datetime] NOT NULL CONSTRAINT DF_ClientStaff_UpdatedDate DEFAULT GETDATE(),
        [UpdatedBy] [varchar](250) NULL,
        CONSTRAINT PK_ClientStaff PRIMARY KEY CLUSTERED ([ClientStaffId] ASC),
        CONSTRAINT UQ_ClientStaff_StaffCode UNIQUE ([StaffCode])
    );

    ALTER TABLE [Profile].[ClientStaff]
        ADD CONSTRAINT DF_ClientStaff_ClientStaffId DEFAULT (NEWID()) FOR [ClientStaffId];
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ClientStaff_StaffType')
BEGIN
    ALTER TABLE [Profile].[ClientStaff]
    ADD CONSTRAINT CK_ClientStaff_StaffType
    CHECK ([StaffType] IN ('Clinical', 'Administrative', 'Support', 'Management'));
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ClientStaff_EmploymentType')
BEGIN
    ALTER TABLE [Profile].[ClientStaff]
    ADD CONSTRAINT CK_ClientStaff_EmploymentType
    CHECK ([EmploymentType] IN ('Full-Time', 'Part-Time', 'Contract', 'Locum'));
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ClientStaff_TerminationDate')
BEGIN
    ALTER TABLE [Profile].[ClientStaff]
    ADD CONSTRAINT CK_ClientStaff_TerminationDate
    CHECK ([TerminationDate] IS NULL OR [HireDate] IS NULL OR [TerminationDate] >= [HireDate]);
END
GO

IF OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
AND OBJECT_ID(N'FK_ClientStaff_Client', N'F') IS NULL
BEGIN
    ALTER TABLE [Profile].[ClientStaff] WITH CHECK
    ADD CONSTRAINT FK_ClientStaff_Client FOREIGN KEY([ClientIdFK]) REFERENCES [Profile].[Clients]([ClientId]);
END
GO

IF OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
AND OBJECT_ID(N'FK_ClientStaff_Role', N'F') IS NULL
BEGIN
    ALTER TABLE [Profile].[ClientStaff] WITH CHECK
    ADD CONSTRAINT FK_ClientStaff_Role FOREIGN KEY([RoleIdFK]) REFERENCES [Auth].[Roles]([RoleId]);
END
GO

IF OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
AND OBJECT_ID(N'FK_ClientStaff_User', N'F') IS NULL
BEGIN
    ALTER TABLE [Profile].[ClientStaff] WITH CHECK
    ADD CONSTRAINT FK_ClientStaff_User FOREIGN KEY([UserIdFK]) REFERENCES [Auth].[Users]([UserId]);
END
GO

IF OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
AND OBJECT_ID(N'FK_ClientStaff_Provider', N'F') IS NULL
BEGIN
    ALTER TABLE [Profile].[ClientStaff] WITH CHECK
    ADD CONSTRAINT FK_ClientStaff_Provider FOREIGN KEY([ProviderIdFK]) REFERENCES [Profile].[HealthcareProviders]([ProviderId]);
END
GO

IF OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientStaff]') AND name = N'UX_ClientStaff_Client_Email')
BEGIN
    CREATE UNIQUE INDEX UX_ClientStaff_Client_Email
    ON [Profile].[ClientStaff]([ClientIdFK], [Email])
    WHERE [Email] IS NOT NULL AND [IsDeleted] = 0;
END
GO

IF OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientStaff]') AND name = N'IX_ClientStaff_ClientIdFK')
BEGIN
    CREATE INDEX IX_ClientStaff_ClientIdFK ON [Profile].[ClientStaff]([ClientIdFK]);
END
GO

IF OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientStaff]') AND name = N'IX_ClientStaff_RoleIdFK')
BEGIN
    CREATE INDEX IX_ClientStaff_RoleIdFK ON [Profile].[ClientStaff]([RoleIdFK]);
END
GO

IF OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientStaff]') AND name = N'IX_ClientStaff_IsActive')
BEGIN
    CREATE INDEX IX_ClientStaff_IsActive ON [Profile].[ClientStaff]([IsActive]);
END
GO

IF OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientStaff]') AND name = N'IX_ClientStaff_IsDeleted')
BEGIN
    CREATE INDEX IX_ClientStaff_IsDeleted ON [Profile].[ClientStaff]([IsDeleted]);
END
GO
