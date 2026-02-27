USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Form template definitions for different healthcare forms
--	TFS Task:		Healthcare form - form templates
--================================================================================================

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[Contacts].[FormTemplates]', N'U') IS NULL
BEGIN
CREATE TABLE [Contacts].[FormTemplates](
	[FormTemplateId] [uniqueidentifier] NOT NULL,
	[FormName] [varchar](250) NOT NULL UNIQUE,
	[FormVersion] [varchar](20) NOT NULL DEFAULT '1.0',
	[Description] [varchar](MAX) NULL,
	[FormType] [varchar](100) NOT NULL, -- Intake, Consent, Medical History, Insurance, Discharge, etc.
	[IsActive] [bit] NOT NULL DEFAULT 1,
	[RequiresSignature] [bit] NOT NULL DEFAULT 1,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[FormTemplateId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

IF OBJECT_ID(N'[Contacts].[FormTemplates]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Contacts].[FormTemplates]')
      AND c.name = N'FormTemplateId'
)
BEGIN
ALTER TABLE [Contacts].[FormTemplates] ADD DEFAULT (newid()) FOR [FormTemplateId]
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[FormTemplates]') AND name = 'IX_FormTemplates_FormType')
BEGIN
CREATE INDEX IX_FormTemplates_FormType ON [Contacts].[FormTemplates]([FormType])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[FormTemplates]') AND name = 'IX_FormTemplates_IsActive')
BEGIN
CREATE INDEX IX_FormTemplates_IsActive ON [Contacts].[FormTemplates]([IsActive])
END
GO
