USE HealthcareForm
GO

/****** Object:  Table [Contacts].[PatientEmails] - Junction Table ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- This junction table allows patients to have multiple email addresses
IF OBJECT_ID(N'[Contacts].[PatientEmails]', N'U') IS NULL
BEGIN
CREATE TABLE [Contacts].[PatientEmails](
	[PatientEmailId] [uniqueidentifier] NOT NULL,
	[PatientIdFK] [uniqueidentifier] NOT NULL,
	[EmailIdFK] [uniqueidentifier] NOT NULL,
	[IsPrimary] [bit] NOT NULL DEFAULT 0,
	[EmailType] [varchar](50) NULL, -- e.g., 'Personal', 'Work'
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[PatientEmailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

IF OBJECT_ID(N'[Contacts].[PatientEmails]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Contacts].[PatientEmails]')
      AND c.name = N'PatientEmailId'
)
BEGIN
ALTER TABLE [Contacts].[PatientEmails] ADD DEFAULT (newid()) FOR [PatientEmailId]
END
GO

-- Foreign key to Patient
IF OBJECT_ID(N'[Contacts].[PatientEmails]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Contacts].[PatientEmails]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Contacts].[PatientEmails]'), N'PatientIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[Patient]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Patient]'), N'PatientId', 'ColumnId')
)
BEGIN
ALTER TABLE [Contacts].[PatientEmails] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
REFERENCES [Profile].[Patient] ([PatientId])
END
GO

-- Foreign key to Emails
IF OBJECT_ID(N'[Contacts].[PatientEmails]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Contacts].[Emails]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Contacts].[PatientEmails]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Contacts].[PatientEmails]'), N'EmailIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Contacts].[Emails]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Contacts].[Emails]'), N'EmailId', 'ColumnId')
)
BEGIN
ALTER TABLE [Contacts].[PatientEmails] WITH CHECK ADD FOREIGN KEY([EmailIdFK])
REFERENCES [Contacts].[Emails] ([EmailId])
END
GO

-- Create indexes for performance
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[PatientEmails]') AND name = 'IX_PatientEmails_PatientIdFK')
BEGIN
CREATE INDEX IX_PatientEmails_PatientIdFK ON [Contacts].[PatientEmails]([PatientIdFK])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[PatientEmails]') AND name = 'IX_PatientEmails_EmailIdFK')
BEGIN
CREATE INDEX IX_PatientEmails_EmailIdFK ON [Contacts].[PatientEmails]([EmailIdFK])
END
GO

-- Unique constraint to prevent duplicate email assignments
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[PatientEmails]') AND name = 'UX_PatientEmails_Unique')
BEGIN
CREATE UNIQUE INDEX UX_PatientEmails_Unique ON [Contacts].[PatientEmails]([PatientIdFK], [EmailIdFK])
END
GO
