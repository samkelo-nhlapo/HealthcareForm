USE HealthcareForm
GO

/****** Object:  Table [Contacts].[Emails]    Script Date: 13-May-22 02:10:27 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Contacts].[Emails](
	[EmailId] [uniqueidentifier] NOT NULL,
	[Email] [varchar](250) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[UpdateDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[EmailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [Contacts].[Emails] ADD  DEFAULT (newid()) FOR [EmailId]
GO


