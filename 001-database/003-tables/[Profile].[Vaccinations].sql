USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Vaccination and immunization records for patient preventive care
--	TFS Task:		Healthcare form - vaccination tracking
--================================================================================================

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[Profile].[Vaccinations]', N'U') IS NULL
BEGIN
CREATE TABLE [Profile].[Vaccinations](
	[VaccinationId] [uniqueidentifier] NOT NULL,
	[PatientIdFK] [uniqueidentifier] NOT NULL,
	[VaccineName] [varchar](250) NOT NULL,
	[VaccineCode] [varchar](50) NULL, -- CDC vaccine code
	[AdministrationDate] [datetime] NOT NULL,
	[DueDate] [datetime] NULL, -- Next booster due date
	[AdministeredBy] [varchar](250) NOT NULL,
	[Lot] [varchar](100) NULL, -- Vaccine lot number
	[Site] [varchar](100) NOT NULL DEFAULT 'Left Arm', -- Body site
	[Route] [varchar](50) NOT NULL DEFAULT 'Intramuscular',
	[Reaction] [varchar](MAX) NULL, -- Any adverse reactions
	[Status] [varchar](50) NOT NULL DEFAULT 'Completed', -- Completed, Pending, Contraindicated
	[Notes] [varchar](MAX) NULL,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[VaccinationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

IF OBJECT_ID(N'[Profile].[Vaccinations]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[Vaccinations]')
      AND c.name = N'VaccinationId'
)
BEGIN
ALTER TABLE [Profile].[Vaccinations] ADD DEFAULT (newid()) FOR [VaccinationId]
END
GO

IF OBJECT_ID(N'[Profile].[Vaccinations]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[Vaccinations]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Vaccinations]'), N'PatientIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[Patient]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Patient]'), N'PatientId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[Vaccinations] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
REFERENCES [Profile].[Patient] ([PatientId])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Vaccinations]') AND name = 'IX_Vaccinations_PatientIdFK')
BEGIN
CREATE INDEX IX_Vaccinations_PatientIdFK ON [Profile].[Vaccinations]([PatientIdFK])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Vaccinations]') AND name = 'IX_Vaccinations_DueDate')
BEGIN
CREATE INDEX IX_Vaccinations_DueDate ON [Profile].[Vaccinations]([DueDate])
END
GO
