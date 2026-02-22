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
GO

ALTER TABLE [Profile].[ConsultationNotes] ADD DEFAULT (newid()) FOR [ConsultationNoteId]
GO

ALTER TABLE [Profile].[ConsultationNotes] WITH CHECK ADD FOREIGN KEY([AppointmentIdFK])
REFERENCES [Profile].[Appointments] ([AppointmentId])
GO

ALTER TABLE [Profile].[ConsultationNotes] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
REFERENCES [Profile].[Patient] ([PatientId])
GO

ALTER TABLE [Profile].[ConsultationNotes] WITH CHECK ADD FOREIGN KEY([ProviderIdFK])
REFERENCES [Profile].[HealthcareProviders] ([ProviderId])
GO

CREATE INDEX IX_ConsultationNotes_PatientIdFK ON [Profile].[ConsultationNotes]([PatientIdFK])
GO

CREATE INDEX IX_ConsultationNotes_ProviderIdFK ON [Profile].[ConsultationNotes]([ProviderIdFK])
GO

CREATE INDEX IX_ConsultationNotes_ConsultationDate ON [Profile].[ConsultationNotes]([ConsultationDate])
GO
