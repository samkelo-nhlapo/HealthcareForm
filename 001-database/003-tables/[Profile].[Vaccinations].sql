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
GO

ALTER TABLE [Profile].[Vaccinations] ADD DEFAULT (newid()) FOR [VaccinationId]
GO

ALTER TABLE [Profile].[Vaccinations] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
REFERENCES [Profile].[Patient] ([PatientId])
GO

CREATE INDEX IX_Vaccinations_PatientIdFK ON [Profile].[Vaccinations]([PatientIdFK])
GO

CREATE INDEX IX_Vaccinations_DueDate ON [Profile].[Vaccinations]([DueDate])
GO
