USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spGetPatientAllergies]
(
    @IDNumber VARCHAR(250)
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        A.AllergyId,
        A.AllergyType,
        A.AllergenName,
        A.Reaction,
        A.Severity,
        A.ReactionOnsetDate,
        A.VerifiedBy,
        A.IsActive,
        A.CreatedDate,
        A.CreatedBy,
        A.UpdatedDate,
        A.UpdatedBy
    FROM Profile.Allergies A
    INNER JOIN Profile.Patient P
        ON P.PatientId = A.PatientIdFK
    WHERE P.ID_Number = @IDNumber
      AND P.IsDeleted = 0
    ORDER BY COALESCE(A.UpdatedDate, A.CreatedDate, GETDATE()) DESC;

    SET NOCOUNT OFF;
END
GO
