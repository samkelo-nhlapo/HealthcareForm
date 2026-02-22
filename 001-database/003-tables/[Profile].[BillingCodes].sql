USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Billing codes for medical procedures and services (ICD-10, CPT codes)
--	TFS Task:		Healthcare form - billing codes
--================================================================================================

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Profile].[BillingCodes](
	[BillingCodeId] [uniqueidentifier] NOT NULL,
	[CodeType] [varchar](50) NOT NULL, -- ICD-10 (diagnosis), CPT (procedure), HCPCS (service)
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

CREATE INDEX IX_BillingCodes_Code ON [Profile].[BillingCodes]([Code])
GO

CREATE INDEX IX_BillingCodes_CodeType ON [Profile].[BillingCodes]([CodeType])
GO
