USE [HealthcareForm]
GO

/****** Object:  StoredProcedure [Profile].[spGetGender]    Script Date: 21-Jul-22 11:36:04 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER PROC [Profile].[spGetGender]
(
	@GenderId INT = 0,
	@GenderDescription VARCHAR(250) = ''
)
AS
BEGIN

	SET NOCOUNT ON
	
		SELECT CAST(GenderId AS VARCHAR(250)) AS GenderIDFK, GenderDescription 
		FROM Profile.Gender WITH(NOLOCK)
	
	SET NOCOUNT OFF

END
GO


