USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Returns medication rows for the patient identified by ID number.
-- Output stays close to the table shape because the API performs only light mapping.
CREATE OR ALTER PROC [Profile].[spGetPatientMedications]
(
    @IDNumber VARCHAR(250)
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        M.MedicationId,
        M.MedicationName,
        M.Dosage,
        M.Frequency,
        M.Route,
        M.Indication,
        M.PrescribedBy,
        M.PrescriptionDate,
        M.StartDate,
        M.EndDate,
        M.Status,
        M.SideEffects,
        M.Notes,
        M.IsActive,
        M.CreatedDate,
        M.CreatedBy,
        M.UpdatedDate,
        M.UpdatedBy
    FROM Profile.Medications M
    INNER JOIN Profile.Patient P
        ON P.PatientId = M.PatientIdFK
    WHERE P.ID_Number = @IDNumber
      AND P.IsDeleted = 0
    ORDER BY COALESCE(M.UpdatedDate, M.StartDate, M.PrescriptionDate, GETDATE()) DESC;

    SET NOCOUNT OFF;
END
GO
