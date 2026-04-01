using HealthcareForm.Contracts.Operations;
using HealthcareForm.Security;
using HealthcareForm.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace HealthcareForm.Controllers.Api;

// Read-only operational endpoints used by the scheduling and task-queue views.
[ApiController]
[Authorize(Policy = AuthorizationPolicies.OperationsAccess)]
[Produces("application/json")]
[Route("api/operations")]
public sealed class OperationsController : ControllerBase
{
    private readonly IOperationsService _operationsService;

    public OperationsController(IOperationsService operationsService)
    {
        _operationsService = operationsService;
    }

    // Returns the current scheduling snapshot for provider, resource, and time-block views.
    [HttpGet("scheduling")]
    [ProducesResponseType(typeof(SchedulingSnapshotDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<SchedulingSnapshotDto>> GetSchedulingSnapshot(CancellationToken cancellationToken)
        => Ok(await _operationsService.GetSchedulingSnapshotAsync(cancellationToken));

    // Returns the current operational task queue with SLA-focused ordering.
    [HttpGet("task-queue")]
    [ProducesResponseType(typeof(TaskQueueSnapshotDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<TaskQueueSnapshotDto>> GetTaskQueueSnapshot(CancellationToken cancellationToken)
        => Ok(await _operationsService.GetTaskQueueSnapshotAsync(cancellationToken));
}
