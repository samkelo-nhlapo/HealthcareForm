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
	[ID_Number] [varchar](250) NOT NULL,
	[DateOfBirth] [datetime] NOT NULL,
	[GenderIDFK] [int] NOT NULL,
	[MedicationList] [varchar](250) NOT NULL,
	[EmailIDFK] [uniqueidentifier] NOT NULL,
	[PhoneIDFK] [uniqueidentifier] NOT NULL,
	[AddressIDFK] [uniqueidentifier] NOT NULL,
	[MaritalStatusIDFK] [int] NOT NULL,
	[EmergencyIDFK] [uniqueidentifier] NOT NULL,
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

ALTER TABLE [Profile].[Patient]  WITH CHECK ADD FOREIGN KEY([EmailIDFK])
REFERENCES [Contacts].[Emails] ([EmailId])
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

ALTER TABLE [Profile].[Patient]  WITH CHECK ADD FOREIGN KEY([PhoneIDFK])
REFERENCES [Contacts].[Phones] ([PhoneId])
GO


