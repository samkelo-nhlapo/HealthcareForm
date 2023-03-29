USE HealthcareForm
GO

CREATE OR ALTER PROC Location.spGetProvinces
(
	@ProvinceId INT = '',
	@ProvinceName VARCHAR(250) = ''
)
AS
BEGIN
SET NOCOUNT ON
	
	SELECT 
		CAST(ProvinceId AS VARCHAR(250)) AS ProvinceIDFK , 
		ProvinceName
	FROM  Location.Provinces WITH (NOLOCK)

SET NOCOUNT OFF
END