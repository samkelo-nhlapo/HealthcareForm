-- V25__client_provider_affiliations_foundation.sql
-- Phase 1 foundation for separating client employment from provider-client operating relationships.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'[Profile].[ClientProviderAffiliations]', N'U') IS NULL
BEGIN
    CREATE TABLE [Profile].[ClientProviderAffiliations](
        [ClientProviderAffiliationId] [uniqueidentifier] NOT NULL,
        [ClientIdFK] [uniqueidentifier] NOT NULL,
        [ProviderIdFK] [uniqueidentifier] NOT NULL,
        [ClientStaffIdFK] [uniqueidentifier] NULL,
        [PrimaryDepartmentIdFK] [uniqueidentifier] NULL,
        [RelationshipType] [varchar](50) NOT NULL CONSTRAINT [DF_ClientProviderAffiliations_RelationshipType] DEFAULT 'Employee',
        [CanBookAppointments] [bit] NOT NULL CONSTRAINT [DF_ClientProviderAffiliations_CanBookAppointments] DEFAULT 1,
        [CanReceiveReferrals] [bit] NOT NULL CONSTRAINT [DF_ClientProviderAffiliations_CanReceiveReferrals] DEFAULT 1,
        [StartDate] [datetime] NOT NULL CONSTRAINT [DF_ClientProviderAffiliations_StartDate] DEFAULT GETDATE(),
        [EndDate] [datetime] NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_ClientProviderAffiliations_IsActive] DEFAULT 1,
        [Notes] [varchar](500) NULL,
        [CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_ClientProviderAffiliations_CreatedDate] DEFAULT GETDATE(),
        [CreatedBy] [varchar](250) NULL,
        [UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_ClientProviderAffiliations_UpdatedDate] DEFAULT GETDATE(),
        [UpdatedBy] [varchar](250) NULL,
        CONSTRAINT [PK_ClientProviderAffiliations] PRIMARY KEY CLUSTERED ([ClientProviderAffiliationId] ASC)
    );
END
GO

IF OBJECT_ID(N'[Profile].[ClientProviderAffiliations]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[ClientProviderAffiliations]')
      AND c.name = N'ClientProviderAffiliationId'
)
BEGIN
    ALTER TABLE [Profile].[ClientProviderAffiliations] ADD DEFAULT (NEWID()) FOR [ClientProviderAffiliationId];
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ClientProviderAffiliations_RelationshipType')
BEGIN
    ALTER TABLE [Profile].[ClientProviderAffiliations] WITH CHECK
    ADD CONSTRAINT [CK_ClientProviderAffiliations_RelationshipType]
    CHECK ([RelationshipType] IN ('Employee', 'Visiting', 'Locum', 'Contracted', 'ReferralNetwork'));
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ClientProviderAffiliations_DateRange')
BEGIN
    ALTER TABLE [Profile].[ClientProviderAffiliations] WITH CHECK
    ADD CONSTRAINT [CK_ClientProviderAffiliations_DateRange]
    CHECK ([EndDate] IS NULL OR [EndDate] >= [StartDate]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ClientProviderAffiliations_EmployeeRequiresStaff')
BEGIN
    ALTER TABLE [Profile].[ClientProviderAffiliations] WITH CHECK
    ADD CONSTRAINT [CK_ClientProviderAffiliations_EmployeeRequiresStaff]
    CHECK (([RelationshipType] <> 'Employee') OR ([ClientStaffIdFK] IS NOT NULL));
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ClientProviderAffiliations_StaffImpliesEmployee')
BEGIN
    ALTER TABLE [Profile].[ClientProviderAffiliations] WITH CHECK
    ADD CONSTRAINT [CK_ClientProviderAffiliations_StaffImpliesEmployee]
    CHECK ([ClientStaffIdFK] IS NULL OR [RelationshipType] = 'Employee');
END
GO

IF OBJECT_ID(N'[Profile].[Clients]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ClientProviderAffiliations_Client')
BEGIN
    ALTER TABLE [Profile].[ClientProviderAffiliations] WITH CHECK
    ADD CONSTRAINT [FK_ClientProviderAffiliations_Client]
    FOREIGN KEY([ClientIdFK]) REFERENCES [Profile].[Clients]([ClientId]);
END
GO

IF OBJECT_ID(N'[Profile].[HealthcareProviders]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ClientProviderAffiliations_Provider')
BEGIN
    ALTER TABLE [Profile].[ClientProviderAffiliations] WITH CHECK
    ADD CONSTRAINT [FK_ClientProviderAffiliations_Provider]
    FOREIGN KEY([ProviderIdFK]) REFERENCES [Profile].[HealthcareProviders]([ProviderId]);
END
GO

IF OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ClientProviderAffiliations_ClientStaff')
BEGIN
    ALTER TABLE [Profile].[ClientProviderAffiliations] WITH CHECK
    ADD CONSTRAINT [FK_ClientProviderAffiliations_ClientStaff]
    FOREIGN KEY([ClientStaffIdFK]) REFERENCES [Profile].[ClientStaff]([ClientStaffId]);
END
GO

IF OBJECT_ID(N'[Profile].[ClientDepartments]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ClientProviderAffiliations_PrimaryDepartment')
BEGIN
    ALTER TABLE [Profile].[ClientProviderAffiliations] WITH CHECK
    ADD CONSTRAINT [FK_ClientProviderAffiliations_PrimaryDepartment]
    FOREIGN KEY([PrimaryDepartmentIdFK]) REFERENCES [Profile].[ClientDepartments]([ClientDepartmentId]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientProviderAffiliations]') AND name = 'UX_ClientProviderAffiliations_Client_Provider_ActiveOpen')
BEGIN
    CREATE UNIQUE INDEX UX_ClientProviderAffiliations_Client_Provider_ActiveOpen
    ON [Profile].[ClientProviderAffiliations]([ClientIdFK], [ProviderIdFK])
    WHERE [IsActive] = 1 AND [EndDate] IS NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientProviderAffiliations]') AND name = 'UX_ClientProviderAffiliations_ClientStaff_ActiveOpen')
BEGIN
    CREATE UNIQUE INDEX UX_ClientProviderAffiliations_ClientStaff_ActiveOpen
    ON [Profile].[ClientProviderAffiliations]([ClientStaffIdFK])
    WHERE [ClientStaffIdFK] IS NOT NULL AND [IsActive] = 1 AND [EndDate] IS NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientProviderAffiliations]') AND name = 'IX_ClientProviderAffiliations_ClientIdFK_IsActive_CanBookAppointments')
BEGIN
    CREATE INDEX IX_ClientProviderAffiliations_ClientIdFK_IsActive_CanBookAppointments
    ON [Profile].[ClientProviderAffiliations]([ClientIdFK], [IsActive], [CanBookAppointments]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientProviderAffiliations]') AND name = 'IX_ClientProviderAffiliations_ProviderIdFK_IsActive')
BEGIN
    CREATE INDEX IX_ClientProviderAffiliations_ProviderIdFK_IsActive
    ON [Profile].[ClientProviderAffiliations]([ProviderIdFK], [IsActive]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientProviderAffiliations]') AND name = 'IX_ClientProviderAffiliations_PrimaryDepartmentIdFK')
BEGIN
    CREATE INDEX IX_ClientProviderAffiliations_PrimaryDepartmentIdFK
    ON [Profile].[ClientProviderAffiliations]([PrimaryDepartmentIdFK]);
END
GO
