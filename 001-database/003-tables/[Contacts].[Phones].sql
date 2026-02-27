USE HealthcareForm
GO

/****** Object:  Table [Contacts].[Phones]    Script Date: 13-May-22 02:11:06 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[Contacts].[Phones]', N'U') IS NULL
BEGIN
CREATE TABLE [Contacts].[Phones](
	[PhoneId] [uniqueidentifier] NOT NULL,
	[PhoneNumber] [varchar](15) NOT NULL UNIQUE,
	[IsActive] [bit] NOT NULL,
	[UpdateDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[PhoneId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

IF OBJECT_ID(N'[Contacts].[Phones]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Contacts].[Phones]')
      AND c.name = N'PhoneId'
)
BEGIN
ALTER TABLE [Contacts].[Phones] ADD  DEFAULT (newid()) FOR [PhoneId]
END
GO

-- Create index for phone lookups
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[Phones]') AND name = 'IX_Phones_PhoneNumber')
BEGIN
CREATE INDEX IX_Phones_PhoneNumber ON [Contacts].[Phones]([PhoneNumber])
END
GO


