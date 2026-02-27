USE HealthcareForm
GO

DECLARE @CountryId INT = (SELECT CountryId FROM Location.Countries WHERE Alpha2Code = 'ZA'),
        @DefaultDate DATETIME = GETDATE();

INSERT INTO Location.Provinces (ProvinceName, CountryIDFK, IsActive, UpdateDate)
SELECT V.ProvinceName, V.CountryIDFK, V.IsActive, @DefaultDate
FROM (
    VALUES
        ('Western Cape', @CountryId, 1),
        ('Eastern Cape', @CountryId, 1),
        ('Northern Cape', @CountryId, 1),
        ('Free State', @CountryId, 1),
        ('KwaZulu-Natal', @CountryId, 1),
        ('Gauteng', @CountryId, 1),
        ('Limpopo', @CountryId, 1),
        ('Mpumalanga', @CountryId, 1),
        ('North West', @CountryId, 1)
) V(ProvinceName, CountryIDFK, IsActive)
WHERE @CountryId IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM Location.Provinces P
      WHERE P.ProvinceName = V.ProvinceName
        AND P.CountryIDFK = V.CountryIDFK
  );
GO

PRINT 'Provinces lookup table populated successfully';
GO
