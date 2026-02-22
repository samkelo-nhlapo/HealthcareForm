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
GO

ALTER TABLE [Profile].[Referrals] ADD DEFAULT (newid()) FOR [ReferralId]
GO

ALTER TABLE [Profile].[Referrals] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
REFERENCES [Profile].[Patient] ([PatientId])
GO

ALTER TABLE [Profile].[Referrals] WITH CHECK ADD FOREIGN KEY([ReferringProviderIdFK])
REFERENCES [Profile].[HealthcareProviders] ([ProviderId])
GO

ALTER TABLE [Profile].[Referrals] WITH CHECK ADD FOREIGN KEY([ReferredProviderIdFK])
REFERENCES [Profile].[HealthcareProviders] ([ProviderId])
GO

CREATE INDEX IX_Referrals_PatientIdFK ON [Profile].[Referrals]([PatientIdFK])
GO

CREATE INDEX IX_Referrals_ReferringProviderIdFK ON [Profile].[Referrals]([ReferringProviderIdFK])
GO

CREATE INDEX IX_Referrals_ReferredProviderIdFK ON [Profile].[Referrals]([ReferredProviderIdFK])
GO

CREATE INDEX IX_Referrals_Status ON [Profile].[Referrals]([Status])
GO
