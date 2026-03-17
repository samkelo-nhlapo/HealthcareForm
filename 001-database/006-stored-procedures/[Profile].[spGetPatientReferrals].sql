USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spGetPatientReferrals]
(
    @IDNumber VARCHAR(250)
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        R.ReferralId,
        R.ReferringProviderIdFK,
        ReferringProviderName = LTRIM(RTRIM(ISNULL(RP.FirstName, '') + ' ' + ISNULL(RP.LastName, ''))),
        R.ReferredProviderIdFK,
        ReferredProviderName = LTRIM(RTRIM(ISNULL(RTP.FirstName, '') + ' ' + ISNULL(RTP.LastName, ''))),
        R.ReferralDate,
        R.Reason,
        R.Priority,
        R.ReferralType,
        R.SpecializationNeeded,
        R.ReferralCode,
        R.Status,
        R.AcceptanceDate,
        R.CompletionDate,
        R.Notes,
        R.CreatedDate,
        R.CreatedBy,
        R.UpdatedDate,
        R.UpdatedBy
    FROM Profile.Referrals R
    INNER JOIN Profile.Patient P
        ON P.PatientId = R.PatientIdFK
    LEFT JOIN Profile.HealthcareProviders RP
        ON RP.ProviderId = R.ReferringProviderIdFK
    LEFT JOIN Profile.HealthcareProviders RTP
        ON RTP.ProviderId = R.ReferredProviderIdFK
    WHERE P.ID_Number = @IDNumber
      AND P.IsDeleted = 0
    ORDER BY COALESCE(R.UpdatedDate, R.ReferralDate, GETDATE()) DESC;

    SET NOCOUNT OFF;
END
GO
