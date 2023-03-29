USE [PatientEnrollment]
GO

/****** Object:  StoredProcedure [Location].[spInsertCountries]    Script Date: 17-Feb-22 12:11:45 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER   PROC [Location].[spInsertCountries]
(
	@Country VARCHAR(250),
	@Alpha2Code VARCHAR(250),
	@Alpha3Code VARCHAR(250),
	@Numeric VARCHAR(250),
	@IsActive BIT,
	@UpdateDate DATETIME,
	@Message VARCHAR(250) OUTPUT
)
AS
BEGIN

SET NOCOUNT ON

	IF NOT EXISTS(SELECT 1 FROM Location.Countries WITH(NOLOCK) WHERE CountryName = @Country)
	BEGIN

		INSERT INTO Location.Countries
		(
			CountryName, 
			Alpha2Code, 
			Alpha3Code, 
			Numeric, 
			IsActive, 
			UpdateDate
		)
		VALUES(@Country, @Alpha2Code, @Alpha3Code, @Numeric, @IsActive, @UpdateDate)
	
		SET @Message = ''

	END ELSE
	BEGIN
		
		SET @Message = 'please check xlsx doc Duplicate found '

	END

SET NOCOUNT OFF

END
GO


