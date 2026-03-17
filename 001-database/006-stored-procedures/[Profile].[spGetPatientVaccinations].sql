USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spGetPatientVaccinations]
(
    @IDNumber VARCHAR(250)
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        V.VaccinationId,
        V.VaccineName,
        V.VaccineCode,
        V.AdministrationDate,
        V.DueDate,
        V.AdministeredBy,
        V.Lot,
        V.Site,
        V.Route,
        V.Reaction,
        V.Status,
        V.Notes,
        V.CreatedDate,
        V.CreatedBy,
        V.UpdatedDate,
        V.UpdatedBy
    FROM Profile.Vaccinations V
    INNER JOIN Profile.Patient P
        ON P.PatientId = V.PatientIdFK
    WHERE P.ID_Number = @IDNumber
      AND P.IsDeleted = 0
    ORDER BY COALESCE(V.UpdatedDate, V.AdministrationDate, GETDATE()) DESC;

    SET NOCOUNT OFF;
END
GO
