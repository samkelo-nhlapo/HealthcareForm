USE HealthcareForm
GO

/****** Object:  Table [Location].[Provinces]    Script Date: 13-May-22 02:09:04 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[Location].[Provinces]', N'U') IS NULL
BEGIN
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
END
GO

IF OBJECT_ID(N'[Location].[Provinces]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Location].[Countries]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Location].[Provinces]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Location].[Provinces]'), N'CountryIDFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Location].[Countries]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Location].[Countries]'), N'CountryId', 'ColumnId')
)
BEGIN
ALTER TABLE [Location].[Provinces]  WITH CHECK ADD FOREIGN KEY([CountryIDFK])
REFERENCES [Location].[Countries] ([CountryId])
END
GO


