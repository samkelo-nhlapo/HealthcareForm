-- 008-index-templates.sql
-- Idempotent index creation for commonly queried columns / FK columns.

-- Auth.Users: username and email (will skip if already exist)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Users_Username' AND object_id = OBJECT_ID('Auth.Users'))
BEGIN
    CREATE INDEX IX_Users_Username ON [Auth].[Users](Username);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Users_Email' AND object_id = OBJECT_ID('Auth.Users'))
BEGIN
    CREATE INDEX IX_Users_Email ON [Auth].[Users](Email);
END
GO

-- Contacts: patient lookup indexes
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_PatientPhones_PatientIdFK' AND object_id = OBJECT_ID('Contacts.PatientPhones'))
BEGIN
    CREATE INDEX IX_PatientPhones_PatientIdFK ON [Contacts].[PatientPhones](PatientIdFK);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_PatientEmails_PatientIdFK' AND object_id = OBJECT_ID('Contacts.PatientEmails'))
BEGIN
    CREATE INDEX IX_PatientEmails_PatientIdFK ON [Contacts].[PatientEmails](PatientIdFK);
END
GO

-- Appointments and consultation notes
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Appointments_PatientIdFK' AND object_id = OBJECT_ID('Profile.Appointments'))
BEGIN
    CREATE INDEX IX_Appointments_PatientIdFK ON [Profile].[Appointments](PatientIdFK);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Appointments_ProviderIdFK' AND object_id = OBJECT_ID('Profile.Appointments'))
BEGIN
    CREATE INDEX IX_Appointments_ProviderIdFK ON [Profile].[Appointments](ProviderIdFK);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_ConsultNotes_PatientIdFK' AND object_id = OBJECT_ID('Profile.ConsultationNotes'))
BEGIN
    CREATE INDEX IX_ConsultNotes_PatientIdFK ON [Profile].[ConsultationNotes](PatientIdFK);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_ConsultNotes_ProviderIdFK' AND object_id = OBJECT_ID('Profile.ConsultationNotes'))
BEGIN
    CREATE INDEX IX_ConsultNotes_ProviderIdFK ON [Profile].[ConsultationNotes](ProviderIdFK);
END
GO

-- PatientInsurance
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_PatientInsurance_InsuranceProviderIdFK' AND object_id = OBJECT_ID('Profile.PatientInsurance'))
BEGIN
    CREATE INDEX IX_PatientInsurance_InsuranceProviderIdFK ON [Profile].[PatientInsurance](InsuranceProviderIdFK);
END
GO

-- Add more index suggestions as you profile queries.
