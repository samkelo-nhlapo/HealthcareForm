USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Returns allergy lookup rows for search boxes and admin maintenance screens.
CREATE OR ALTER PROC [Lookup].[spGetAllergies]
(
    @SearchTerm VARCHAR(250) = '',
    @IsActive BIT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        AllergyId,
        AllergyName,
        AllergyCategory,
        Severity,
        ReactionDescription,
        IsCritical,
        IsActive,
        CreatedDate,
        CreatedBy
    FROM Lookup.Allergies
    WHERE (@SearchTerm = '' OR AllergyName LIKE '%' + @SearchTerm + '%')
      AND (@IsActive IS NULL OR IsActive = @IsActive)
    ORDER BY AllergyName;

    SET NOCOUNT OFF;
END
GO
