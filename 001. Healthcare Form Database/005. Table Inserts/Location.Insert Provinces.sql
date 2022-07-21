USE HealthcareForm
GO
DECLARE @DefaultDate DATETIME = GETDATE(),
		@ActiveStatus BIT = 0

INSERT INTO Location.Provinces
		(
			ProvinceName, 
			CountryIDFK, 
			IsActive, 
			UpdateDate
		)
VALUES('Eastern Cape', 1, @ActiveStatus, @DefaultDate ),
	  ('Free State', 1, @ActiveStatus, @DefaultDate ),
	  ('Gauteng', 1, @ActiveStatus, @DefaultDate ),
	  ('KwaZulu Natal', 1, @ActiveStatus, @DefaultDate ),
	  ('Limpopo', 1, @ActiveStatus, @DefaultDate ),
	  ('Mpumalanga', 1, @ActiveStatus, @DefaultDate ),
	  ('Northern Cape', 1, @ActiveStatus, @DefaultDate ),
	  ('North West', 1, @ActiveStatus, @DefaultDate ),
	  ('Western Cape', 1, @ActiveStatus, @DefaultDate )
