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

IF OBJECT_ID(N'[Profile].[Invoices]', N'U') IS NULL
BEGIN
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
END
GO

IF OBJECT_ID(N'[Profile].[Invoices]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[Invoices]')
      AND c.name = N'InvoiceId'
)
BEGIN
ALTER TABLE [Profile].[Invoices] ADD DEFAULT (newid()) FOR [InvoiceId]
END
GO

IF OBJECT_ID(N'[Profile].[Invoices]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[Invoices]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Invoices]'), N'PatientIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[Patient]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Patient]'), N'PatientId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[Invoices] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
REFERENCES [Profile].[Patient] ([PatientId])
END
GO

IF OBJECT_ID(N'[Profile].[Invoices]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[HealthcareProviders]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[Invoices]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Invoices]'), N'ProviderIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[HealthcareProviders]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[HealthcareProviders]'), N'ProviderId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[Invoices] WITH CHECK ADD FOREIGN KEY([ProviderIdFK])
REFERENCES [Profile].[HealthcareProviders] ([ProviderId])
END
GO

IF OBJECT_ID(N'[Profile].[Invoices]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[BillingCodes]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[Invoices]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Invoices]'), N'BillingCodeIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[BillingCodes]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[BillingCodes]'), N'BillingCodeId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[Invoices] WITH CHECK ADD FOREIGN KEY([BillingCodeIdFK])
REFERENCES [Profile].[BillingCodes] ([BillingCodeId])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Invoices]') AND name = 'IX_Invoices_PatientIdFK')
BEGIN
CREATE INDEX IX_Invoices_PatientIdFK ON [Profile].[Invoices]([PatientIdFK])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Invoices]') AND name = 'IX_Invoices_Status')
BEGIN
CREATE INDEX IX_Invoices_Status ON [Profile].[Invoices]([Status])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Invoices]') AND name = 'IX_Invoices_InvoiceDate')
BEGIN
CREATE INDEX IX_Invoices_InvoiceDate ON [Profile].[Invoices]([InvoiceDate])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Invoices]') AND name = 'IX_Invoices_DueDate')
BEGIN
CREATE INDEX IX_Invoices_DueDate ON [Profile].[Invoices]([DueDate])
END
GO
