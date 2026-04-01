USE HealthcareForm
GO

-- Lightweight province lookup shaped for older dropdown-binding code paths.
-- IDs are returned as strings because some consumers still bind everything as text.
CREATE OR ALTER PROC [Location].[spGetProvinces]
(
    @ProvinceId INT = 0,
    @ProvinceName VARCHAR(250) = ''
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CAST(ProvinceId AS VARCHAR(250)) AS ProvinceIDFK,
        ProvinceName
    FROM Location.Provinces
    WHERE (@ProvinceId = 0 OR ProvinceId = @ProvinceId)
      AND (@ProvinceName = '' OR ProvinceName LIKE @ProvinceName + '%')
    ORDER BY ProvinceName;

    SET NOCOUNT OFF;
END
GO
