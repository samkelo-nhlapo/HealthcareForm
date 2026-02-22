using HealthcareForm.Contracts.Admin;
using HealthcareForm.Security;
using HealthcareForm.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace HealthcareForm.Controllers.Api;

[ApiController]
[Authorize(Policy = AuthorizationPolicies.AdminAccess)]
[Route("api/admin")]
public sealed class AdminController : ControllerBase
{
    private readonly IAdminService _adminService;

    public AdminController(IAdminService adminService)
    {
        _adminService = adminService;
    }

    [HttpGet("access-control")]
    public async Task<ActionResult<AdminAccessControlSnapshotDto>> GetAccessControlSnapshot(CancellationToken cancellationToken)
        => Ok(await _adminService.GetAccessControlAsync(cancellationToken));

    [HttpGet("audit-log")]
    public async Task<ActionResult<AdminAuditLogSnapshotDto>> GetAuditLogSnapshot(
        [FromQuery] AdminAuditLogQueryDto? query,
        CancellationToken cancellationToken)
        => Ok(await _adminService.GetAuditLogAsync(query ?? new AdminAuditLogQueryDto(), cancellationToken));

    [HttpGet("data-governance")]
    public async Task<ActionResult<AdminDataGovernanceSnapshotDto>> GetDataGovernanceSnapshot(CancellationToken cancellationToken)
        => Ok(await _adminService.GetDataGovernanceAsync(cancellationToken));
}
