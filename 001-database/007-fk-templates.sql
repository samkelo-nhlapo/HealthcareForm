-- 007-fk-templates.sql
-- Idempotent FK templates to run after tables are created.
-- Run this file after DDL creation if some FKs were skipped due to ordering.

-- Profile: Patient and related tables
IF OBJECT_ID('FK_Allergies_Patient','F') IS NULL
BEGIN
    ALTER TABLE [Profile].[Allergies] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
    REFERENCES [Profile].[Patient] ([PatientId])
END
GO

IF OBJECT_ID('FK_Medications_Patient','F') IS NULL
BEGIN
    ALTER TABLE [Profile].[Medications] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
    REFERENCES [Profile].[Patient] ([PatientId])
END
GO

IF OBJECT_ID('FK_ConsultationNotes_Patient','F') IS NULL
BEGIN
    ALTER TABLE [Profile].[ConsultationNotes] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
    REFERENCES [Profile].[Patient] ([PatientId])
END
GO

IF OBJECT_ID('FK_ConsultationNotes_Provider','F') IS NULL
BEGIN
    ALTER TABLE [Profile].[ConsultationNotes] WITH CHECK ADD FOREIGN KEY([ProviderIdFK])
    REFERENCES [Profile].[HealthcareProviders] ([ProviderId])
END
GO

IF OBJECT_ID('FK_Appointments_Patient','F') IS NULL
BEGIN
    ALTER TABLE [Profile].[Appointments] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
    REFERENCES [Profile].[Patient] ([PatientId])
END
GO

IF OBJECT_ID('FK_Appointments_Provider','F') IS NULL
BEGIN
    ALTER TABLE [Profile].[Appointments] WITH CHECK ADD FOREIGN KEY([ProviderIdFK])
    REFERENCES [Profile].[HealthcareProviders] ([ProviderId])
END
GO

IF OBJECT_ID('FK_PatientInsurance_InsuranceProvider','F') IS NULL
BEGIN
    ALTER TABLE [Profile].[PatientInsurance] WITH CHECK ADD FOREIGN KEY([InsuranceProviderIdFK])
    REFERENCES [Profile].[InsuranceProviders] ([InsuranceProviderId])
END
GO

-- Contacts -> Patient
IF OBJECT_ID('FK_PatientPhones_Patient','F') IS NULL
BEGIN
    ALTER TABLE [Contacts].[PatientPhones] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
    REFERENCES [Profile].[Patient] ([PatientId])
END
GO

IF OBJECT_ID('FK_PatientEmails_Patient','F') IS NULL
BEGIN
    ALTER TABLE [Contacts].[PatientEmails] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
    REFERENCES [Profile].[Patient] ([PatientId])
END
GO

-- Add any additional FK statements here as required by your environment.
