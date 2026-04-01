USE HealthcareForm
GO

-- Lightweight city lookup shaped for older dropdown-binding code paths.
-- IDs are returned as strings because some consumers still bind everything as text.
CREATE OR ALTER PROC [Location].[spGetCities]
(
    @CityIDFK INT = 0,
    @CityName VARCHAR(250) = ''
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CAST(CityId AS VARCHAR(250)) AS CityIDFK,
        CityName
    FROM Location.Cities
    WHERE (@CityIDFK = 0 OR CityId = @CityIDFK)
      AND (@CityName = '' OR CityName LIKE @CityName + '%')
    ORDER BY CityName;

    SET NOCOUNT OFF;
END
GO
