using HealthcareForm.Contracts.Revenue;
using HealthcareForm.Security;
using HealthcareForm.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace HealthcareForm.Controllers.Api;

[ApiController]
[Authorize(Policy = AuthorizationPolicies.RevenueAccess)]
[Route("api/revenue")]
public sealed class RevenueController : ControllerBase
{
    private readonly IRevenueService _revenueService;

    public RevenueController(IRevenueService revenueService)
    {
        _revenueService = revenueService;
    }

    [HttpGet("claims")]
    public async Task<ActionResult<RevenueClaimsSnapshotDto>> GetClaimsSnapshot(CancellationToken cancellationToken)
        => Ok(await _revenueService.GetClaimsSnapshotAsync(cancellationToken));
}
