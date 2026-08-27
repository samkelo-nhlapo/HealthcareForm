USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Returns clinic/hospital options with linked doctor providers for appointment booking.
CREATE OR ALTER PROC [Profile].[spGetSchedulingBookingOptions]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Now DATETIME = GETDATE();

    SELECT DISTINCT
        C.ClientId,
        C.ClientCode,
        ClientName = CASE
            WHEN LTRIM(RTRIM(CONCAT(ISNULL(C.FirstName, ''), ' ', ISNULL(C.LastName, '')))) = ''
                THEN COALESCE(NULLIF(LTRIM(RTRIM(C.ClientCode)), ''), 'Client')
            ELSE LTRIM(RTRIM(CONCAT(ISNULL(C.FirstName, ''), ' ', ISNULL(C.LastName, ''))))
        END,
        ClientCategory = COALESCE(NULLIF(LTRIM(RTRIM(CCC.CategoryName)), ''), 'Uncategorized'),
        ClientStaffId = CPA.ClientStaffIdFK,
        HP.ProviderId,
        Provider = LTRIM(RTRIM(CONCAT(
            CASE
                WHEN NULLIF(LTRIM(RTRIM(ISNULL(HP.Title, ''))), '') IS NULL THEN ''
                ELSE LTRIM(RTRIM(HP.Title)) + ' '
            END,
            CASE
                WHEN LTRIM(RTRIM(CONCAT(ISNULL(HP.FirstName, ''), ' ', ISNULL(HP.LastName, '')))) = ''
                    THEN 'Provider'
                ELSE LTRIM(RTRIM(CONCAT(ISNULL(HP.FirstName, ''), ' ', ISNULL(HP.LastName, ''))))
            END
        ))),
        Clinic = COALESCE(NULLIF(LTRIM(RTRIM(HP.Specialization)), ''), 'General'),
        ClientProviderAffiliationId = CPA.ClientProviderAffiliationId
    FROM Profile.Clients C
    INNER JOIN Profile.ClientProviderAffiliations CPA
        ON CPA.ClientIdFK = C.ClientId
       AND CPA.IsActive = 1
       AND CPA.CanBookAppointments = 1
       AND CPA.StartDate <= @Now
       AND (CPA.EndDate IS NULL OR CPA.EndDate >= @Now)
    INNER JOIN Profile.HealthcareProviders HP
        ON HP.ProviderId = CPA.ProviderIdFK
       AND HP.IsActive = 1
    LEFT JOIN Profile.ClientStaff CS
        ON CS.ClientStaffId = CPA.ClientStaffIdFK
    LEFT JOIN Profile.ClientClinicCategories CCC
        ON CCC.ClientClinicCategoryId = C.ClientClinicCategoryIDFK
    WHERE C.IsDeleted = 0
      AND C.IsActive = 1
      AND (
            CPA.ClientStaffIdFK IS NULL
            OR (CS.ClientStaffId IS NOT NULL AND CS.IsDeleted = 0 AND CS.IsActive = 1)
          )
    ORDER BY
        ClientName ASC,
        Provider ASC;

    SET NOCOUNT OFF;
END
GO
