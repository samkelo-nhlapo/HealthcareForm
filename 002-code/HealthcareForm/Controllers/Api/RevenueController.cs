using HealthcareForm.Contracts.Revenue;
using HealthcareForm.Security;
using HealthcareForm.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace HealthcareForm.Controllers.Api;

// Read-only revenue endpoints used by billing and finance views.
[ApiController]
[Authorize(Policy = AuthorizationPolicies.RevenueAccess)]
[Produces("application/json")]
[Route("api/revenue")]
public sealed class RevenueController : ControllerBase
{
    private readonly IRevenueService _revenueService;

    public RevenueController(IRevenueService revenueService)
    {
        _revenueService = revenueService;
    }

    // Returns the current claims snapshot for the revenue workspace.
    [HttpGet("claims")]
    [ProducesResponseType(typeof(RevenueClaimsSnapshotDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<RevenueClaimsSnapshotDto>> GetClaimsSnapshot(CancellationToken cancellationToken)
        => Ok(await _revenueService.GetClaimsSnapshotAsync(cancellationToken));
}
