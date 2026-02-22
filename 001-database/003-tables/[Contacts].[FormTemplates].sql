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
GO

ALTER TABLE [Contacts].[FormTemplates] ADD DEFAULT (newid()) FOR [FormTemplateId]
GO

CREATE INDEX IX_FormTemplates_FormType ON [Contacts].[FormTemplates]([FormType])
GO

CREATE INDEX IX_FormTemplates_IsActive ON [Contacts].[FormTemplates]([IsActive])
GO
