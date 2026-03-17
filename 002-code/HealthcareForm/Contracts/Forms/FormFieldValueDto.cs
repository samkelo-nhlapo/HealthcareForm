namespace HealthcareForm.Contracts.Forms;

public sealed class FormFieldValueDto
{
    public Guid FormFieldValueId { get; init; }
    public Guid FormSubmissionId { get; init; }
    public string FieldName { get; init; } = string.Empty;
    public string FieldType { get; init; } = string.Empty;
    public string FieldValue { get; init; } = string.Empty;
    public int? DisplayOrder { get; init; }
    public bool IsRequired { get; init; }
    public string ValidationRules { get; init; } = string.Empty;
    public DateTime? UpdatedDate { get; init; }
}
