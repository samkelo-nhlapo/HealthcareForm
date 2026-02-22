USE HealthcareForm
GO

/****** Object:  Table [Location].[Countries]    Script Date: 13-May-22 02:08:40 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Location].[Countries](
	[CountryId] [int] IDENTITY(1,1) NOT NULL,
	[CountryName] [varchar](250) NOT NULL,
	[Alpha2Code] [varchar](5) NOT NULL,
	[Alpha3Code] [varchar](5) NOT NULL,
	[Numeric] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[UpdateDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[CountryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


