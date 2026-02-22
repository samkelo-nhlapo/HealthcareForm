USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Patient invoices for healthcare services and billing
--	TFS Task:		Healthcare form - invoicing
--================================================================================================

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Profile].[Invoices](
	[InvoiceId] [uniqueidentifier] NOT NULL,
	[PatientIdFK] [uniqueidentifier] NOT NULL,
	[InvoiceNumber] [varchar](100) NOT NULL UNIQUE,
	[InvoiceDate] [datetime] NOT NULL,
	[DueDate] [datetime] NOT NULL,
	[ServiceDate] [datetime] NOT NULL,
	[ProviderIdFK] [uniqueidentifier] NOT NULL,
	[BillingCodeIdFK] [uniqueidentifier] NOT NULL,
	[Description] [varchar](MAX) NOT NULL,
	[Quantity] [int] NOT NULL DEFAULT 1,
	[UnitPrice] [decimal](10,2) NOT NULL,
	[TotalAmount] [decimal](10,2) NOT NULL,
	[InsuranceCoverage] [decimal](10,2) NULL,
	[PatientResponsibility] [decimal](10,2) NOT NULL,
	[Discount] [decimal](10,2) NULL DEFAULT 0,
	[Status] [varchar](50) NOT NULL DEFAULT 'Draft', -- Draft, Sent, Partial Paid, Paid, Overdue, Cancelled
	[PaymentMethod] [varchar](50) NULL, -- Cash, Credit Card, Insurance, Check
	[PaymentDate] [datetime] NULL,
	[Notes] [varchar](MAX) NULL,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[InvoiceId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [Profile].[Invoices] ADD DEFAULT (newid()) FOR [InvoiceId]
GO

ALTER TABLE [Profile].[Invoices] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
REFERENCES [Profile].[Patient] ([PatientId])
GO

ALTER TABLE [Profile].[Invoices] WITH CHECK ADD FOREIGN KEY([ProviderIdFK])
REFERENCES [Profile].[HealthcareProviders] ([ProviderId])
GO

ALTER TABLE [Profile].[Invoices] WITH CHECK ADD FOREIGN KEY([BillingCodeIdFK])
REFERENCES [Profile].[BillingCodes] ([BillingCodeId])
GO

CREATE INDEX IX_Invoices_PatientIdFK ON [Profile].[Invoices]([PatientIdFK])
GO

CREATE INDEX IX_Invoices_Status ON [Profile].[Invoices]([Status])
GO

CREATE INDEX IX_Invoices_InvoiceDate ON [Profile].[Invoices]([InvoiceDate])
GO

CREATE INDEX IX_Invoices_DueDate ON [Profile].[Invoices]([DueDate])
GO
