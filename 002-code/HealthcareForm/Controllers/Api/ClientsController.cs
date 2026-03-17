using HealthcareForm.Contracts.Clients;
using HealthcareForm.Security;
using HealthcareForm.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace HealthcareForm.Controllers.Api;

[ApiController]
[Authorize(Policy = AuthorizationPolicies.AdminAccess)]
[Route("api/clients")]
public sealed class ClientsController : ControllerBase
{
    private readonly IClientDirectoryService _clientDirectoryService;

    public ClientsController(IClientDirectoryService clientDirectoryService)
    {
        _clientDirectoryService = clientDirectoryService;
    }

    [HttpGet("clinic-categories")]
    public async Task<ActionResult<IReadOnlyList<ClientClinicCategoryDto>>> GetClinicCategories(
        [FromQuery] ClientClinicCategoryQueryDto? query,
        CancellationToken cancellationToken)
        => Ok(await _clientDirectoryService.GetClinicCategoriesAsync(query ?? new ClientClinicCategoryQueryDto(), cancellationToken));

    [HttpGet]
    public async Task<ActionResult<ClientDirectorySnapshotDto>> GetClients(
        [FromQuery] ClientDirectoryQueryDto? query,
        CancellationToken cancellationToken)
        => Ok(await _clientDirectoryService.GetClientsAsync(query ?? new ClientDirectoryQueryDto(), cancellationToken));

    [HttpGet("departments")]
    public async Task<ActionResult<ClientDepartmentSnapshotDto>> GetDepartments(
        [FromQuery] ClientDepartmentQueryDto? query,
        CancellationToken cancellationToken)
        => Ok(await _clientDirectoryService.GetClientDepartmentsAsync(query ?? new ClientDepartmentQueryDto(), cancellationToken));

    [HttpGet("staff")]
    public async Task<ActionResult<ClientStaffSnapshotDto>> GetStaff(
        [FromQuery] ClientStaffQueryDto? query,
        CancellationToken cancellationToken)
        => Ok(await _clientDirectoryService.GetClientStaffAsync(query ?? new ClientStaffQueryDto(), cancellationToken));
}
