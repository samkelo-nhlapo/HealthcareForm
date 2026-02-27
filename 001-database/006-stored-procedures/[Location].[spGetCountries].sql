USE [HealthcareForm]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Location].[spGetCountries]
(
    @CountryId INT = 0,
    @CountryName VARCHAR(250) = ''
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CAST(CountryId AS VARCHAR(250)) AS CountryIDFK,
        CountryName
    FROM Location.Countries
    WHERE (@CountryId = 0 OR CountryId = @CountryId)
      AND (@CountryName = '' OR CountryName LIKE @CountryName + '%')
    ORDER BY CountryName;

    SET NOCOUNT OFF;
END
GO
