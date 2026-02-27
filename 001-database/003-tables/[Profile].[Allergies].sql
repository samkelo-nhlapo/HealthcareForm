USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Patient allergies tracking including drug, food, and environmental allergies
--	TFS Task:		Healthcare form - allergy capture
--================================================================================================

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[Profile].[Allergies]', N'U') IS NULL
BEGIN
CREATE TABLE [Profile].[Allergies](
	[AllergyId] [uniqueidentifier] NOT NULL,
	[PatientIdFK] [uniqueidentifier] NOT NULL,
	[AllergyType] [varchar](50) NOT NULL, -- Drug, Food, Environmental, Other
	[AllergenName] [varchar](250) NOT NULL,
	[Reaction] [varchar](MAX) NOT NULL, -- Description of allergic reaction
	[Severity] [varchar](50) NOT NULL DEFAULT 'Moderate', -- Mild, Moderate, Severe, Life-threatening
	[ReactionOnsetDate] [datetime] NULL,
	[VerifiedBy] [varchar](250) NULL, -- Doctor who verified
	[IsActive] [bit] NOT NULL DEFAULT 1,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[AllergyId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

IF OBJECT_ID(N'[Profile].[Allergies]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[Allergies]')
      AND c.name = N'AllergyId'
)
BEGIN
ALTER TABLE [Profile].[Allergies] ADD DEFAULT (newid()) FOR [AllergyId]
END
GO

IF OBJECT_ID(N'[Profile].[Allergies]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[Allergies]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Allergies]'), N'PatientIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[Patient]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Patient]'), N'PatientId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[Allergies] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
REFERENCES [Profile].[Patient] ([PatientId])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Allergies]') AND name = 'IX_Allergies_PatientIdFK')
BEGIN
CREATE INDEX IX_Allergies_PatientIdFK ON [Profile].[Allergies]([PatientIdFK])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Allergies]') AND name = 'IX_Allergies_AllergyType')
BEGIN
CREATE INDEX IX_Allergies_AllergyType ON [Profile].[Allergies]([AllergyType])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Allergies]') AND name = 'IX_Allergies_Severity')
BEGIN
CREATE INDEX IX_Allergies_Severity ON [Profile].[Allergies]([Severity])
END
GO
