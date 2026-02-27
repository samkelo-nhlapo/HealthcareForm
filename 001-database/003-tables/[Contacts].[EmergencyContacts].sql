USE HealthcareForm
GO

/****** Object:  Table [Contacts].[EmergencyContacts]    Script Date: 13-May-22 02:10:50 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[Contacts].[EmergencyContacts]', N'U') IS NULL
BEGIN
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
END
GO

IF OBJECT_ID(N'[Contacts].[EmergencyContacts]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Contacts].[EmergencyContacts]')
      AND c.name = N'EmergencyId'
)
BEGIN
ALTER TABLE [Contacts].[EmergencyContacts] ADD  DEFAULT (newid()) FOR [EmergencyId]
END
GO


