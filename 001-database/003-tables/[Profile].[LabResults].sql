USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Laboratory and diagnostic test results for patient health monitoring
--	TFS Task:		Healthcare form - lab results capture
--================================================================================================

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[Profile].[LabResults]', N'U') IS NULL
BEGIN
CREATE TABLE [Profile].[LabResults](
	[LabResultId] [uniqueidentifier] NOT NULL,
	[PatientIdFK] [uniqueidentifier] NOT NULL,
	[TestName] [varchar](250) NOT NULL, -- e.g., "Complete Blood Count", "Cholesterol Panel"
	[TestCode] [varchar](50) NULL, -- Lab test code
	[SpecimenType] [varchar](100) NULL, -- Blood, Urine, Tissue, etc.
	[CollectionDate] [datetime] NOT NULL,
	[ResultDate] [datetime] NOT NULL,
	[ResultValue] [varchar](250) NOT NULL,
	[Unit] [varchar](50) NULL, -- mg/dL, mg/L, etc.
	[ReferenceRange] [varchar](250) NULL, -- Normal range
	[Status] [varchar](50) NOT NULL DEFAULT 'Normal', -- Normal, Abnormal, Critical, Pending
	[OrderedBy] [varchar](250) NOT NULL,
	[Lab] [varchar](250) NULL, -- Lab name/facility
	[Interpretation] [varchar](MAX) NULL, -- Doctor interpretation
	[Notes] [varchar](MAX) NULL,
	[FileAttachmentId] [uniqueidentifier] NULL, -- Link to actual test file/scan
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[LabResultId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

IF OBJECT_ID(N'[Profile].[LabResults]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[LabResults]')
      AND c.name = N'LabResultId'
)
BEGIN
ALTER TABLE [Profile].[LabResults] ADD DEFAULT (newid()) FOR [LabResultId]
END
GO

IF OBJECT_ID(N'[Profile].[LabResults]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[LabResults]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[LabResults]'), N'PatientIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[Patient]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Patient]'), N'PatientId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[LabResults] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
REFERENCES [Profile].[Patient] ([PatientId])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[LabResults]') AND name = 'IX_LabResults_PatientIdFK')
BEGIN
CREATE INDEX IX_LabResults_PatientIdFK ON [Profile].[LabResults]([PatientIdFK])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[LabResults]') AND name = 'IX_LabResults_ResultDate')
BEGIN
CREATE INDEX IX_LabResults_ResultDate ON [Profile].[LabResults]([ResultDate])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[LabResults]') AND name = 'IX_LabResults_Status')
BEGIN
CREATE INDEX IX_LabResults_Status ON [Profile].[LabResults]([Status])
END
GO
