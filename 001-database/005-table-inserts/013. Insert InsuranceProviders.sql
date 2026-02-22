USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Insert insurance provider reference data
--	TFS Task:		Initialize insurance providers
--================================================================================================

DECLARE @DefaultDate DATETIME = GETDATE(),
		@CountryId INT = (SELECT CountryId FROM Location.Countries WHERE CountryCode = 'ZA')

INSERT INTO HealthcareServices.InsuranceProviders (ProviderName, ContactPhone, ContactEmail, SupportedByCountryIdFK, IsActive, CreatedDate, CreatedBy)
VALUES	
	('Discovery Health', '+27 11 799 8000', 'inquiry@discovery.co.za', @CountryId, 1, @DefaultDate, 'SYSTEM'),
	('Momentum Health Solutions', '+27 11 408 6600', 'support@momentum.co.za', @CountryId, 1, @DefaultDate, 'SYSTEM'),
	('Medshelf Medical Scheme', '+27 10 020 2020', 'membercare@medshelf.co.za', @CountryId, 1, @DefaultDate, 'SYSTEM'),
	('Bonitas', '+27 11 407 5000', 'support@bonitas.co.za', @CountryId, 1, @DefaultDate, 'SYSTEM'),
	('Polmed', '+27 11 386 4800', 'info@polmed.co.za', @CountryId, 1, @DefaultDate, 'SYSTEM'),
	('GEMS (Government Employees Medical Scheme)', '+27 12 307 9000', 'support@gems.gov.za', @CountryId, 1, @DefaultDate, 'SYSTEM'),
	('Sizwe Medical Scheme', '+27 11 287 8000', 'member@sizwehealth.co.za', @CountryId, 1, @DefaultDate, 'SYSTEM'),
	('Umkhulu Medical Scheme', '+27 31 328 6000', 'support@umkhulu.co.za', @CountryId, 1, @DefaultDate, 'SYSTEM')

GO

PRINT 'Insurance providers inserted successfully'
GO
