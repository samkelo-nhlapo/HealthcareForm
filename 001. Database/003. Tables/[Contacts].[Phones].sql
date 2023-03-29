USE HealthcareForm
GO

/****** Object:  Table [Contacts].[Phones]    Script Date: 13-May-22 02:11:06 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Contacts].[Phones](
	[PhoneId] [uniqueidentifier] NOT NULL,
	[PhoneNumber] [varchar](15) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[UpdateDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[PhoneId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [Contacts].[Phones] ADD  DEFAULT (newid()) FOR [PhoneId]
GO


