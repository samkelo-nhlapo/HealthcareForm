USE HealthcareForm;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- Returns two result sets in a fixed order for the admin data-governance view.
-- 1. Template governance summary. 2. Lookup freshness summary.
CREATE OR ALTER PROC [Auth].[spGetAdminDataGovernanceSourceRows]
AS
BEGIN
    SET NOCOUNT ON;

    -- Result set 1: templates/forms and their latest approval signals.
    SELECT TOP (50)
        FT.FormName,
        FT.FormVersion,
        FT.IsActive,
        COALESCE(NULLIF(FT.UpdatedBy, ''), NULLIF(FT.CreatedBy, ''), 'Operations') AS Owner,
        COALESCE(FT.UpdatedDate, FT.CreatedDate, GETDATE()) AS TemplateUpdatedDate,
        MAX(
            CASE
                WHEN UPPER(FS.Status) IN ('APPROVED', 'SIGNED')
                    THEN COALESCE(FS.ReviewDate, FS.SignatureDate, FS.CompletionDate, FS.SubmissionDate)
                ELSE NULL
            END
        ) AS LastApprovedDate,
        MAX(CASE WHEN UPPER(FS.Status) = 'DRAFT' THEN 1 ELSE 0 END) AS HasDraft
    FROM Contacts.FormTemplates FT
    LEFT JOIN Contacts.FormSubmissions FS
        ON FS.FormTemplateIdFK = FT.FormTemplateId
    GROUP BY
        FT.FormName,
        FT.FormVersion,
        FT.IsActive,
        FT.UpdatedBy,
        FT.CreatedBy,
        FT.UpdatedDate,
        FT.CreatedDate
    ORDER BY COALESCE(FT.UpdatedDate, FT.CreatedDate, GETDATE()) DESC;

    -- Result set 2: lookup domains and their freshness metadata.
    SELECT 'Gender' AS LookupName, COUNT(1) AS Records, MAX(UpdateDate) AS LastSync, 'api/lookups/genders' AS Source, 'Weekly' AS RefreshCadence
    FROM Profile.Gender
    WHERE IsActive = 1
    UNION ALL
    SELECT 'Marital Status' AS LookupName, COUNT(1) AS Records, MAX(UpdateDate) AS LastSync, 'api/lookups/marital-statuses' AS Source, 'Weekly' AS RefreshCadence
    FROM Profile.MaritalStatus
    WHERE IsActive = 1
    UNION ALL
    SELECT 'Provinces' AS LookupName, COUNT(1) AS Records, MAX(UpdateDate) AS LastSync, 'api/lookups/provinces' AS Source, 'Daily' AS RefreshCadence
    FROM Location.Provinces
    WHERE IsActive = 1
    UNION ALL
    SELECT 'Cities' AS LookupName, COUNT(1) AS Records, MAX(UpdateDate) AS LastSync, 'api/lookups/cities' AS Source, 'Daily' AS RefreshCadence
    FROM Location.Cities
    WHERE IsActive = 1;
END
GO
