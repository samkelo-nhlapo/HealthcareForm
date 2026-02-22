using HealthcareForm.Contracts.Operations;
using HealthcareForm.Security;
using HealthcareForm.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace HealthcareForm.Controllers.Api;

[ApiController]
[Authorize(Policy = AuthorizationPolicies.OperationsAccess)]
[Route("api/operations")]
public sealed class OperationsController : ControllerBase
{
    private readonly IOperationsService _operationsService;

    public OperationsController(IOperationsService operationsService)
    {
        _operationsService = operationsService;
    }

    [HttpGet("scheduling")]
    public async Task<ActionResult<SchedulingSnapshotDto>> GetSchedulingSnapshot(CancellationToken cancellationToken)
        => Ok(await _operationsService.GetSchedulingSnapshotAsync(cancellationToken));
}
