USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Patient allergies tracking including drug, food, and environmental allergies
--	TFS Task:		Healthcare form - allergy capture
--================================================================================================

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Profile].[Allergies](
	[AllergyId] [uniqueidentifier] NOT NULL,
	[PatientIdFK] [uniqueidentifier] NOT NULL,
	[AllergyType] [varchar](50) NOT NULL, -- Drug, Food, Environmental, Other
	[AllergenName] [varchar](250) NOT NULL,
	[Reaction] [varchar](MAX) NOT NULL, -- Description of allergic reaction
	[Severity] [varchar](50) NOT NULL DEFAULT 'Moderate', -- Mild, Moderate, Severe, Life-threatening
	[ReactionOnsetDate] [datetime] NULL,
	[VerifiedBy] [varchar](250) NULL, -- Doctor who verified
	[IsActive] [bit] NOT NULL DEFAULT 1,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[AllergyId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [Profile].[Allergies] ADD DEFAULT (newid()) FOR [AllergyId]
GO

ALTER TABLE [Profile].[Allergies] WITH CHECK ADD FOREIGN KEY([PatientIdFK])
REFERENCES [Profile].[Patient] ([PatientId])
GO

CREATE INDEX IX_Allergies_PatientIdFK ON [Profile].[Allergies]([PatientIdFK])
GO

CREATE INDEX IX_Allergies_AllergyType ON [Profile].[Allergies]([AllergyType])
GO

CREATE INDEX IX_Allergies_Severity ON [Profile].[Allergies]([Severity])
GO
