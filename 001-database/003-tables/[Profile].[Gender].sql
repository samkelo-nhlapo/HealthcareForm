USE HealthcareForm
GO

/****** Object:  Table [Profile].[Gender]    Script Date: 13-May-22 02:11:52 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[Profile].[Gender]', N'U') IS NULL
BEGIN
CREATE TABLE [Profile].[Gender](
	[GenderId] [int] IDENTITY(1,1) NOT NULL,
	[GenderDescription] [varchar](250) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[UpdateDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[GenderId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO


