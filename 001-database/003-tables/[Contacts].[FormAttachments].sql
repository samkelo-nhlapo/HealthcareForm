USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Form attachments for documents, medical records, and supporting files
--	TFS Task:		Healthcare form - file attachments
--================================================================================================

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Contacts].[FormAttachments](
	[FormAttachmentId] [uniqueidentifier] NOT NULL,
	[FormSubmissionIdFK] [uniqueidentifier] NOT NULL,
	[FileName] [varchar](500) NOT NULL,
	[FileType] [varchar](50) NOT NULL, -- PDF, DOC, JPG, PNG, etc.
	[FileSizeBytes] [bigint] NOT NULL,
	[FileHash] [varchar](64) NULL, -- SHA-256 hash for integrity verification
	[StoragePath] [varchar](MAX) NOT NULL, -- Path/URL to file storage
	[DocumentType] [varchar](100) NOT NULL, -- Medical Record, Prescription, ID, Insurance, Other
	[UploadedDate] [datetime] NOT NULL,
	[UploadedBy] [varchar](250) NOT NULL,
	[IsVerified] [bit] NOT NULL DEFAULT 0,
	[VerifiedBy] [varchar](250) NULL,
	[VerificationDate] [datetime] NULL,
	[ExpiryDate] [datetime] NULL, -- For documents that expire (licenses, insurance)
	[Notes] [varchar](MAX) NULL,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[FormAttachmentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [Contacts].[FormAttachments] ADD DEFAULT (newid()) FOR [FormAttachmentId]
GO

ALTER TABLE [Contacts].[FormAttachments] WITH CHECK ADD FOREIGN KEY([FormSubmissionIdFK])
REFERENCES [Contacts].[FormSubmissions] ([FormSubmissionId])
GO

CREATE INDEX IX_FormAttachments_FormSubmissionIdFK ON [Contacts].[FormAttachments]([FormSubmissionIdFK])
GO

CREATE INDEX IX_FormAttachments_DocumentType ON [Contacts].[FormAttachments]([DocumentType])
GO

CREATE INDEX IX_FormAttachments_UploadedDate ON [Contacts].[FormAttachments]([UploadedDate])
GO
