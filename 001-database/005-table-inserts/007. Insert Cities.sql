USE HealthcareForm
GO

DECLARE @DefaultDate DATETIME = GETDATE(),
        @ProvinceId_GT INT = (SELECT ProvinceId FROM Location.Provinces WHERE ProvinceName = 'Gauteng'),
        @ProvinceId_WC INT = (SELECT ProvinceId FROM Location.Provinces WHERE ProvinceName = 'Western Cape'),
        @ProvinceId_KZN INT = (SELECT ProvinceId FROM Location.Provinces WHERE ProvinceName = 'KwaZulu-Natal'),
        @ProvinceId_EC INT = (SELECT ProvinceId FROM Location.Provinces WHERE ProvinceName = 'Eastern Cape'),
        @ProvinceId_MP INT = (SELECT ProvinceId FROM Location.Provinces WHERE ProvinceName = 'Mpumalanga'),
        @ProvinceId_LP INT = (SELECT ProvinceId FROM Location.Provinces WHERE ProvinceName = 'Limpopo'),
        @ProvinceId_FS INT = (SELECT ProvinceId FROM Location.Provinces WHERE ProvinceName = 'Free State'),
        @ProvinceId_NC INT = (SELECT ProvinceId FROM Location.Provinces WHERE ProvinceName = 'Northern Cape'),
        @ProvinceId_NW INT = (SELECT ProvinceId FROM Location.Provinces WHERE ProvinceName = 'North West');

INSERT INTO Location.Cities (CityName, ProvinceIDFK, IsActive, UpdateDate)
SELECT V.CityName, V.ProvinceIDFK, V.IsActive, @DefaultDate
FROM (
    VALUES
        ('Johannesburg', @ProvinceId_GT, 1),
        ('Pretoria', @ProvinceId_GT, 1),
        ('Sandton', @ProvinceId_GT, 1),
        ('Midrand', @ProvinceId_GT, 1),
        ('Soweto', @ProvinceId_GT, 1),
        ('Benoni', @ProvinceId_GT, 1),
        ('Germiston', @ProvinceId_GT, 1),
        ('Roodepoort', @ProvinceId_GT, 1),
        ('Cape Town', @ProvinceId_WC, 1),
        ('Bellville', @ProvinceId_WC, 1),
        ('Parow', @ProvinceId_WC, 1),
        ('Mitchells Plain', @ProvinceId_WC, 1),
        ('Stellenbosch', @ProvinceId_WC, 1),
        ('Paarl', @ProvinceId_WC, 1),
        ('Durban', @ProvinceId_KZN, 1),
        ('Pietermaritzburg', @ProvinceId_KZN, 1),
        ('Newcastle', @ProvinceId_KZN, 1),
        ('Pinetown', @ProvinceId_KZN, 1),
        ('Umhlanga', @ProvinceId_KZN, 1),
        ('Westville', @ProvinceId_KZN, 1),
        ('Port Elizabeth', @ProvinceId_EC, 1),
        ('East London', @ProvinceId_EC, 1),
        ('Gqeberha', @ProvinceId_EC, 1),
        ('Nelspruit', @ProvinceId_MP, 1),
        ('Secunda', @ProvinceId_MP, 1),
        ('Emalahleni', @ProvinceId_MP, 1),
        ('Polokwane', @ProvinceId_LP, 1),
        ('Messina', @ProvinceId_LP, 1),
        ('Musina', @ProvinceId_LP, 1),
        ('Bloemfontein', @ProvinceId_FS, 1),
        ('Welkom', @ProvinceId_FS, 1),
        ('Kroonstad', @ProvinceId_FS, 1),
        ('Kimberley', @ProvinceId_NC, 1),
        ('De Aar', @ProvinceId_NC, 1),
        ('Rustenburg', @ProvinceId_NW, 1),
        ('Mafikeng', @ProvinceId_NW, 1),
        ('Potchefstroom', @ProvinceId_NW, 1)
) V(CityName, ProvinceIDFK, IsActive)
WHERE V.ProvinceIDFK IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM Location.Cities C
      WHERE C.CityName = V.CityName
        AND C.ProvinceIDFK = V.ProvinceIDFK
  );
GO

PRINT 'Cities lookup table populated successfully';
GO
