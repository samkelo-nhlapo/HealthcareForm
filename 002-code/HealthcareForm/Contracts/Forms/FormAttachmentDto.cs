namespace HealthcareForm.Contracts.Forms;

public sealed class FormAttachmentDto
{
    public Guid FormAttachmentId { get; init; }
    public Guid FormSubmissionId { get; init; }
    public string FileName { get; init; } = string.Empty;
    public string FileType { get; init; } = string.Empty;
    public long FileSizeBytes { get; init; }
    public string FileHash { get; init; } = string.Empty;
    public string StoragePath { get; init; } = string.Empty;
    public string DocumentType { get; init; } = string.Empty;
    public DateTime UploadedDate { get; init; }
    public string UploadedBy { get; init; } = string.Empty;
    public bool IsVerified { get; init; }
    public string VerifiedBy { get; init; } = string.Empty;
    public DateTime? VerificationDate { get; init; }
    public DateTime? ExpiryDate { get; init; }
    public string Notes { get; init; } = string.Empty;
    public DateTime? UpdatedDate { get; init; }
}
