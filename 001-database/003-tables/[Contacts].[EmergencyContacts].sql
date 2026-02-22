USE HealthcareForm
GO

/****** Object:  Table [Contacts].[EmergencyContacts]    Script Date: 13-May-22 02:10:50 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Contacts].[EmergencyContacts](
	[EmergencyId] [uniqueidentifier] NOT NULL,
	[FirstName] [varchar](250) NOT NULL,
	[LastName] [varchar](250) NOT NULL,
	[PhoneNumber] [varchar](250) NOT NULL,
	[Relationship] [varchar](250) NOT NULL,
	[DateOfBirth] [datetime] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[UpdateDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[EmergencyId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [Contacts].[EmergencyContacts] ADD  DEFAULT (newid()) FOR [EmergencyId]
GO


