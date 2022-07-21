USE HealthcareForm
GO

/****** Object:  Table [Location].[Address]    Script Date: 13-May-22 02:11:24 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Location].[Address](
	[AddressId] [uniqueidentifier] NOT NULL,
	[Line1] [varchar](250) NOT NULL,
	[Line2] [varchar](250) NOT NULL,
	[CityIDFK] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[AddressId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [Location].[Address] ADD  DEFAULT (newid()) FOR [AddressId]
GO

ALTER TABLE [Location].[Address]  WITH CHECK ADD FOREIGN KEY([CityIDFK])
REFERENCES [Location].[Cities] ([CityId])
GO


