USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spGetPatientConsultationNotes]
(
    @IDNumber VARCHAR(250)
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CN.ConsultationNoteId,
        CN.AppointmentIdFK,
        CN.ProviderIdFK,
        ProviderName = LTRIM(RTRIM(ISNULL(HP.FirstName, '') + ' ' + ISNULL(HP.LastName, ''))),
        ProviderSpecialization = ISNULL(HP.Specialization, ''),
        CN.ConsultationDate,
        CN.ChiefComplaint,
        CN.PresentingSymptoms,
        CN.History,
        CN.PhysicalExamination,
        CN.Diagnosis,
        CN.DiagnosisCodes,
        CN.TreatmentPlan,
        CN.Medications,
        CN.Procedures,
        CN.FollowUpDate,
        CN.ReferralNeeded,
        CN.ReferralReason,
        CN.Restrictions,
        CN.Notes,
        CN.CreatedDate,
        CN.CreatedBy,
        CN.UpdatedDate,
        CN.UpdatedBy
    FROM Profile.ConsultationNotes CN
    INNER JOIN Profile.Patient P
        ON P.PatientId = CN.PatientIdFK
    LEFT JOIN Profile.HealthcareProviders HP
        ON HP.ProviderId = CN.ProviderIdFK
    WHERE P.ID_Number = @IDNumber
      AND P.IsDeleted = 0
    ORDER BY COALESCE(CN.UpdatedDate, CN.ConsultationDate, GETDATE()) DESC;

    SET NOCOUNT OFF;
END
GO
