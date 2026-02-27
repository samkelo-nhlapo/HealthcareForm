USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Patient referrals to specialists or other healthcare providers
--	TFS Task:		Healthcare form - referral management
--================================================================================================

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
	[ReferredProviderIdFK] [uniqueidentifier] NULL, -- Can be NULL if specialist not yet assigned
	[ReferralDate] [datetime] NOT NULL,
	[Reason] [varchar](MAX) NOT NULL,
	[Priority] [varchar](50) NOT NULL DEFAULT 'Normal', -- Urgent, Normal, Routine
	[ReferralType] [varchar](100) NOT NULL, -- Specialist consultation, Second opinion, Procedure, etc.
	[SpecializationNeeded] [varchar](250) NOT NULL,
	[ReferralCode] [varchar](50) NULL, -- Authorization code from insurance
	[Status] [varchar](50) NOT NULL DEFAULT 'Pending', -- Pending, Accepted, In Progress, Completed, Rejected
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

IF OBJECT_ID(N'[Profile].[Referrals]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[Referrals]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Referrals]'), N'PatientIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[Patient]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Patient]'), N'PatientId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[Referrals] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
REFERENCES [Profile].[Patient] ([PatientId])
END
GO

IF OBJECT_ID(N'[Profile].[Referrals]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[HealthcareProviders]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[Referrals]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Referrals]'), N'ReferringProviderIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[HealthcareProviders]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[HealthcareProviders]'), N'ProviderId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[Referrals] WITH CHECK ADD FOREIGN KEY([ReferringProviderIdFK])
REFERENCES [Profile].[HealthcareProviders] ([ProviderId])
END
GO

IF OBJECT_ID(N'[Profile].[Referrals]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[HealthcareProviders]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[Referrals]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Referrals]'), N'ReferredProviderIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[HealthcareProviders]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[HealthcareProviders]'), N'ProviderId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[Referrals] WITH CHECK ADD FOREIGN KEY([ReferredProviderIdFK])
REFERENCES [Profile].[HealthcareProviders] ([ProviderId])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Referrals]') AND name = 'IX_Referrals_PatientIdFK')
BEGIN
CREATE INDEX IX_Referrals_PatientIdFK ON [Profile].[Referrals]([PatientIdFK])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Referrals]') AND name = 'IX_Referrals_ReferringProviderIdFK')
BEGIN
CREATE INDEX IX_Referrals_ReferringProviderIdFK ON [Profile].[Referrals]([ReferringProviderIdFK])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Referrals]') AND name = 'IX_Referrals_ReferredProviderIdFK')
BEGIN
CREATE INDEX IX_Referrals_ReferredProviderIdFK ON [Profile].[Referrals]([ReferredProviderIdFK])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Referrals]') AND name = 'IX_Referrals_Status')
BEGIN
CREATE INDEX IX_Referrals_Status ON [Profile].[Referrals]([Status])
END
GO
