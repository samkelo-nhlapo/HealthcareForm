USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Medical history tracking for patient chronic conditions and past medical events
--	TFS Task:		Healthcare form - medical history capture
--================================================================================================

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[Profile].[MedicalHistory]', N'U') IS NULL
BEGIN
CREATE TABLE [Profile].[MedicalHistory](
	[MedicalHistoryId] [uniqueidentifier] NOT NULL,
	[PatientIdFK] [uniqueidentifier] NOT NULL,
	[Condition] [varchar](250) NOT NULL,
	[DiagnosisDate] [datetime] NOT NULL,
	[DiagnosingDoctor] [varchar](250) NULL,
	[Status] [varchar](50) NOT NULL DEFAULT 'Active', -- Active, Resolved, Chronic
	[Description] [varchar](MAX) NULL,
	[ICD10Code] [varchar](10) NULL, -- International disease classification code
	[IsActive] [bit] NOT NULL DEFAULT 1,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[MedicalHistoryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

IF OBJECT_ID(N'[Profile].[MedicalHistory]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[MedicalHistory]')
      AND c.name = N'MedicalHistoryId'
)
BEGIN
ALTER TABLE [Profile].[MedicalHistory] ADD DEFAULT (newid()) FOR [MedicalHistoryId]
END
GO

IF OBJECT_ID(N'[Profile].[MedicalHistory]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[MedicalHistory]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[MedicalHistory]'), N'PatientIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[Patient]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Patient]'), N'PatientId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[MedicalHistory] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
REFERENCES [Profile].[Patient] ([PatientId])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[MedicalHistory]') AND name = 'IX_MedicalHistory_PatientIdFK')
BEGIN
CREATE INDEX IX_MedicalHistory_PatientIdFK ON [Profile].[MedicalHistory]([PatientIdFK])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[MedicalHistory]') AND name = 'IX_MedicalHistory_Status')
BEGIN
CREATE INDEX IX_MedicalHistory_Status ON [Profile].[MedicalHistory]([Status])
END
GO
