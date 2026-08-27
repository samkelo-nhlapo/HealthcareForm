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

    DECLARE @Now DATETIME = GETDATE();

    SELECT
        ClientStaffId = CPA.ClientStaffIdFK,
        C.ClientId,
        ClientName = CASE
            WHEN LTRIM(RTRIM(CONCAT(ISNULL(C.FirstName, ''), ' ', ISNULL(C.LastName, '')))) = ''
                THEN COALESCE(NULLIF(LTRIM(RTRIM(C.ClientCode)), ''), 'Client')
            ELSE LTRIM(RTRIM(CONCAT(ISNULL(C.FirstName, ''), ' ', ISNULL(C.LastName, ''))))
        END,
        HP.ProviderId,
        HP.FirstName,
        HP.LastName,
        HP.Title,
        HP.Specialization,
        ClientProviderAffiliationId = CPA.ClientProviderAffiliationId
    FROM Profile.ClientProviderAffiliations CPA
    INNER JOIN Profile.Clients C
        ON C.ClientId = CPA.ClientIdFK
       AND C.IsDeleted = 0
       AND C.IsActive = 1
    INNER JOIN Profile.HealthcareProviders HP
        ON HP.ProviderId = CPA.ProviderIdFK
       AND HP.IsActive = 1
    LEFT JOIN Profile.ClientStaff CS
        ON CS.ClientStaffId = CPA.ClientStaffIdFK
    WHERE CPA.IsActive = 1
      AND CPA.CanBookAppointments = 1
      AND CPA.StartDate <= @Now
      AND (CPA.EndDate IS NULL OR CPA.EndDate >= @Now)
      AND (
            CPA.ClientStaffIdFK IS NULL
            OR (CS.ClientStaffId IS NOT NULL AND CS.IsDeleted = 0 AND CS.IsActive = 1)
          )
    ORDER BY
        ClientName,
        HP.LastName,
        HP.FirstName,
        CPA.ClientProviderAffiliationId;
END
GO
