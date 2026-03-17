USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Lookup].[spGetMedications]
(
    @SearchTerm VARCHAR(250) = '',
    @IsActive BIT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        MedicationId,
        MedicationName,
        MedicationGenericName,
        MedicationCategory,
        Strength,
        Unit,
        RouteOfAdministration,
        ManufacturerName,
        IsActive,
        CreatedDate,
        CreatedBy
    FROM Lookup.Medications
    WHERE (@SearchTerm = '' OR MedicationName LIKE '%' + @SearchTerm + '%')
      AND (@IsActive IS NULL OR IsActive = @IsActive)
    ORDER BY MedicationName;

    SET NOCOUNT OFF;
END
GO
