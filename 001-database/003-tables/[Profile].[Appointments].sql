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

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NULL
BEGIN
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
END
GO

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[Appointments]')
      AND c.name = N'AppointmentId'
)
BEGIN
ALTER TABLE [Profile].[Appointments] ADD DEFAULT (newid()) FOR [AppointmentId]
END
GO

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[Appointments]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Appointments]'), N'PatientIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[Patient]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Patient]'), N'PatientId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[Appointments] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
REFERENCES [Profile].[Patient] ([PatientId])
END
GO

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[HealthcareProviders]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[Appointments]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Appointments]'), N'ProviderIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[HealthcareProviders]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[HealthcareProviders]'), N'ProviderId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[Appointments] WITH CHECK ADD FOREIGN KEY([ProviderIdFK])
REFERENCES [Profile].[HealthcareProviders] ([ProviderId])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Appointments]') AND name = 'IX_Appointments_PatientIdFK')
BEGIN
CREATE INDEX IX_Appointments_PatientIdFK ON [Profile].[Appointments]([PatientIdFK])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Appointments]') AND name = 'IX_Appointments_ProviderIdFK')
BEGIN
CREATE INDEX IX_Appointments_ProviderIdFK ON [Profile].[Appointments]([ProviderIdFK])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Appointments]') AND name = 'IX_Appointments_AppointmentDateTime')
BEGIN
CREATE INDEX IX_Appointments_AppointmentDateTime ON [Profile].[Appointments]([AppointmentDateTime])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Appointments]') AND name = 'IX_Appointments_Status')
BEGIN
CREATE INDEX IX_Appointments_Status ON [Profile].[Appointments]([Status])
END
GO
