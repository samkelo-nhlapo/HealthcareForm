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
GO

ALTER TABLE [Contacts].[FormFieldValues] ADD DEFAULT (newid()) FOR [FormFieldValueId]
GO

ALTER TABLE [Contacts].[FormFieldValues] WITH CHECK ADD FOREIGN KEY([FormSubmissionIdFK])
REFERENCES [Contacts].[FormSubmissions] ([FormSubmissionId])
GO

CREATE INDEX IX_FormFieldValues_FormSubmissionIdFK ON [Contacts].[FormFieldValues]([FormSubmissionIdFK])
GO

CREATE INDEX IX_FormFieldValues_FieldName ON [Contacts].[FormFieldValues]([FieldName])
GO
