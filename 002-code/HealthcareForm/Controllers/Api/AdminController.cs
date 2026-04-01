using HealthcareForm.Contracts.Admin;
using HealthcareForm.Security;
using HealthcareForm.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace HealthcareForm.Controllers.Api;

// Read-only endpoints that power the admin workspace.
// Every route in this controller uses AdminAccess and feeds dashboard-style admin screens.
[ApiController]
[Authorize(Policy = AuthorizationPolicies.AdminAccess)]
[Produces("application/json")]
[Route("api/admin")]
public sealed class AdminController : ControllerBase
{
    private readonly IAdminService _adminService;

    public AdminController(IAdminService adminService)
    {
        _adminService = adminService;
    }

    // Returns the current access-control snapshot for the admin console.
    [HttpGet("access-control")]
    [ProducesResponseType(typeof(AdminAccessControlSnapshotDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<AdminAccessControlSnapshotDto>> GetAccessControlSnapshot(CancellationToken cancellationToken)
        => Ok(await _adminService.GetAccessControlAsync(cancellationToken));

    // Returns a filtered audit-log snapshot for the admin console.
    [HttpGet("audit-log")]
    [ProducesResponseType(typeof(AdminAuditLogSnapshotDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<AdminAuditLogSnapshotDto>> GetAuditLogSnapshot(
        [FromQuery] AdminAuditLogQueryDto? query,
        CancellationToken cancellationToken)
        => Ok(await _adminService.GetAuditLogAsync(query ?? new AdminAuditLogQueryDto(), cancellationToken));

    // Returns configuration, template governance, and lookup health in one payload.
    [HttpGet("data-governance")]
    [ProducesResponseType(typeof(AdminDataGovernanceSnapshotDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<AdminDataGovernanceSnapshotDto>> GetDataGovernanceSnapshot(CancellationToken cancellationToken)
        => Ok(await _adminService.GetDataGovernanceAsync(cancellationToken));

    // Returns recent database errors for operational troubleshooting.
    [HttpGet("db-errors")]
    [ProducesResponseType(typeof(AdminDbErrorSnapshotDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<AdminDbErrorSnapshotDto>> GetDbErrorsSnapshot(
        [FromQuery] AdminDbErrorQueryDto? query,
        CancellationToken cancellationToken)
        => Ok(await _adminService.GetDbErrorsAsync(query ?? new AdminDbErrorQueryDto(), cancellationToken));
}
