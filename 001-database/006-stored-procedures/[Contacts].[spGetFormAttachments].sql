USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Returns file attachments for a single form submission, newest first.
CREATE OR ALTER PROC [Contacts].[spGetFormAttachments]
(
    @FormSubmissionId UNIQUEIDENTIFIER
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        A.FormAttachmentId,
        A.FormSubmissionIdFK,
        A.FileName,
        A.FileType,
        A.FileSizeBytes,
        A.FileHash,
        A.StoragePath,
        A.DocumentType,
        A.UploadedDate,
        A.UploadedBy,
        A.IsVerified,
        A.VerifiedBy,
        A.VerificationDate,
        A.ExpiryDate,
        A.Notes,
        A.CreatedDate,
        A.CreatedBy,
        A.UpdatedDate,
        A.UpdatedBy
    FROM Contacts.FormAttachments A
    WHERE A.FormSubmissionIdFK = @FormSubmissionId
    ORDER BY COALESCE(A.UploadedDate, A.CreatedDate, GETDATE()) DESC;

    SET NOCOUNT OFF;
END
GO
