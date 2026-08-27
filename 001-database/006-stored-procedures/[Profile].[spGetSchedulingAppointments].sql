USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
        ClientStaffIdFK = COALESCE(A.ClientStaffIdFK, DirectAffiliation.ClientStaffIdFK, FallbackAffiliation.ClientStaffIdFK),
        ClientIdFK = COALESCE(A.ClientIdFK, DirectAffiliation.ClientIdFK, FallbackAffiliation.ClientIdFK),
        ClientName = CASE
            WHEN LTRIM(RTRIM(CONCAT(ISNULL(C.FirstName, ''), ' ', ISNULL(C.LastName, '')))) = ''
                THEN COALESCE(NULLIF(LTRIM(RTRIM(C.ClientCode)), ''), 'Client')
            ELSE LTRIM(RTRIM(CONCAT(ISNULL(C.FirstName, ''), ' ', ISNULL(C.LastName, ''))))
        END,
        ProviderId = COALESCE(DirectAffiliation.ProviderIdFK, FallbackAffiliation.ProviderIdFK, A.ProviderIdFK),
        A.AppointmentDateTime,
        A.DurationMinutes,
        A.Status,
        A.Location,
        HP.Specialization,
        ClientProviderAffiliationIdFK = COALESCE(A.ClientProviderAffiliationIdFK, FallbackAffiliation.ClientProviderAffiliationId)
    FROM Profile.Appointments A
    LEFT JOIN Profile.ClientProviderAffiliations DirectAffiliation
        ON DirectAffiliation.ClientProviderAffiliationId = A.ClientProviderAffiliationIdFK
    OUTER APPLY
    (
        SELECT TOP 1
            CPA.ClientProviderAffiliationId,
            CPA.ClientStaffIdFK,
            CPA.ClientIdFK,
            CPA.ProviderIdFK
        FROM Profile.ClientProviderAffiliations CPA
        WHERE A.ClientProviderAffiliationIdFK IS NULL
          AND CPA.ProviderIdFK = A.ProviderIdFK
          AND
          (
              A.ClientIdFK IS NULL
              OR CPA.ClientIdFK = A.ClientIdFK
          )
        ORDER BY
            CASE
                WHEN A.ClientIdFK IS NOT NULL AND CPA.ClientIdFK = A.ClientIdFK THEN 0
                ELSE 1
            END,
            CASE
                WHEN CPA.IsActive = 1 THEN 0
                ELSE 1
            END,
            CASE
                WHEN CPA.EndDate IS NULL THEN 0
                ELSE 1
            END,
            CASE
                WHEN CPA.ClientStaffIdFK IS NOT NULL THEN 0
                ELSE 1
            END,
            COALESCE(CPA.UpdatedDate, CPA.CreatedDate) DESC,
            CPA.ClientProviderAffiliationId DESC
    ) FallbackAffiliation
    LEFT JOIN Profile.HealthcareProviders HP
        ON HP.ProviderId = COALESCE(DirectAffiliation.ProviderIdFK, FallbackAffiliation.ProviderIdFK, A.ProviderIdFK)
    LEFT JOIN Profile.Clients C
        ON C.ClientId = COALESCE(A.ClientIdFK, DirectAffiliation.ClientIdFK, FallbackAffiliation.ClientIdFK)
    WHERE A.AppointmentDateTime >= @WindowStart
      AND A.AppointmentDateTime < @WindowEnd;
END
GO
