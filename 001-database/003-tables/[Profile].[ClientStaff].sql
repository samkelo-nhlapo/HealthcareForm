USE HealthcareForm
GO

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
        [StaffDesignationIdFK] [uniqueidentifier] NULL,
        [PrimaryDepartmentIdFK] [uniqueidentifier] NULL,
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

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE parent_object_id = OBJECT_ID(N'[Profile].[ClientStaff]')
      AND name = N'FK_ClientStaff_Client'
)
BEGIN
    ALTER TABLE [Profile].[ClientStaff] WITH CHECK
    ADD CONSTRAINT FK_ClientStaff_Client FOREIGN KEY([ClientIdFK]) REFERENCES [Profile].[Clients]([ClientId]);
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE parent_object_id = OBJECT_ID(N'[Profile].[ClientStaff]')
      AND name = N'FK_ClientStaff_Role'
)
BEGIN
    ALTER TABLE [Profile].[ClientStaff] WITH CHECK
    ADD CONSTRAINT FK_ClientStaff_Role FOREIGN KEY([RoleIdFK]) REFERENCES [Auth].[Roles]([RoleId]);
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE parent_object_id = OBJECT_ID(N'[Profile].[ClientStaff]')
      AND name = N'FK_ClientStaff_User'
)
BEGIN
    ALTER TABLE [Profile].[ClientStaff] WITH CHECK
    ADD CONSTRAINT FK_ClientStaff_User FOREIGN KEY([UserIdFK]) REFERENCES [Auth].[Users]([UserId]);
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE parent_object_id = OBJECT_ID(N'[Profile].[ClientStaff]')
      AND name = N'FK_ClientStaff_Provider'
)
BEGIN
    ALTER TABLE [Profile].[ClientStaff] WITH CHECK
    ADD CONSTRAINT FK_ClientStaff_Provider FOREIGN KEY([ProviderIdFK]) REFERENCES [Profile].[HealthcareProviders]([ProviderId]);
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE parent_object_id = OBJECT_ID(N'[Profile].[ClientStaff]')
      AND name = N'FK_ClientStaff_StaffDesignation'
)
BEGIN
    ALTER TABLE [Profile].[ClientStaff] WITH CHECK
    ADD CONSTRAINT FK_ClientStaff_StaffDesignation FOREIGN KEY([StaffDesignationIdFK]) REFERENCES [Profile].[StaffDesignations]([StaffDesignationId]);
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE parent_object_id = OBJECT_ID(N'[Profile].[ClientStaff]')
      AND name = N'FK_ClientStaff_PrimaryDepartment'
)
BEGIN
    ALTER TABLE [Profile].[ClientStaff] WITH CHECK
    ADD CONSTRAINT FK_ClientStaff_PrimaryDepartment FOREIGN KEY([PrimaryDepartmentIdFK]) REFERENCES [Profile].[ClientDepartments]([ClientDepartmentId]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientStaff]') AND name = N'UX_ClientStaff_Client_Email')
BEGIN
    CREATE UNIQUE INDEX UX_ClientStaff_Client_Email
    ON [Profile].[ClientStaff]([ClientIdFK], [Email])
    WHERE [Email] IS NOT NULL AND [IsDeleted] = 0;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientStaff]') AND name = N'IX_ClientStaff_ClientIdFK')
BEGIN
    CREATE INDEX IX_ClientStaff_ClientIdFK ON [Profile].[ClientStaff]([ClientIdFK]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientStaff]') AND name = N'IX_ClientStaff_RoleIdFK')
BEGIN
    CREATE INDEX IX_ClientStaff_RoleIdFK ON [Profile].[ClientStaff]([RoleIdFK]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientStaff]') AND name = N'IX_ClientStaff_StaffDesignationIdFK')
BEGIN
    CREATE INDEX IX_ClientStaff_StaffDesignationIdFK ON [Profile].[ClientStaff]([StaffDesignationIdFK]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientStaff]') AND name = N'IX_ClientStaff_PrimaryDepartmentIdFK')
BEGIN
    CREATE INDEX IX_ClientStaff_PrimaryDepartmentIdFK ON [Profile].[ClientStaff]([PrimaryDepartmentIdFK]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientStaff]') AND name = N'IX_ClientStaff_IsActive')
BEGIN
    CREATE INDEX IX_ClientStaff_IsActive ON [Profile].[ClientStaff]([IsActive]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientStaff]') AND name = N'IX_ClientStaff_IsDeleted')
BEGIN
    CREATE INDEX IX_ClientStaff_IsDeleted ON [Profile].[ClientStaff]([IsDeleted]);
END
GO
