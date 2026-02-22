USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Healthcare providers/doctors information and credentials
--	TFS Task:		Healthcare form - provider management
--================================================================================================

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Profile].[HealthcareProviders](
	[ProviderId] [uniqueidentifier] NOT NULL,
	[FirstName] [varchar](250) NOT NULL,
	[LastName] [varchar](250) NOT NULL,
	[Title] [varchar](50) NULL, -- Dr., Prof., Mr., etc.
	[Specialization] [varchar](250) NOT NULL, -- Cardiology, Pediatrics, etc.
	[LicenseNumber] [varchar](100) NOT NULL UNIQUE,
	[RegistrationBody] [varchar](250) NOT NULL, -- Medical Council, etc.
	[ProviderType] [varchar](50) NOT NULL, -- Doctor, Nurse, Therapist, Specialist
	[Qualifications] [varchar](MAX) NULL, -- Degrees, certifications
	[YearsOfExperience] [int] NULL,
	[OfficeAddressIdFK] [uniqueidentifier] NULL,
	[IsActive] [bit] NOT NULL DEFAULT 1,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[ProviderId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [Profile].[HealthcareProviders] ADD DEFAULT (newid()) FOR [ProviderId]
GO

ALTER TABLE [Profile].[HealthcareProviders] WITH CHECK ADD FOREIGN KEY([OfficeAddressIdFK])
REFERENCES [Location].[Address] ([AddressId])
GO

CREATE INDEX IX_HealthcareProviders_Specialization ON [Profile].[HealthcareProviders]([Specialization])
GO

CREATE INDEX IX_HealthcareProviders_LicenseNumber ON [Profile].[HealthcareProviders]([LicenseNumber])
GO
