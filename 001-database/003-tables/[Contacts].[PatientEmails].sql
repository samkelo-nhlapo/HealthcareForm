USE HealthcareForm
GO

/****** Object:  Table [Contacts].[PatientEmails] - Junction Table ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- This junction table allows patients to have multiple email addresses
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
GO

ALTER TABLE [Contacts].[PatientEmails] ADD DEFAULT (newid()) FOR [PatientEmailId]
GO

-- Foreign key to Patient
ALTER TABLE [Contacts].[PatientEmails] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
REFERENCES [Profile].[Patient] ([PatientId])
GO

-- Foreign key to Emails
ALTER TABLE [Contacts].[PatientEmails] WITH CHECK ADD FOREIGN KEY([EmailIdFK])
REFERENCES [Contacts].[Emails] ([EmailId])
GO

-- Create indexes for performance
CREATE INDEX IX_PatientEmails_PatientIdFK ON [Contacts].[PatientEmails]([PatientIdFK])
GO

CREATE INDEX IX_PatientEmails_EmailIdFK ON [Contacts].[PatientEmails]([EmailIdFK])
GO

-- Unique constraint to prevent duplicate email assignments
CREATE UNIQUE INDEX UX_PatientEmails_Unique ON [Contacts].[PatientEmails]([PatientIdFK], [EmailIdFK])
GO
