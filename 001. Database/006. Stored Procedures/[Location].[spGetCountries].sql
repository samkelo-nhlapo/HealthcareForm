USE [HealthcareForm]
GO

/****** Object:  StoredProcedure [Location].[spGetCountries]    Script Date: 21-Jul-22 09:55:17 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- This Procedure gets the Countries list to .Net

CREATE OR ALTER   PROC [Location].[spGetCountries]
(
	@CountryId INT = 0,
	@CountryName VARCHAR(250) = ''
)
AS
BEGIN

SET NOCOUNT ON

	SELECT 
		CAST(CountryId AS VARCHAR(250)) AS CountryIDFK, 
		CountryName 
	FROM Location.Countries 

SET NOCOUNT OFF

END
GO


