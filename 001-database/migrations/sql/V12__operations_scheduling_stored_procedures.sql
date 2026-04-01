USE HealthcareForm;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
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

-- Returns appointments inside a requested scheduling window.
-- The API layers clinic normalization and capacity calculations on top of the raw rows.
CREATE OR ALTER PROC [Profile].[spGetSchedulingAppointments]
(
    @WindowStart DATETIME = NULL,
    @WindowEnd DATETIME = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Default to a same-day window because the dashboard is optimized for today's load.
    IF @WindowStart IS NULL
    BEGIN
        SET @WindowStart = CAST(GETDATE() AS DATE);
    END

    IF @WindowEnd IS NULL OR @WindowEnd <= @WindowStart
    BEGIN
        SET @WindowEnd = DATEADD(DAY, 1, @WindowStart);
    END

    SELECT
        A.ProviderIdFK,
        A.AppointmentDateTime,
        A.DurationMinutes,
        A.Status,
        A.Location,
        HP.Specialization
    FROM Profile.Appointments A
    LEFT JOIN Profile.HealthcareProviders HP
        ON HP.ProviderId = A.ProviderIdFK
    WHERE A.AppointmentDateTime >= @WindowStart
      AND A.AppointmentDateTime < @WindowEnd;
END
GO
