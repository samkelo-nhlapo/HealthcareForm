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
GO

ALTER TABLE [Contacts].[FormSubmissions] ADD DEFAULT (newid()) FOR [FormSubmissionId]
GO

ALTER TABLE [Contacts].[FormSubmissions] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
REFERENCES [Profile].[Patient] ([PatientId])
GO

ALTER TABLE [Contacts].[FormSubmissions] WITH CHECK ADD FOREIGN KEY([FormTemplateIdFK])
REFERENCES [Contacts].[FormTemplates] ([FormTemplateId])
GO

CREATE INDEX IX_FormSubmissions_PatientIdFK ON [Contacts].[FormSubmissions]([PatientIdFK])
GO

CREATE INDEX IX_FormSubmissions_FormTemplateIdFK ON [Contacts].[FormSubmissions]([FormTemplateIdFK])
GO

CREATE INDEX IX_FormSubmissions_Status ON [Contacts].[FormSubmissions]([Status])
GO

CREATE INDEX IX_FormSubmissions_SubmissionDate ON [Contacts].[FormSubmissions]([SubmissionDate])
GO
