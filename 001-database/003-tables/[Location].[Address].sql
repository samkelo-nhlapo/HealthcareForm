USE HealthcareForm
GO

/****** Object:  Table [Location].[Address]    Script Date: 13-May-22 02:11:24 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[Location].[Address]', N'U') IS NULL
BEGIN
CREATE TABLE [Location].[Address](
	[AddressId] [uniqueidentifier] NOT NULL,
	[Line1] [varchar](250) NOT NULL,
	[Line2] [varchar](250) NOT NULL,
	[CityIDFK] [int] NOT NULL,
	[UpdateDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[AddressId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

IF OBJECT_ID(N'[Location].[Address]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Location].[Address]')
      AND c.name = N'AddressId'
)
BEGIN
ALTER TABLE [Location].[Address] ADD  DEFAULT (newid()) FOR [AddressId]
END
GO

IF OBJECT_ID(N'[Location].[Address]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Location].[Cities]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Location].[Address]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Location].[Address]'), N'CityIDFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Location].[Cities]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Location].[Cities]'), N'CityId', 'ColumnId')
)
BEGIN
ALTER TABLE [Location].[Address]  WITH CHECK ADD FOREIGN KEY([CityIDFK])
REFERENCES [Location].[Cities] ([CityId])
END
GO

-- Create index for city lookups
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Location].[Address]') AND name = 'IX_Address_CityIDFK')
BEGIN
CREATE INDEX IX_Address_CityIDFK ON [Location].[Address]([CityIDFK])
END
GO


