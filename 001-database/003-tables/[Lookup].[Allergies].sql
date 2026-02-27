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

IF OBJECT_ID(N'[Lookup].[Allergies]', N'U') IS NULL
BEGIN
    CREATE TABLE [Lookup].[Allergies]
    (
        [AllergyId] [uniqueidentifier] NOT NULL DEFAULT NEWID(),
        [AllergyName] [varchar](250) NOT NULL,
        [AllergyCategory] [varchar](50) NOT NULL,
        [Severity] [varchar](50) NOT NULL,
        [ReactionDescription] [varchar](MAX) NULL,
        [IsCritical] [bit] NOT NULL DEFAULT 0,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        [CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
        [CreatedBy] [varchar](250) NULL,
        CONSTRAINT PK_LookupAllergies PRIMARY KEY ([AllergyId])
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Lookup].[Allergies]') AND name = N'IX_LookupAllergies_AllergyName')
BEGIN
    CREATE INDEX IX_LookupAllergies_AllergyName ON [Lookup].[Allergies]([AllergyName]);
END
GO
