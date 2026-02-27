USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Doctor consultation notes, diagnosis, and treatment plans
--	TFS Task:		Healthcare form - consultation documentation
--================================================================================================

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[Profile].[ConsultationNotes]', N'U') IS NULL
BEGIN
CREATE TABLE [Profile].[ConsultationNotes](
	[ConsultationNoteId] [uniqueidentifier] NOT NULL,
	[AppointmentIdFK] [uniqueidentifier] NOT NULL,
	[PatientIdFK] [uniqueidentifier] NOT NULL,
	[ProviderIdFK] [uniqueidentifier] NOT NULL,
	[ConsultationDate] [datetime] NOT NULL,
	[ChiefComplaint] [varchar](MAX) NOT NULL,
	[PresentingSymptoms] [varchar](MAX) NULL,
	[History] [varchar](MAX) NULL, -- Patient history
	[PhysicalExamination] [varchar](MAX) NULL,
	[Diagnosis] [varchar](MAX) NOT NULL,
	[DiagnosisCodes] [varchar](MAX) NULL, -- ICD-10 codes, comma separated
	[TreatmentPlan] [varchar](MAX) NOT NULL,
	[Medications] [varchar](MAX) NULL, -- Prescribed medications
	[Procedures] [varchar](MAX) NULL, -- Any procedures ordered
	[FollowUpDate] [datetime] NULL,
	[ReferralNeeded] [bit] NOT NULL DEFAULT 0,
	[ReferralReason] [varchar](MAX) NULL,
	[Restrictions] [varchar](MAX) NULL, -- Activity restrictions
	[Notes] [varchar](MAX) NULL,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[ConsultationNoteId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

IF OBJECT_ID(N'[Profile].[ConsultationNotes]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[ConsultationNotes]')
      AND c.name = N'ConsultationNoteId'
)
BEGIN
ALTER TABLE [Profile].[ConsultationNotes] ADD DEFAULT (newid()) FOR [ConsultationNoteId]
END
GO

IF OBJECT_ID(N'[Profile].[ConsultationNotes]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[ConsultationNotes]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[ConsultationNotes]'), N'AppointmentIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[Appointments]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Appointments]'), N'AppointmentId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[ConsultationNotes] WITH CHECK ADD FOREIGN KEY([AppointmentIdFK])
REFERENCES [Profile].[Appointments] ([AppointmentId])
END
GO

IF OBJECT_ID(N'[Profile].[ConsultationNotes]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[ConsultationNotes]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[ConsultationNotes]'), N'PatientIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[Patient]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Patient]'), N'PatientId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[ConsultationNotes] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
REFERENCES [Profile].[Patient] ([PatientId])
END
GO

IF OBJECT_ID(N'[Profile].[ConsultationNotes]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[HealthcareProviders]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[ConsultationNotes]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[ConsultationNotes]'), N'ProviderIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[HealthcareProviders]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[HealthcareProviders]'), N'ProviderId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[ConsultationNotes] WITH CHECK ADD FOREIGN KEY([ProviderIdFK])
REFERENCES [Profile].[HealthcareProviders] ([ProviderId])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ConsultationNotes]') AND name = 'IX_ConsultationNotes_PatientIdFK')
BEGIN
CREATE INDEX IX_ConsultationNotes_PatientIdFK ON [Profile].[ConsultationNotes]([PatientIdFK])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ConsultationNotes]') AND name = 'IX_ConsultationNotes_ProviderIdFK')
BEGIN
CREATE INDEX IX_ConsultationNotes_ProviderIdFK ON [Profile].[ConsultationNotes]([ProviderIdFK])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ConsultationNotes]') AND name = 'IX_ConsultationNotes_ConsultationDate')
BEGIN
CREATE INDEX IX_ConsultationNotes_ConsultationDate ON [Profile].[ConsultationNotes]([ConsultationDate])
END
GO
