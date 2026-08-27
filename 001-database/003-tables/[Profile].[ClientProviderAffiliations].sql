USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	30/04/2026
--	Description:	Client-scoped provider affiliations for employed and flexible clinicians
--	TFS Task:		Healthcare form - client provider affiliation model
--================================================================================================

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[Profile].[ClientProviderAffiliations]', N'U') IS NULL
BEGIN
CREATE TABLE [Profile].[ClientProviderAffiliations](
	[ClientProviderAffiliationId] [uniqueidentifier] NOT NULL,
	[ClientIdFK] [uniqueidentifier] NOT NULL,
	[ProviderIdFK] [uniqueidentifier] NOT NULL,
	[ClientStaffIdFK] [uniqueidentifier] NULL, -- Only set when the provider is also a client employee
	[PrimaryDepartmentIdFK] [uniqueidentifier] NULL, -- Client-local operating department/clinic
	[RelationshipType] [varchar](50) NOT NULL CONSTRAINT [DF_ClientProviderAffiliations_RelationshipType] DEFAULT 'Employee', -- Employee, Visiting, Locum, Contracted, ReferralNetwork
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
PRIMARY KEY CLUSTERED
(
	[ClientProviderAffiliationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
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
ALTER TABLE [Profile].[ClientProviderAffiliations] ADD DEFAULT (newid()) FOR [ClientProviderAffiliationId]
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ClientProviderAffiliations_RelationshipType')
BEGIN
ALTER TABLE [Profile].[ClientProviderAffiliations] WITH CHECK
ADD CONSTRAINT [CK_ClientProviderAffiliations_RelationshipType]
CHECK ([RelationshipType] IN ('Employee', 'Visiting', 'Locum', 'Contracted', 'ReferralNetwork'))
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ClientProviderAffiliations_DateRange')
BEGIN
ALTER TABLE [Profile].[ClientProviderAffiliations] WITH CHECK
ADD CONSTRAINT [CK_ClientProviderAffiliations_DateRange]
CHECK ([EndDate] IS NULL OR [EndDate] >= [StartDate])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ClientProviderAffiliations_EmployeeRequiresStaff')
BEGIN
ALTER TABLE [Profile].[ClientProviderAffiliations] WITH CHECK
ADD CONSTRAINT [CK_ClientProviderAffiliations_EmployeeRequiresStaff]
CHECK (
    ([RelationshipType] <> 'Employee')
    OR
    ([ClientStaffIdFK] IS NOT NULL)
)
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ClientProviderAffiliations_StaffImpliesEmployee')
BEGIN
ALTER TABLE [Profile].[ClientProviderAffiliations] WITH CHECK
ADD CONSTRAINT [CK_ClientProviderAffiliations_StaffImpliesEmployee]
CHECK (
    [ClientStaffIdFK] IS NULL
    OR
    [RelationshipType] = 'Employee'
)
END
GO

IF OBJECT_ID(N'[Profile].[ClientProviderAffiliations]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[Clients]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[ClientProviderAffiliations]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[ClientProviderAffiliations]'), N'ClientIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[Clients]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Clients]'), N'ClientId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[ClientProviderAffiliations] WITH CHECK ADD FOREIGN KEY([ClientIdFK])
REFERENCES [Profile].[Clients] ([ClientId])
END
GO

IF OBJECT_ID(N'[Profile].[ClientProviderAffiliations]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[HealthcareProviders]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[ClientProviderAffiliations]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[ClientProviderAffiliations]'), N'ProviderIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[HealthcareProviders]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[HealthcareProviders]'), N'ProviderId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[ClientProviderAffiliations] WITH CHECK ADD FOREIGN KEY([ProviderIdFK])
REFERENCES [Profile].[HealthcareProviders] ([ProviderId])
END
GO

IF OBJECT_ID(N'[Profile].[ClientProviderAffiliations]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[ClientProviderAffiliations]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[ClientProviderAffiliations]'), N'ClientStaffIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[ClientStaff]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[ClientStaff]'), N'ClientStaffId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[ClientProviderAffiliations] WITH CHECK ADD FOREIGN KEY([ClientStaffIdFK])
REFERENCES [Profile].[ClientStaff] ([ClientStaffId])
END
GO

IF OBJECT_ID(N'[Profile].[ClientProviderAffiliations]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[ClientDepartments]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[ClientProviderAffiliations]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[ClientProviderAffiliations]'), N'PrimaryDepartmentIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[ClientDepartments]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[ClientDepartments]'), N'ClientDepartmentId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[ClientProviderAffiliations] WITH CHECK ADD FOREIGN KEY([PrimaryDepartmentIdFK])
REFERENCES [Profile].[ClientDepartments] ([ClientDepartmentId])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientProviderAffiliations]') AND name = 'UX_ClientProviderAffiliations_Client_Provider_ActiveOpen')
BEGIN
CREATE UNIQUE INDEX UX_ClientProviderAffiliations_Client_Provider_ActiveOpen
ON [Profile].[ClientProviderAffiliations]([ClientIdFK], [ProviderIdFK])
WHERE [IsActive] = 1 AND [EndDate] IS NULL
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientProviderAffiliations]') AND name = 'UX_ClientProviderAffiliations_ClientStaff_ActiveOpen')
BEGIN
CREATE UNIQUE INDEX UX_ClientProviderAffiliations_ClientStaff_ActiveOpen
ON [Profile].[ClientProviderAffiliations]([ClientStaffIdFK])
WHERE [ClientStaffIdFK] IS NOT NULL AND [IsActive] = 1 AND [EndDate] IS NULL
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientProviderAffiliations]') AND name = 'IX_ClientProviderAffiliations_ClientIdFK_IsActive_CanBookAppointments')
BEGIN
CREATE INDEX IX_ClientProviderAffiliations_ClientIdFK_IsActive_CanBookAppointments
ON [Profile].[ClientProviderAffiliations]([ClientIdFK], [IsActive], [CanBookAppointments])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientProviderAffiliations]') AND name = 'IX_ClientProviderAffiliations_ProviderIdFK_IsActive')
BEGIN
CREATE INDEX IX_ClientProviderAffiliations_ProviderIdFK_IsActive
ON [Profile].[ClientProviderAffiliations]([ProviderIdFK], [IsActive])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientProviderAffiliations]') AND name = 'IX_ClientProviderAffiliations_PrimaryDepartmentIdFK')
BEGIN
CREATE INDEX IX_ClientProviderAffiliations_PrimaryDepartmentIdFK
ON [Profile].[ClientProviderAffiliations]([PrimaryDepartmentIdFK])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientProviderAffiliations]') AND name = 'UX_ClientProviderAffiliations_Id_Client_Provider')
BEGIN
CREATE UNIQUE INDEX UX_ClientProviderAffiliations_Id_Client_Provider
ON [Profile].[ClientProviderAffiliations]([ClientProviderAffiliationId], [ClientIdFK], [ProviderIdFK])
END
GO
