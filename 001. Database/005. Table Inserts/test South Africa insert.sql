USE HealthcareForm
GO

DECLARE @DefaultDate DATETIME = GETDATE(),
		@ActiveStatus BIT = 0

INSERT INTO Location.Countries
		(
			CountryName, 
			Alpha2Code, 
			Alpha3Code, 
			Numeric, 
			IsActive, 
			UpdateDate
		)
VALUES('South Africa', 'ZA', 'ZAF', 710, @ActiveStatus , @DefaultDate)