USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Returns the client clinic-category lookup used to classify clients by clinic profile.
CREATE OR ALTER PROC [Profile].[spGetClientClinicCategories]
(
    @ClientClinicCategoryId INT = 0,
    @IsActive BIT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CCC.ClientClinicCategoryId,
        CCC.CategoryName,
        CCC.ClinicSize,
        CCC.OwnershipType,
        CCC.IsActive,
        CCC.CreatedDate,
        CCC.UpdatedDate
    FROM Profile.ClientClinicCategories CCC
    WHERE (@ClientClinicCategoryId = 0 OR CCC.ClientClinicCategoryId = @ClientClinicCategoryId)
      AND (@IsActive IS NULL OR CCC.IsActive = @IsActive)
    ORDER BY CCC.CategoryName;

    SET NOCOUNT OFF;
END
GO
