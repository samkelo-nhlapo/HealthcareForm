USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Individual form field values and answers for each form submission
--	TFS Task:		Healthcare form - form field values
--================================================================================================

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[Contacts].[FormFieldValues]', N'U') IS NULL
BEGIN
CREATE TABLE [Contacts].[FormFieldValues](
	[FormFieldValueId] [uniqueidentifier] NOT NULL,
	[FormSubmissionIdFK] [uniqueidentifier] NOT NULL,
	[FieldName] [varchar](250) NOT NULL, -- Question/field name
	[FieldType] [varchar](50) NOT NULL, -- Text, TextArea, Date, Checkbox, Radio, Select, File
	[FieldValue] [varchar](MAX) NOT NULL, -- Answer/value
	[DisplayOrder] [int] NULL, -- Order of fields in form
	[IsRequired] [bit] NOT NULL DEFAULT 0,
	[ValidationRules] [varchar](MAX) NULL, -- JSON validation rules
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[FormFieldValueId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

IF OBJECT_ID(N'[Contacts].[FormFieldValues]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Contacts].[FormFieldValues]')
      AND c.name = N'FormFieldValueId'
)
BEGIN
ALTER TABLE [Contacts].[FormFieldValues] ADD DEFAULT (newid()) FOR [FormFieldValueId]
END
GO

IF OBJECT_ID(N'[Contacts].[FormFieldValues]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Contacts].[FormSubmissions]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Contacts].[FormFieldValues]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Contacts].[FormFieldValues]'), N'FormSubmissionIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Contacts].[FormSubmissions]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Contacts].[FormSubmissions]'), N'FormSubmissionId', 'ColumnId')
)
BEGIN
ALTER TABLE [Contacts].[FormFieldValues] WITH CHECK ADD FOREIGN KEY([FormSubmissionIdFK])
REFERENCES [Contacts].[FormSubmissions] ([FormSubmissionId])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[FormFieldValues]') AND name = 'IX_FormFieldValues_FormSubmissionIdFK')
BEGIN
CREATE INDEX IX_FormFieldValues_FormSubmissionIdFK ON [Contacts].[FormFieldValues]([FormSubmissionIdFK])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[FormFieldValues]') AND name = 'IX_FormFieldValues_FieldName')
BEGIN
CREATE INDEX IX_FormFieldValues_FieldName ON [Contacts].[FormFieldValues]([FieldName])
END
GO
