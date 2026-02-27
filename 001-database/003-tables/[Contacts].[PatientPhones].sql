USE HealthcareForm
GO

/****** Object:  Table [Contacts].[PatientPhones] - Junction Table ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- This junction table allows patients to have multiple phone numbers
IF OBJECT_ID(N'[Contacts].[PatientPhones]', N'U') IS NULL
BEGIN
CREATE TABLE [Contacts].[PatientPhones](
	[PatientPhoneId] [uniqueidentifier] NOT NULL,
	[PatientIdFK] [uniqueidentifier] NOT NULL,
	[PhoneIdFK] [uniqueidentifier] NOT NULL,
	[IsPrimary] [bit] NOT NULL DEFAULT 0,
	[PhoneType] [varchar](50) NULL, -- e.g., 'Mobile', 'Home', 'Work'
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[PatientPhoneId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

IF OBJECT_ID(N'[Contacts].[PatientPhones]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Contacts].[PatientPhones]')
      AND c.name = N'PatientPhoneId'
)
BEGIN
ALTER TABLE [Contacts].[PatientPhones] ADD DEFAULT (newid()) FOR [PatientPhoneId]
END
GO

-- Foreign key to Patient
IF OBJECT_ID(N'[Contacts].[PatientPhones]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Contacts].[PatientPhones]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Contacts].[PatientPhones]'), N'PatientIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[Patient]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Patient]'), N'PatientId', 'ColumnId')
)
BEGIN
ALTER TABLE [Contacts].[PatientPhones] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
REFERENCES [Profile].[Patient] ([PatientId])
END
GO

-- Foreign key to Phones
IF OBJECT_ID(N'[Contacts].[PatientPhones]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Contacts].[Phones]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Contacts].[PatientPhones]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Contacts].[PatientPhones]'), N'PhoneIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Contacts].[Phones]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Contacts].[Phones]'), N'PhoneId', 'ColumnId')
)
BEGIN
ALTER TABLE [Contacts].[PatientPhones] WITH CHECK ADD FOREIGN KEY([PhoneIdFK])
REFERENCES [Contacts].[Phones] ([PhoneId])
END
GO

-- Create indexes for performance
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[PatientPhones]') AND name = 'IX_PatientPhones_PatientIdFK')
BEGIN
CREATE INDEX IX_PatientPhones_PatientIdFK ON [Contacts].[PatientPhones]([PatientIdFK])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[PatientPhones]') AND name = 'IX_PatientPhones_PhoneIdFK')
BEGIN
CREATE INDEX IX_PatientPhones_PhoneIdFK ON [Contacts].[PatientPhones]([PhoneIdFK])
END
GO

-- Unique constraint to prevent duplicate phone assignments
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[PatientPhones]') AND name = 'UX_PatientPhones_Unique')
BEGIN
CREATE UNIQUE INDEX UX_PatientPhones_Unique ON [Contacts].[PatientPhones]([PatientIdFK], [PhoneIdFK])
END
GO
