USE HealthcareForm
GO

/****** Object:  Table [Contacts].[Emails]    Script Date: 13-May-22 02:10:27 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[Contacts].[Emails]', N'U') IS NULL
BEGIN
CREATE TABLE [Contacts].[Emails](
	[EmailId] [uniqueidentifier] NOT NULL,
	[Email] [varchar](250) NOT NULL UNIQUE,
	[IsActive] [bit] NOT NULL,
	[UpdateDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[EmailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

IF OBJECT_ID(N'[Contacts].[Emails]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Contacts].[Emails]')
      AND c.name = N'EmailId'
)
BEGIN
ALTER TABLE [Contacts].[Emails] ADD  DEFAULT (newid()) FOR [EmailId]
END
GO

-- Create index for email lookups
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[Emails]') AND name = 'IX_Emails_Email')
BEGIN
CREATE INDEX IX_Emails_Email ON [Contacts].[Emails]([Email])
END
GO


