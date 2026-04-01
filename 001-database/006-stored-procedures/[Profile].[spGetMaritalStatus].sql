USE [HealthcareForm]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Lightweight marital-status lookup shaped for older dropdown-binding code paths.
-- IDs are returned as strings because some consumers still bind everything as text.
CREATE OR ALTER PROC [Profile].[spGetMaritalStatus]
(
    @MaritalStatusId INT = 0,
    @MaritalStatusDescription VARCHAR(250) = ''
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CAST(MaritalStatusId AS VARCHAR(250)) AS MaritalStatusIDFK,
        MaritalStatusDescription
    FROM Profile.MaritalStatus
    WHERE (@MaritalStatusId = 0 OR MaritalStatusId = @MaritalStatusId)
      AND (@MaritalStatusDescription = '' OR MaritalStatusDescription LIKE @MaritalStatusDescription + '%')
    ORDER BY MaritalStatusDescription;

    SET NOCOUNT OFF;
END
GO
