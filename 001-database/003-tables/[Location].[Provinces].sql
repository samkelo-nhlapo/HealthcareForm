USE HealthcareForm
GO

/****** Object:  Table [Location].[Provinces]    Script Date: 13-May-22 02:09:04 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Location].[Provinces](
	[ProvinceId] [int] IDENTITY(1,1) NOT NULL,
	[ProvinceName] [varchar](250) NOT NULL,
	[CountryIDFK] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[UpdateDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ProvinceId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [Location].[Provinces]  WITH CHECK ADD FOREIGN KEY([CountryIDFK])
REFERENCES [Location].[Countries] ([CountryId])
GO


