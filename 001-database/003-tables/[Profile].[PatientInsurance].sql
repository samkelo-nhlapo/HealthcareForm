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

IF OBJECT_ID(N'[Profile].[PatientInsurance]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[PatientInsurance]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[PatientInsurance]'), N'PatientIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[Patient]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Patient]'), N'PatientId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[PatientInsurance] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
REFERENCES [Profile].[Patient] ([PatientId])
END
GO

IF OBJECT_ID(N'[Profile].[PatientInsurance]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[InsuranceProviders]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[PatientInsurance]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[PatientInsurance]'), N'InsuranceProviderIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[InsuranceProviders]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[InsuranceProviders]'), N'InsuranceProviderId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[PatientInsurance] WITH CHECK ADD FOREIGN KEY([InsuranceProviderIdFK])
REFERENCES [Profile].[InsuranceProviders] ([InsuranceProviderId])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[PatientInsurance]') AND name = 'IX_PatientInsurance_PatientIdFK')
BEGIN
CREATE INDEX IX_PatientInsurance_PatientIdFK ON [Profile].[PatientInsurance]([PatientIdFK])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[PatientInsurance]') AND name = 'IX_PatientInsurance_InsuranceProviderIdFK')
BEGIN
CREATE INDEX IX_PatientInsurance_InsuranceProviderIdFK ON [Profile].[PatientInsurance]([InsuranceProviderIdFK])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[PatientInsurance]') AND name = 'IX_PatientInsurance_ExpiryDate')
BEGIN
CREATE INDEX IX_PatientInsurance_ExpiryDate ON [Profile].[PatientInsurance]([ExpiryDate])
END
GO
