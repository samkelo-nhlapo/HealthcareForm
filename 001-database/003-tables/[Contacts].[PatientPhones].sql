USE HealthcareForm
GO

/****** Object:  Table [Contacts].[PatientPhones] - Junction Table ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- This junction table allows patients to have multiple phone numbers
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
GO

ALTER TABLE [Contacts].[PatientPhones] ADD DEFAULT (newid()) FOR [PatientPhoneId]
GO

-- Foreign key to Patient
ALTER TABLE [Contacts].[PatientPhones] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
REFERENCES [Profile].[Patient] ([PatientId])
GO

-- Foreign key to Phones
ALTER TABLE [Contacts].[PatientPhones] WITH CHECK ADD FOREIGN KEY([PhoneIdFK])
REFERENCES [Contacts].[Phones] ([PhoneId])
GO

-- Create indexes for performance
CREATE INDEX IX_PatientPhones_PatientIdFK ON [Contacts].[PatientPhones]([PatientIdFK])
GO

CREATE INDEX IX_PatientPhones_PhoneIdFK ON [Contacts].[PatientPhones]([PhoneIdFK])
GO

-- Unique constraint to prevent duplicate phone assignments
CREATE UNIQUE INDEX UX_PatientPhones_Unique ON [Contacts].[PatientPhones]([PatientIdFK], [PhoneIdFK])
GO
