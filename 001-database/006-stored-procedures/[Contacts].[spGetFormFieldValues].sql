USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Returns the captured field-value rows for a single form submission.
CREATE OR ALTER PROC [Contacts].[spGetFormFieldValues]
(
    @FormSubmissionId UNIQUEIDENTIFIER
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        F.FormFieldValueId,
        F.FormSubmissionIdFK,
        F.FieldName,
        F.FieldType,
        F.FieldValue,
        F.DisplayOrder,
        F.IsRequired,
        F.ValidationRules,
        F.CreatedDate,
        F.CreatedBy,
        F.UpdatedDate,
        F.UpdatedBy
    FROM Contacts.FormFieldValues F
    WHERE F.FormSubmissionIdFK = @FormSubmissionId
    -- Display order comes first; newest edits break ties when display order is missing.
    ORDER BY
        CASE WHEN F.DisplayOrder IS NULL THEN 1 ELSE 0 END,
        F.DisplayOrder ASC,
        COALESCE(F.UpdatedDate, F.CreatedDate, GETDATE()) DESC;

    SET NOCOUNT OFF;
END
GO
