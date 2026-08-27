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
	[ClientIdFK] [uniqueidentifier] NOT NULL,
	[ClientProviderAffiliationIdFK] [uniqueidentifier] NOT NULL,
	[ClientStaffIdFK] [uniqueidentifier] NULL,
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
AND COL_LENGTH(N'[Profile].[Appointments]', N'ClientIdFK') IS NULL
BEGIN
ALTER TABLE [Profile].[Appointments] ADD [ClientIdFK] [uniqueidentifier] NULL
END
GO

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND COL_LENGTH(N'[Profile].[Appointments]', N'ClientStaffIdFK') IS NULL
BEGIN
ALTER TABLE [Profile].[Appointments] ADD [ClientStaffIdFK] [uniqueidentifier] NULL
END
GO

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND COL_LENGTH(N'[Profile].[Appointments]', N'ClientProviderAffiliationIdFK') IS NULL
BEGIN
ALTER TABLE [Profile].[Appointments] ADD [ClientProviderAffiliationIdFK] [uniqueidentifier] NULL
END
GO

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND COL_LENGTH(N'[Profile].[Appointments]', N'ClientStaffIdFK') IS NOT NULL
AND EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[Profile].[Appointments]')
      AND name = N'ClientStaffIdFK'
      AND is_nullable = 0
)
BEGIN
ALTER TABLE [Profile].[Appointments] ALTER COLUMN [ClientStaffIdFK] [uniqueidentifier] NULL
END
GO

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND COL_LENGTH(N'[Profile].[Appointments]', N'ClientProviderAffiliationIdFK') IS NOT NULL
AND EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[Profile].[Appointments]')
      AND name = N'ClientProviderAffiliationIdFK'
      AND is_nullable = 1
)
AND NOT EXISTS (
    SELECT 1
    FROM [Profile].[Appointments]
    WHERE [ClientProviderAffiliationIdFK] IS NULL
)
BEGIN
ALTER TABLE [Profile].[Appointments] ALTER COLUMN [ClientProviderAffiliationIdFK] [uniqueidentifier] NOT NULL
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

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[Clients]', N'U') IS NOT NULL
AND COL_LENGTH(N'[Profile].[Appointments]', N'ClientIdFK') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[Appointments]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Appointments]'), N'ClientIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[Clients]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Clients]'), N'ClientId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[Appointments] WITH CHECK ADD FOREIGN KEY([ClientIdFK])
REFERENCES [Profile].[Clients] ([ClientId])
END
GO

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
AND COL_LENGTH(N'[Profile].[Appointments]', N'ClientStaffIdFK') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[Appointments]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Appointments]'), N'ClientStaffIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[ClientStaff]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[ClientStaff]'), N'ClientStaffId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[Appointments] WITH CHECK ADD FOREIGN KEY([ClientStaffIdFK])
REFERENCES [Profile].[ClientStaff] ([ClientStaffId])
END
GO

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[ClientProviderAffiliations]', N'U') IS NOT NULL
AND COL_LENGTH(N'[Profile].[Appointments]', N'ClientProviderAffiliationIdFK') IS NOT NULL
AND COL_LENGTH(N'[Profile].[Appointments]', N'ClientIdFK') IS NOT NULL
AND COL_LENGTH(N'[Profile].[Appointments]', N'ProviderIdFK') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = N'FK_Appointments_ClientProviderAffiliations_Id_Client_Provider'
)
BEGIN
ALTER TABLE [Profile].[Appointments] WITH CHECK
ADD CONSTRAINT [FK_Appointments_ClientProviderAffiliations_Id_Client_Provider]
FOREIGN KEY([ClientProviderAffiliationIdFK], [ClientIdFK], [ProviderIdFK])
REFERENCES [Profile].[ClientProviderAffiliations] ([ClientProviderAffiliationId], [ClientIdFK], [ProviderIdFK])
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

IF COL_LENGTH(N'[Profile].[Appointments]', N'ClientStaffIdFK') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Appointments]') AND name = 'IX_Appointments_ClientStaffIdFK')
BEGIN
CREATE INDEX IX_Appointments_ClientStaffIdFK ON [Profile].[Appointments]([ClientStaffIdFK])
END
GO

IF COL_LENGTH(N'[Profile].[Appointments]', N'ClientProviderAffiliationIdFK') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Appointments]') AND name = 'IX_Appointments_ClientProviderAffiliationIdFK')
BEGIN
CREATE INDEX IX_Appointments_ClientProviderAffiliationIdFK ON [Profile].[Appointments]([ClientProviderAffiliationIdFK])
END
GO

IF COL_LENGTH(N'[Profile].[Appointments]', N'ClientIdFK') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Appointments]') AND name = 'IX_Appointments_ClientIdFK_AppointmentDateTime')
BEGIN
CREATE INDEX IX_Appointments_ClientIdFK_AppointmentDateTime ON [Profile].[Appointments]([ClientIdFK], [AppointmentDateTime])
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
