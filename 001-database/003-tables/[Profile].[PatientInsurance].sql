USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Patient insurance policy information and coverage details
--	TFS Task:		Healthcare form - patient insurance
--================================================================================================

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
	[CoveragePlan] [varchar](250) NOT NULL, -- e.g., "Bronze", "Silver", "Gold"
	[StartDate] [datetime] NOT NULL,
	[ExpiryDate] [datetime] NOT NULL,
	[CoverageType] [varchar](50) NOT NULL, -- Individual, Family, Group, Government
	[Deductible] [decimal](10,2) NULL,
	[CopayAmount] [decimal](10,2) NULL,
	[OutOfPocketMax] [decimal](10,2) NULL,
	[IsPrimary] [bit] NOT NULL DEFAULT 1, -- In case of multiple insurances
	[Status] [varchar](50) NOT NULL DEFAULT 'Active', -- Active, Inactive, Expired, Cancelled
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

ALTER TABLE [Profile].[PatientInsurance] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
REFERENCES [Profile].[Patient] ([PatientId])
GO

ALTER TABLE [Profile].[PatientInsurance] WITH CHECK ADD FOREIGN KEY([InsuranceProviderIdFK])
REFERENCES [Profile].[InsuranceProviders] ([InsuranceProviderId])
GO

CREATE INDEX IX_PatientInsurance_PatientIdFK ON [Profile].[PatientInsurance]([PatientIdFK])
GO

CREATE INDEX IX_PatientInsurance_InsuranceProviderIdFK ON [Profile].[PatientInsurance]([InsuranceProviderIdFK])
GO

CREATE INDEX IX_PatientInsurance_ExpiryDate ON [Profile].[PatientInsurance]([ExpiryDate])
GO
