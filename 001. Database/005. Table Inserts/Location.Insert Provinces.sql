USE HealthcareForm
GO

-- This insert query inserts South African Provinces into [Location].[Provinces] Table

DECLARE @DefaultDate DATETIME = GETDATE(),
		@ActiveStatus BIT = 0,
		@CountryName VARCHAR

INSERT INTO Location.Provinces
		(
			ProvinceName, 
			CountryIDFK, 
			IsActive, 
			UpdateDate
		)
VALUES('Eastern Cape', (SELECT CountryId FROM Location.Countries WHERE CountryName = @CountryName), @ActiveStatus, @DefaultDate ),
	  ('Free State', (SELECT CountryId FROM Location.Countries WHERE CountryName = @CountryName), @ActiveStatus, @DefaultDate ),
	  ('Gauteng', (SELECT CountryId FROM Location.Countries WHERE CountryName = @CountryName), @ActiveStatus, @DefaultDate ),
	  ('KwaZulu Natal', (SELECT CountryId FROM Location.Countries WHERE CountryName = @CountryName), @ActiveStatus, @DefaultDate ),
	  ('Limpopo', (SELECT CountryId FROM Location.Countries WHERE CountryName = @CountryName), @ActiveStatus, @DefaultDate ),
	  ('Mpumalanga', (SELECT CountryId FROM Location.Countries WHERE CountryName = @CountryName), @ActiveStatus, @DefaultDate ),
	  ('Northern Cape', (SELECT CountryId FROM Location.Countries WHERE CountryName = @CountryName), @ActiveStatus, @DefaultDate ),
	  ('North West', (SELECT CountryId FROM Location.Countries WHERE CountryName = @CountryName), @ActiveStatus, @DefaultDate ),
	  ('Western Cape', (SELECT CountryId FROM Location.Countries WHERE CountryName = @CountryName), @ActiveStatus, @DefaultDate )
