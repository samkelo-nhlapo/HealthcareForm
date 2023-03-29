USE HealthcareForm
GO

CREATE OR ALTER PROC Location.spGetCities
(
	@CityIDFK INT = 0,
	@CityName VARCHAR(250) = ''
)
AS
BEGIN
	SET NOCOUNT ON
	
		SELECT 
			CAST(CityId AS VARCHAR(250)) AS CityIDFK, CityName 
		FROM Location.Cities WITH(NOLOCK)
	
	SET NOCOUNT OFF
END