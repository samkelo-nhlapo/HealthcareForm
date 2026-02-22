USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Patient appointment scheduling and management
--	TFS Task:		Healthcare form - appointment scheduling
--================================================================================================

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Profile].[Appointments](
	[AppointmentId] [uniqueidentifier] NOT NULL,
	[PatientIdFK] [uniqueidentifier] NOT NULL,
	[ProviderIdFK] [uniqueidentifier] NOT NULL,
	[AppointmentDateTime] [datetime] NOT NULL,
	[DurationMinutes] [int] NOT NULL DEFAULT 30,
	[AppointmentType] [varchar](100) NOT NULL, -- Consultation, Follow-up, Check-up, Procedure
	[Reason] [varchar](MAX) NOT NULL,
	[Location] [varchar](250) NULL,
	[Status] [varchar](50) NOT NULL DEFAULT 'Scheduled', -- Scheduled, In Progress, Completed, Cancelled, No-show, Rescheduled
	[CancellationReason] [varchar](MAX) NULL,
	[CancelledBy] [varchar](250) NULL,
	[CancelledDate] [datetime] NULL,
	[Reminders] [varchar](MAX) NULL, -- JSON array of reminder preferences
	[Notes] [varchar](MAX) NULL,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[AppointmentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [Profile].[Appointments] ADD DEFAULT (newid()) FOR [AppointmentId]
GO

ALTER TABLE [Profile].[Appointments] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
REFERENCES [Profile].[Patient] ([PatientId])
GO

ALTER TABLE [Profile].[Appointments] WITH CHECK ADD FOREIGN KEY([ProviderIdFK])
REFERENCES [Profile].[HealthcareProviders] ([ProviderId])
GO

CREATE INDEX IX_Appointments_PatientIdFK ON [Profile].[Appointments]([PatientIdFK])
GO

CREATE INDEX IX_Appointments_ProviderIdFK ON [Profile].[Appointments]([ProviderIdFK])
GO

CREATE INDEX IX_Appointments_AppointmentDateTime ON [Profile].[Appointments]([AppointmentDateTime])
GO

CREATE INDEX IX_Appointments_Status ON [Profile].[Appointments]([Status])
GO
