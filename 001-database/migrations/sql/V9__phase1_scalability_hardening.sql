-- Phase 1 scalability hardening
-- Adds tenant-ready keys and idempotent constraints/indexes for core workflows.

USE HealthcareForm;
GO

IF OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH('Profile.Patient', 'ClientIdFK') IS NULL
        ALTER TABLE [Profile].[Patient] ADD [ClientIdFK] UNIQUEIDENTIFIER NULL;
END
GO

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH('Profile.Appointments', 'ClientIdFK') IS NULL
        ALTER TABLE [Profile].[Appointments] ADD [ClientIdFK] UNIQUEIDENTIFIER NULL;
END
GO

IF OBJECT_ID(N'[Profile].[ConsultationNotes]', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH('Profile.ConsultationNotes', 'ClientIdFK') IS NULL
        ALTER TABLE [Profile].[ConsultationNotes] ADD [ClientIdFK] UNIQUEIDENTIFIER NULL;
END
GO

IF OBJECT_ID(N'[Contacts].[FormSubmissions]', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH('Contacts.FormSubmissions', 'ClientIdFK') IS NULL
        ALTER TABLE [Contacts].[FormSubmissions] ADD [ClientIdFK] UNIQUEIDENTIFIER NULL;
END
GO

IF OBJECT_ID(N'[Profile].[Invoices]', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH('Profile.Invoices', 'ClientIdFK') IS NULL
        ALTER TABLE [Profile].[Invoices] ADD [ClientIdFK] UNIQUEIDENTIFIER NULL;
END
GO

IF OBJECT_ID(N'[Profile].[Clients]', N'U') IS NOT NULL AND OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Patient_Client')
BEGIN
    ALTER TABLE [Profile].[Patient] WITH CHECK
    ADD CONSTRAINT [FK_Patient_Client] FOREIGN KEY([ClientIdFK]) REFERENCES [Profile].[Clients]([ClientId]);
END
GO

IF OBJECT_ID(N'[Profile].[Clients]', N'U') IS NOT NULL AND OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Appointments_Client')
BEGIN
    ALTER TABLE [Profile].[Appointments] WITH CHECK
    ADD CONSTRAINT [FK_Appointments_Client] FOREIGN KEY([ClientIdFK]) REFERENCES [Profile].[Clients]([ClientId]);
END
GO

IF OBJECT_ID(N'[Profile].[Clients]', N'U') IS NOT NULL AND OBJECT_ID(N'[Profile].[ConsultationNotes]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ConsultationNotes_Client')
BEGIN
    ALTER TABLE [Profile].[ConsultationNotes] WITH CHECK
    ADD CONSTRAINT [FK_ConsultationNotes_Client] FOREIGN KEY([ClientIdFK]) REFERENCES [Profile].[Clients]([ClientId]);
END
GO

IF OBJECT_ID(N'[Profile].[Clients]', N'U') IS NOT NULL AND OBJECT_ID(N'[Contacts].[FormSubmissions]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_FormSubmissions_Client')
BEGIN
    ALTER TABLE [Contacts].[FormSubmissions] WITH CHECK
    ADD CONSTRAINT [FK_FormSubmissions_Client] FOREIGN KEY([ClientIdFK]) REFERENCES [Profile].[Clients]([ClientId]);
END
GO

IF OBJECT_ID(N'[Profile].[Clients]', N'U') IS NOT NULL AND OBJECT_ID(N'[Profile].[Invoices]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Invoices_Client')
BEGIN
    ALTER TABLE [Profile].[Invoices] WITH CHECK
    ADD CONSTRAINT [FK_Invoices_Client] FOREIGN KEY([ClientIdFK]) REFERENCES [Profile].[Clients]([ClientId]);
END
GO

IF OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Patient]') AND name = 'IX_Patient_ClientIdFK')
    CREATE INDEX IX_Patient_ClientIdFK ON [Profile].[Patient]([ClientIdFK]);
GO

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Appointments]') AND name = 'IX_Appointments_ClientIdFK_AppointmentDateTime')
    CREATE INDEX IX_Appointments_ClientIdFK_AppointmentDateTime ON [Profile].[Appointments]([ClientIdFK], [AppointmentDateTime]);
GO

IF OBJECT_ID(N'[Profile].[ConsultationNotes]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ConsultationNotes]') AND name = 'IX_ConsultationNotes_ClientIdFK')
    CREATE INDEX IX_ConsultationNotes_ClientIdFK ON [Profile].[ConsultationNotes]([ClientIdFK]);
GO

IF OBJECT_ID(N'[Contacts].[FormSubmissions]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Contacts].[FormSubmissions]') AND name = 'IX_FormSubmissions_ClientIdFK')
    CREATE INDEX IX_FormSubmissions_ClientIdFK ON [Contacts].[FormSubmissions]([ClientIdFK]);
GO

IF OBJECT_ID(N'[Profile].[Invoices]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Invoices]') AND name = 'IX_Invoices_ClientIdFK')
    CREATE INDEX IX_Invoices_ClientIdFK ON [Profile].[Invoices]([ClientIdFK]);
GO
