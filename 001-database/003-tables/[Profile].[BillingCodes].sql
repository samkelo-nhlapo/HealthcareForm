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

IF OBJECT_ID(N'[Profile].[BillingCodes]', N'U') IS NULL
BEGIN
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
END
GO

IF OBJECT_ID(N'[Profile].[BillingCodes]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[BillingCodes]')
      AND c.name = N'BillingCodeId'
)
BEGIN
ALTER TABLE [Profile].[BillingCodes] ADD DEFAULT (newid()) FOR [BillingCodeId]
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[BillingCodes]') AND name = 'IX_BillingCodes_Code')
BEGIN
CREATE INDEX IX_BillingCodes_Code ON [Profile].[BillingCodes]([Code])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[BillingCodes]') AND name = 'IX_BillingCodes_CodeType')
BEGIN
CREATE INDEX IX_BillingCodes_CodeType ON [Profile].[BillingCodes]([CodeType])
END
GO
