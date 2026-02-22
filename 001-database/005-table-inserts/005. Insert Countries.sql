USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Insert country lookup data
--	TFS Task:		Initialize countries lookup table
--================================================================================================

DECLARE @DefaultDate DATETIME = GETDATE()

INSERT INTO Location.Countries (CountryName, CountryCode, IsActive, CreatedDate, CreatedBy)
VALUES	
	('South Africa', 'ZA', 1, @DefaultDate, 'SYSTEM'),
	('Botswana', 'BW', 1, @DefaultDate, 'SYSTEM'),
	('Lesotho', 'LS', 1, @DefaultDate, 'SYSTEM'),
	('Namibia', 'NA', 1, @DefaultDate, 'SYSTEM'),
	('Eswatini', 'SZ', 1, @DefaultDate, 'SYSTEM'),
	('Zimbabwe', 'ZW', 1, @DefaultDate, 'SYSTEM'),
	('Mozambique', 'MZ', 1, @DefaultDate, 'SYSTEM'),
	('Angola', 'AO', 1, @DefaultDate, 'SYSTEM'),
	('Zambia', 'ZM', 1, @DefaultDate, 'SYSTEM'),
	('Malawi', 'MW', 1, @DefaultDate, 'SYSTEM'),
	('United States', 'US', 1, @DefaultDate, 'SYSTEM'),
	('United Kingdom', 'GB', 1, @DefaultDate, 'SYSTEM'),
	('Canada', 'CA', 1, @DefaultDate, 'SYSTEM'),
	('Australia', 'AU', 1, @DefaultDate, 'SYSTEM'),
	('Germany', 'DE', 1, @DefaultDate, 'SYSTEM'),
	('France', 'FR', 1, @DefaultDate, 'SYSTEM'),
	('India', 'IN', 1, @DefaultDate, 'SYSTEM'),
	('Brazil', 'BR', 1, @DefaultDate, 'SYSTEM'),
	('Japan', 'JP', 1, @DefaultDate, 'SYSTEM'),
	('China', 'CN', 1, @DefaultDate, 'SYSTEM')

GO

PRINT 'Countries lookup table populated successfully'
GO
