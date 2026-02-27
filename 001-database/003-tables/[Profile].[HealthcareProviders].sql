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

IF OBJECT_ID(N'[Profile].[HealthcareProviders]', N'U') IS NULL
BEGIN
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
END
GO

IF OBJECT_ID(N'[Profile].[HealthcareProviders]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[HealthcareProviders]')
      AND c.name = N'ProviderId'
)
BEGIN
ALTER TABLE [Profile].[HealthcareProviders] ADD DEFAULT (newid()) FOR [ProviderId]
END
GO

IF OBJECT_ID(N'[Profile].[HealthcareProviders]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Location].[Address]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[HealthcareProviders]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[HealthcareProviders]'), N'OfficeAddressIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Location].[Address]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Location].[Address]'), N'AddressId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[HealthcareProviders] WITH CHECK ADD FOREIGN KEY([OfficeAddressIdFK])
REFERENCES [Location].[Address] ([AddressId])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[HealthcareProviders]') AND name = 'IX_HealthcareProviders_Specialization')
BEGIN
CREATE INDEX IX_HealthcareProviders_Specialization ON [Profile].[HealthcareProviders]([Specialization])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[HealthcareProviders]') AND name = 'IX_HealthcareProviders_LicenseNumber')
BEGIN
CREATE INDEX IX_HealthcareProviders_LicenseNumber ON [Profile].[HealthcareProviders]([LicenseNumber])
END
GO
