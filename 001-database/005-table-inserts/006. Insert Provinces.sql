USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Insert South African provinces lookup data
--	TFS Task:		Initialize provinces lookup table
--================================================================================================

DECLARE @CountryId INT = (SELECT CountryId FROM Location.Countries WHERE CountryCode = 'ZA'),
		@DefaultDate DATETIME = GETDATE()

INSERT INTO Location.Provinces (ProvinceName, ProvinceCode, CountryIdFK, IsActive, CreatedDate, CreatedBy)
VALUES	
	('Western Cape', 'WC', @CountryId, 1, @DefaultDate, 'SYSTEM'),
	('Eastern Cape', 'EC', @CountryId, 1, @DefaultDate, 'SYSTEM'),
	('Northern Cape', 'NC', @CountryId, 1, @DefaultDate, 'SYSTEM'),
	('Free State', 'FS', @CountryId, 1, @DefaultDate, 'SYSTEM'),
	('KwaZulu-Natal', 'KZN', @CountryId, 1, @DefaultDate, 'SYSTEM'),
	('Gauteng', 'GT', @CountryId, 1, @DefaultDate, 'SYSTEM'),
	('Limpopo', 'LP', @CountryId, 1, @DefaultDate, 'SYSTEM'),
	('Mpumalanga', 'MP', @CountryId, 1, @DefaultDate, 'SYSTEM'),
	('North West', 'NW', @CountryId, 1, @DefaultDate, 'SYSTEM')

GO

PRINT 'Provinces lookup table populated successfully'
GO
