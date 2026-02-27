USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Patient form submissions with status tracking
--	TFS Task:		Healthcare form - form submissions
--================================================================================================

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[Contacts].[FormSubmissions]', N'U') IS NULL
BEGIN
CREATE TABLE [Contacts].[FormSubmissions](
	[FormSubmissionId] [uniqueidentifier] NOT NULL,
	[PatientIdFK] [uniqueidentifier] NOT NULL,
	[FormTemplateIdFK] [uniqueidentifier] NOT NULL,
	[SubmissionDate] [datetime] NOT NULL,
	[CompletionDate] [datetime] NULL,
	[Status] [varchar](50) NOT NULL DEFAULT 'Draft', -- Draft, Submitted, Pending Review, Approved, Rejected, Signed
	[ReviewedBy] [varchar](250) NULL,
	[ReviewDate] [datetime] NULL,
	[RejectionReason] [varchar](MAX) NULL,
	[SignatureDate] [datetime] NULL,
	[SignedBy] [varchar](250) NULL, -- Patient or authorized person
	[IPAddress] [varchar](50) NULL,
	[UserAgent] [varchar](500) NULL, -- Browser/device info
	[Notes] [varchar](MAX) NULL,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[FormSubmissionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

IF OBJECT_ID(N'[Contacts].[FormSubmissions]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Contacts].[FormSubmissions]')
      AND c.name = N'FormSubmissionId'
)
BEGIN
ALTER TABLE [Contacts].[FormSubmissions] ADD DEFAULT (newid()) FOR [FormSubmissionId]
END
GO

IF OBJECT_ID(N'[Contacts].[FormSubmissions]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Contacts].[FormSubmissions]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Contacts].[FormSubmissions]'), N'PatientIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[Patient]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Patient]'), N'PatientId', 'ColumnId')
)
BEGIN
ALTER TABLE [Contacts].[FormSubmissions] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
REFERENCES [Profile].[Patient] ([PatientId])
END
GO

IF OBJECT_ID(N'[Contacts].[FormSubmissions]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Contacts].[FormTemplates]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Contacts].[FormSubmissions]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Contacts].[FormSubmissions]'), N'FormTemplateIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Contacts].[FormTemplates]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Contacts].[FormTemplates]'), N'FormTemplateId', 'ColumnId')
)
BEGIN
ALTER TABLE [Contacts].[FormSubmissions] WITH CHECK ADD FOREIGN KEY([FormTemplateIdFK])
REFERENCES [Contacts].[FormTemplates] ([FormTemplateId])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[FormSubmissions]') AND name = 'IX_FormSubmissions_PatientIdFK')
BEGIN
CREATE INDEX IX_FormSubmissions_PatientIdFK ON [Contacts].[FormSubmissions]([PatientIdFK])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[FormSubmissions]') AND name = 'IX_FormSubmissions_FormTemplateIdFK')
BEGIN
CREATE INDEX IX_FormSubmissions_FormTemplateIdFK ON [Contacts].[FormSubmissions]([FormTemplateIdFK])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[FormSubmissions]') AND name = 'IX_FormSubmissions_Status')
BEGIN
CREATE INDEX IX_FormSubmissions_Status ON [Contacts].[FormSubmissions]([Status])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[FormSubmissions]') AND name = 'IX_FormSubmissions_SubmissionDate')
BEGIN
CREATE INDEX IX_FormSubmissions_SubmissionDate ON [Contacts].[FormSubmissions]([SubmissionDate])
END
GO
