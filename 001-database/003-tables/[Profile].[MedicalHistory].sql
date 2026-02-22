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
GO

ALTER TABLE [Profile].[MedicalHistory] ADD DEFAULT (newid()) FOR [MedicalHistoryId]
GO

ALTER TABLE [Profile].[MedicalHistory] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
REFERENCES [Profile].[Patient] ([PatientId])
GO

CREATE INDEX IX_MedicalHistory_PatientIdFK ON [Profile].[MedicalHistory]([PatientIdFK])
GO

CREATE INDEX IX_MedicalHistory_Status ON [Profile].[MedicalHistory]([Status])
GO
