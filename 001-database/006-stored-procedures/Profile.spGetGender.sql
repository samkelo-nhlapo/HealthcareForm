USE [HealthcareForm]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Lightweight gender lookup shaped for older dropdown-binding code paths.
-- IDs are returned as strings because some consumers still bind everything as text.
CREATE OR ALTER PROC [Profile].[spGetGender]
(
    @GenderId INT = 0,
    @GenderDescription VARCHAR(250) = ''
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CAST(GenderId AS VARCHAR(250)) AS GenderIDFK,
        GenderDescription
    FROM Profile.Gender
    WHERE (@GenderId = 0 OR GenderId = @GenderId)
      AND (@GenderDescription = '' OR GenderDescription LIKE @GenderDescription + '%')
    ORDER BY GenderDescription;

    SET NOCOUNT OFF;
END
GO
