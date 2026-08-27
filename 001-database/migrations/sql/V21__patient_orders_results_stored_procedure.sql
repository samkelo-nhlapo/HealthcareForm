SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- Returns laboratory result rows for the patient identified by ID number.
-- Pending rows are interpreted by the API as open orders, while completed rows
-- are exposed as recent results for the clinical workspace.
CREATE OR ALTER PROC [Profile].[spGetPatientLabResults]
(
    @IDNumber VARCHAR(250)
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        LR.LabResultId,
        LR.TestName,
        LR.TestCode,
        LR.SpecimenType,
        LR.CollectionDate,
        LR.ResultDate,
        LR.ResultValue,
        LR.Unit,
        LR.ReferenceRange,
        LR.Status,
        LR.OrderedBy,
        LR.Lab,
        LR.Interpretation,
        LR.Notes,
        LR.CreatedDate,
        LR.UpdatedDate
    FROM Profile.LabResults LR
    INNER JOIN Profile.Patient P
        ON P.PatientId = LR.PatientIdFK
    WHERE P.ID_Number = @IDNumber
      AND P.IsDeleted = 0
    ORDER BY COALESCE(LR.ResultDate, LR.CollectionDate, LR.UpdatedDate, LR.CreatedDate, GETDATE()) DESC;
END
GO
