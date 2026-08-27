using HealthcareForm.Contracts.Operations;
using HealthcareForm.Security;
using HealthcareForm.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace HealthcareForm.Controllers.Api;

// Operational endpoints used by the scheduling and task-queue views.
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

    // Returns client and provider booking options for appointment ingestion.
    [HttpGet("scheduling/booking-options")]
    [ProducesResponseType(typeof(SchedulingBookingOptionsDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<SchedulingBookingOptionsDto>> GetSchedulingBookingOptions(CancellationToken cancellationToken)
        => Ok(await _operationsService.GetSchedulingBookingOptionsAsync(cancellationToken));

    // Creates a new appointment row for live scheduling ingestion.
    [HttpPost("scheduling/appointments")]
    [ProducesResponseType(typeof(SchedulingAppointmentCommandResult), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(SchedulingAppointmentCommandResult), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(SchedulingAppointmentCommandResult), StatusCodes.Status409Conflict)]
    [ProducesResponseType(typeof(SchedulingAppointmentCommandResult), StatusCodes.Status500InternalServerError)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<SchedulingAppointmentCommandResult>> CreateSchedulingAppointment(
        [FromBody] SchedulingAppointmentCreateRequest request,
        CancellationToken cancellationToken)
    {
        var actor = User?.Identity?.Name ?? "SYSTEM";
        var result = await _operationsService.AddSchedulingAppointmentAsync(request, actor, cancellationToken);

        if (result.Success)
        {
            return Created("/api/operations/scheduling", result);
        }

        return result.StatusCode switch
        {
            1 => BadRequest(result),
            2 => Conflict(result),
            _ => StatusCode(StatusCodes.Status500InternalServerError, result)
        };
    }

    // Returns the current operational task queue with SLA-focused ordering.
    [HttpGet("task-queue")]
    [ProducesResponseType(typeof(TaskQueueSnapshotDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<TaskQueueSnapshotDto>> GetTaskQueueSnapshot(CancellationToken cancellationToken)
        => Ok(await _operationsService.GetTaskQueueSnapshotAsync(cancellationToken));
}
