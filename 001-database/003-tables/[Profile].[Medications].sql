USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Current and historical medication records for patient prescriptions
--	TFS Task:		Healthcare form - medication tracking
--================================================================================================

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[Profile].[Medications]', N'U') IS NULL
BEGIN
CREATE TABLE [Profile].[Medications](
	[MedicationId] [uniqueidentifier] NOT NULL,
	[PatientIdFK] [uniqueidentifier] NOT NULL,
	[MedicationName] [varchar](250) NOT NULL,
	[Dosage] [varchar](100) NOT NULL, -- e.g., "500mg", "10 units"
	[Frequency] [varchar](100) NOT NULL, -- e.g., "Twice daily", "Every 8 hours"
	[Route] [varchar](50) NOT NULL DEFAULT 'Oral', -- Oral, IV, Topical, Injection, etc.
	[Indication] [varchar](250) NULL, -- Reason for medication (condition it treats)
	[PrescribedBy] [varchar](250) NULL, -- Doctor name
	[PrescriptionDate] [datetime] NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[Status] [varchar](50) NOT NULL DEFAULT 'Active', -- Active, Discontinued, Suspended
	[SideEffects] [varchar](MAX) NULL,
	[Notes] [varchar](MAX) NULL,
	[IsActive] [bit] NOT NULL DEFAULT 1,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[MedicationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

IF OBJECT_ID(N'[Profile].[Medications]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[Medications]')
      AND c.name = N'MedicationId'
)
BEGIN
ALTER TABLE [Profile].[Medications] ADD DEFAULT (newid()) FOR [MedicationId]
END
GO

IF OBJECT_ID(N'[Profile].[Medications]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[Medications]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Medications]'), N'PatientIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[Patient]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Patient]'), N'PatientId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[Medications] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
REFERENCES [Profile].[Patient] ([PatientId])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Medications]') AND name = 'IX_Medications_PatientIdFK')
BEGIN
CREATE INDEX IX_Medications_PatientIdFK ON [Profile].[Medications]([PatientIdFK])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Medications]') AND name = 'IX_Medications_Status')
BEGIN
CREATE INDEX IX_Medications_Status ON [Profile].[Medications]([Status])
END
GO
