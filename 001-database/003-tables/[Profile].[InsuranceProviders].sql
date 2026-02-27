USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Insurance provider information and settings
--	TFS Task:		Healthcare form - insurance management
--================================================================================================

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[Profile].[InsuranceProviders]', N'U') IS NULL
BEGIN
CREATE TABLE [Profile].[InsuranceProviders](
	[InsuranceProviderId] [uniqueidentifier] NOT NULL,
	[ProviderName] [varchar](250) NOT NULL UNIQUE,
	[RegistrationNumber] [varchar](100) NOT NULL UNIQUE,
	[ContactPerson] [varchar](250) NULL,
	[AddressIdFK] [uniqueidentifier] NULL,
	[PhoneNumber] [varchar](15) NOT NULL,
	[Email] [varchar](250) NULL,
	[WebsiteUrl] [varchar](500) NULL,
	[BillingCode] [varchar](50) NULL, -- Code for billing purposes
	[IsActive] [bit] NOT NULL DEFAULT 1,
	[Notes] [varchar](MAX) NULL,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[InsuranceProviderId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

IF OBJECT_ID(N'[Profile].[InsuranceProviders]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[InsuranceProviders]')
      AND c.name = N'InsuranceProviderId'
)
BEGIN
ALTER TABLE [Profile].[InsuranceProviders] ADD DEFAULT (newid()) FOR [InsuranceProviderId]
END
GO

IF OBJECT_ID(N'[Profile].[InsuranceProviders]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Location].[Address]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[InsuranceProviders]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[InsuranceProviders]'), N'AddressIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Location].[Address]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Location].[Address]'), N'AddressId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[InsuranceProviders] WITH CHECK ADD FOREIGN KEY([AddressIdFK])
REFERENCES [Location].[Address] ([AddressId])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[InsuranceProviders]') AND name = 'IX_InsuranceProviders_ProviderName')
BEGIN
CREATE INDEX IX_InsuranceProviders_ProviderName ON [Profile].[InsuranceProviders]([ProviderName])
END
GO
