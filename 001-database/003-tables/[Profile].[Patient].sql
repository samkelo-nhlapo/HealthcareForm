USE HealthcareForm
GO

/****** Object:  Table [Profile].[Patient]    Script Date: 13-May-22 02:12:25 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Profile].[Patient](
	[PatientId] [uniqueidentifier] NOT NULL,
	[FirstName] [varchar](250) NOT NULL,
	[LastName] [varchar](250) NOT NULL,
	[ID_Number] [varchar](250) NOT NULL UNIQUE,
	[DateOfBirth] [datetime] NOT NULL,
	[GenderIDFK] [int] NOT NULL,
	[MedicationList] [varchar](MAX) NULL,
	[AddressIDFK] [uniqueidentifier] NULL,
	[MaritalStatusIDFK] [int] NOT NULL,
	[EmergencyIDFK] [uniqueidentifier] NULL,
	[IsDeleted] [BIT] NOT NULL DEFAULT 0,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[PatientId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [Profile].[Patient] ADD  DEFAULT (newid()) FOR [PatientId]
GO

ALTER TABLE [Profile].[Patient]  WITH CHECK ADD FOREIGN KEY([AddressIDFK])
REFERENCES [Location].[Address] ([AddressId])
GO

ALTER TABLE [Profile].[Patient]  WITH CHECK ADD FOREIGN KEY([EmergencyIDFK])
REFERENCES [Contacts].[EmergencyContacts] ([EmergencyId])
GO

ALTER TABLE [Profile].[Patient]  WITH CHECK ADD FOREIGN KEY([GenderIDFK])
REFERENCES [Profile].[Gender] ([GenderId])
GO

ALTER TABLE [Profile].[Patient]  WITH CHECK ADD FOREIGN KEY([MaritalStatusIDFK])
REFERENCES [Profile].[MaritalStatus] ([MaritalStatusId])
GO

-- Create indexes for frequent searches
CREATE INDEX IX_Patient_IDNumber ON [Profile].[Patient]([ID_Number])
GO

CREATE INDEX IX_Patient_LastName ON [Profile].[Patient]([LastName])
GO

CREATE INDEX IX_Patient_IsDeleted ON [Profile].[Patient]([IsDeleted])
GO


