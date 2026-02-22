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
GO

ALTER TABLE [Profile].[InsuranceProviders] ADD DEFAULT (newid()) FOR [InsuranceProviderId]
GO

ALTER TABLE [Profile].[InsuranceProviders] WITH CHECK ADD FOREIGN KEY([AddressIdFK])
REFERENCES [Location].[Address] ([AddressId])
GO

CREATE INDEX IX_InsuranceProviders_ProviderName ON [Profile].[InsuranceProviders]([ProviderName])
GO
