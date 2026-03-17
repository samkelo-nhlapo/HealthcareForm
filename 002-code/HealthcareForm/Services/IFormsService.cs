using HealthcareForm.Contracts.Forms;

namespace HealthcareForm.Services;

public interface IFormsService
{
    Task<IReadOnlyList<FormFieldValueDto>> GetFormFieldValuesAsync(Guid formSubmissionId, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<FormAttachmentDto>> GetFormAttachmentsAsync(Guid formSubmissionId, CancellationToken cancellationToken = default);
}
