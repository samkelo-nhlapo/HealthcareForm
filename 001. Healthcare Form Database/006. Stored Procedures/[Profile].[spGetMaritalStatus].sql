USE [HealthcareForm]
GO

/****** Object:  StoredProcedure [Profile].[spGetMaritalStatus]    Script Date: 21-Jul-22 11:34:19 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER   PROC [Profile].[spGetMaritalStatus]
(
	@MaritalStatusId INT = 0,
	@MaritalStatusDescription VARCHAR(250) = ''
)
AS
BEGIN

SET NOCOUNT ON

	SELECT CAST(MaritalStatusId AS VARCHAR(250)) AS MaritalStatusIDFK, MaritalStatusDescription 
	FROM Profile.MaritalStatus WITH(NOLOCK)

SET NOCOUNT OFF

END
GO


