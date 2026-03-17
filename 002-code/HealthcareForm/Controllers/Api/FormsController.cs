using HealthcareForm.Contracts.Forms;
using HealthcareForm.Security;
using HealthcareForm.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace HealthcareForm.Controllers.Api;

[ApiController]
[Authorize(Policy = AuthorizationPolicies.PatientsRead)]
[Route("api/forms")]
public sealed class FormsController : ControllerBase
{
    private readonly IFormsService _formsService;

    public FormsController(IFormsService formsService)
    {
        _formsService = formsService;
    }

    [HttpGet("submissions/{submissionId:guid}/fields")]
    public async Task<ActionResult<IReadOnlyList<FormFieldValueDto>>> GetFormFieldValues(Guid submissionId, CancellationToken cancellationToken)
    {
        if (submissionId == Guid.Empty)
        {
            return BadRequest(new { Message = "Please provide a submission ID." });
        }

        return Ok(await _formsService.GetFormFieldValuesAsync(submissionId, cancellationToken));
    }

    [HttpGet("submissions/{submissionId:guid}/attachments")]
    public async Task<ActionResult<IReadOnlyList<FormAttachmentDto>>> GetFormAttachments(Guid submissionId, CancellationToken cancellationToken)
    {
        if (submissionId == Guid.Empty)
        {
            return BadRequest(new { Message = "Please provide a submission ID." });
        }

        return Ok(await _formsService.GetFormAttachmentsAsync(submissionId, cancellationToken));
    }
}
