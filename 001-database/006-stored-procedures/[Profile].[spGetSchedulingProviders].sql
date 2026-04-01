USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Returns active providers for the scheduling dashboard.
-- The API derives display labels, capacity, and clinic grouping on top of this lightweight shape.
CREATE OR ALTER PROC [Profile].[spGetSchedulingProviders]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        HP.ProviderId,
        HP.FirstName,
        HP.LastName,
        HP.Title,
        HP.Specialization
    FROM Profile.HealthcareProviders HP
    WHERE HP.IsActive = 1
    ORDER BY HP.LastName, HP.FirstName;
END
GO
