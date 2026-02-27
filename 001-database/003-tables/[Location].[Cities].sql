USE HealthcareForm
GO

/****** Object:  Table [Location].[Cities]    Script Date: 13-May-22 02:09:56 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[Location].[Cities]', N'U') IS NULL
BEGIN
CREATE TABLE [Location].[Cities](
	[CityId] [int] IDENTITY(1,1) NOT NULL,
	[CityName] [varchar](250) NOT NULL,
	[ProvinceIDFK] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[UpdateDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[CityId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

IF OBJECT_ID(N'[Location].[Cities]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Location].[Provinces]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Location].[Cities]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Location].[Cities]'), N'ProvinceIDFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Location].[Provinces]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Location].[Provinces]'), N'ProvinceId', 'ColumnId')
)
BEGIN
ALTER TABLE [Location].[Cities]  WITH CHECK ADD FOREIGN KEY([ProvinceIDFK])
REFERENCES [Location].[Provinces] ([ProvinceId])
END
GO


