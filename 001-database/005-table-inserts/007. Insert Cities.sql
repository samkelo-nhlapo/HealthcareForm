USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Insert major South African cities lookup data
--	TFS Task:		Initialize cities lookup table
--================================================================================================

DECLARE @DefaultDate DATETIME = GETDATE(),
		@ProvinceId_GT INT = (SELECT ProvinceId FROM Location.Provinces WHERE ProvinceCode = 'GT'),
		@ProvinceId_WC INT = (SELECT ProvinceId FROM Location.Provinces WHERE ProvinceCode = 'WC'),
		@ProvinceId_KZN INT = (SELECT ProvinceId FROM Location.Provinces WHERE ProvinceCode = 'KZN'),
		@ProvinceId_EC INT = (SELECT ProvinceId FROM Location.Provinces WHERE ProvinceCode = 'EC'),
		@ProvinceId_MP INT = (SELECT ProvinceId FROM Location.Provinces WHERE ProvinceCode = 'MP'),
		@ProvinceId_LP INT = (SELECT ProvinceId FROM Location.Provinces WHERE ProvinceCode = 'LP'),
		@ProvinceId_FS INT = (SELECT ProvinceId FROM Location.Provinces WHERE ProvinceCode = 'FS'),
		@ProvinceId_NC INT = (SELECT ProvinceId FROM Location.Provinces WHERE ProvinceCode = 'NC'),
		@ProvinceId_NW INT = (SELECT ProvinceId FROM Location.Provinces WHERE ProvinceCode = 'NW')

INSERT INTO Location.Cities (CityName, ProvinceIdFK, IsActive, CreatedDate, CreatedBy)
VALUES	
	-- Gauteng
	('Johannesburg', @ProvinceId_GT, 1, @DefaultDate, 'SYSTEM'),
	('Pretoria', @ProvinceId_GT, 1, @DefaultDate, 'SYSTEM'),
	('Sandton', @ProvinceId_GT, 1, @DefaultDate, 'SYSTEM'),
	('Midrand', @ProvinceId_GT, 1, @DefaultDate, 'SYSTEM'),
	('Soweto', @ProvinceId_GT, 1, @DefaultDate, 'SYSTEM'),
	('Benoni', @ProvinceId_GT, 1, @DefaultDate, 'SYSTEM'),
	('Germiston', @ProvinceId_GT, 1, @DefaultDate, 'SYSTEM'),
	('Roodepoort', @ProvinceId_GT, 1, @DefaultDate, 'SYSTEM'),
	
	-- Western Cape
	('Cape Town', @ProvinceId_WC, 1, @DefaultDate, 'SYSTEM'),
	('Bellville', @ProvinceId_WC, 1, @DefaultDate, 'SYSTEM'),
	('Parow', @ProvinceId_WC, 1, @DefaultDate, 'SYSTEM'),
	('Mitchells Plain', @ProvinceId_WC, 1, @DefaultDate, 'SYSTEM'),
	('Stellenbosch', @ProvinceId_WC, 1, @DefaultDate, 'SYSTEM'),
	('Paarl', @ProvinceId_WC, 1, @DefaultDate, 'SYSTEM'),
	
	-- KwaZulu-Natal
	('Durban', @ProvinceId_KZN, 1, @DefaultDate, 'SYSTEM'),
	('Pietermaritzburg', @ProvinceId_KZN, 1, @DefaultDate, 'SYSTEM'),
	('Newcastle', @ProvinceId_KZN, 1, @DefaultDate, 'SYSTEM'),
	('Pinetown', @ProvinceId_KZN, 1, @DefaultDate, 'SYSTEM'),
	('Umhlanga', @ProvinceId_KZN, 1, @DefaultDate, 'SYSTEM'),
	('Westville', @ProvinceId_KZN, 1, @DefaultDate, 'SYSTEM'),
	
	-- Eastern Cape
	('Port Elizabeth', @ProvinceId_EC, 1, @DefaultDate, 'SYSTEM'),
	('East London', @ProvinceId_EC, 1, @DefaultDate, 'SYSTEM'),
	('Gqeberha', @ProvinceId_EC, 1, @DefaultDate, 'SYSTEM'),
	
	-- Mpumalanga
	('Nelspruit', @ProvinceId_MP, 1, @DefaultDate, 'SYSTEM'),
	('Secunda', @ProvinceId_MP, 1, @DefaultDate, 'SYSTEM'),
	('Emalahleni', @ProvinceId_MP, 1, @DefaultDate, 'SYSTEM'),
	
	-- Limpopo
	('Polokwane', @ProvinceId_LP, 1, @DefaultDate, 'SYSTEM'),
	('Messina', @ProvinceId_LP, 1, @DefaultDate, 'SYSTEM'),
	('Musina', @ProvinceId_LP, 1, @DefaultDate, 'SYSTEM'),
	
	-- Free State
	('Bloemfontein', @ProvinceId_FS, 1, @DefaultDate, 'SYSTEM'),
	('Welkom', @ProvinceId_FS, 1, @DefaultDate, 'SYSTEM'),
	('Kroonstad', @ProvinceId_FS, 1, @DefaultDate, 'SYSTEM'),
	
	-- Northern Cape
	('Kimberley', @ProvinceId_NC, 1, @DefaultDate, 'SYSTEM'),
	('De Aar', @ProvinceId_NC, 1, @DefaultDate, 'SYSTEM'),
	
	-- North West
	('Rustenburg', @ProvinceId_NW, 1, @DefaultDate, 'SYSTEM'),
	('Mafikeng', @ProvinceId_NW, 1, @DefaultDate, 'SYSTEM'),
	('Potchefstroom', @ProvinceId_NW, 1, @DefaultDate, 'SYSTEM')

GO

PRINT 'Cities lookup table populated successfully'
GO
