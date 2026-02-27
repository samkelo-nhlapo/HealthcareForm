USE HealthcareForm
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Lookup')
BEGIN
    EXEC('CREATE SCHEMA Lookup');
END
GO

IF OBJECT_ID(N'[Lookup].[Medications]', N'U') IS NULL
BEGIN
    CREATE TABLE [Lookup].[Medications]
    (
        [MedicationId] [uniqueidentifier] NOT NULL DEFAULT NEWID(),
        [MedicationName] [varchar](250) NOT NULL,
        [MedicationGenericName] [varchar](250) NULL,
        [MedicationCategory] [varchar](100) NULL,
        [Strength] [varchar](50) NULL,
        [Unit] [varchar](50) NULL,
        [RouteOfAdministration] [varchar](50) NULL,
        [ManufacturerName] [varchar](250) NULL,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        [CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
        [CreatedBy] [varchar](250) NULL,
        CONSTRAINT PK_LookupMedications PRIMARY KEY ([MedicationId])
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Lookup].[Medications]') AND name = N'IX_LookupMedications_MedicationName')
BEGIN
    CREATE INDEX IX_LookupMedications_MedicationName ON [Lookup].[Medications]([MedicationName]);
END
GO
