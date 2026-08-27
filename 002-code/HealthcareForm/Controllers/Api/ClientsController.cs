using HealthcareForm.Contracts.Clients;
using HealthcareForm.Security;
using HealthcareForm.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace HealthcareForm.Controllers.Api;

[ApiController]
[Authorize(Policy = AuthorizationPolicies.AdminAccess)]
[Produces("application/json")]
[Route("api/clients")]
public sealed class ClientsController : ControllerBase
{
    private readonly IClientDirectoryService _clientDirectoryService;

    public ClientsController(IClientDirectoryService clientDirectoryService)
    {
        _clientDirectoryService = clientDirectoryService;
    }

    [HttpPost]
    [ProducesResponseType(typeof(ClientCommandResult), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ClientCommandResult), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ClientCommandResult), StatusCodes.Status409Conflict)]
    [ProducesResponseType(typeof(ClientCommandResult), StatusCodes.Status500InternalServerError)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ClientCommandResult>> CreateClient(
        [FromBody] ClientCreateRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _clientDirectoryService.AddClientAsync(request, ResolveActor(), cancellationToken);

        if (result.Success)
        {
            return CreatedAtAction(nameof(GetClient), new { clientId = result.ClientId }, result);
        }

        return result.StatusCode switch
        {
            1 => BadRequest(result),
            2 => Conflict(result),
            _ => StatusCode(StatusCodes.Status500InternalServerError, result)
        };
    }

    [HttpPost("{clientId:guid}/departments")]
    [ProducesResponseType(typeof(ClientDepartmentCommandResult), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ClientDepartmentCommandResult), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ClientDepartmentCommandResult), StatusCodes.Status409Conflict)]
    [ProducesResponseType(typeof(ClientDepartmentCommandResult), StatusCodes.Status500InternalServerError)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ClientDepartmentCommandResult>> CreateDepartment(
        Guid clientId,
        [FromBody] ClientDepartmentCreateRequest request,
        CancellationToken cancellationToken)
    {
        if (clientId == Guid.Empty)
        {
            return BadRequest(new { Message = "Please provide a valid client ID." });
        }

        var result = await _clientDirectoryService.AddClientDepartmentAsync(clientId, request, ResolveActor(), cancellationToken);
        if (result.Success)
        {
            return StatusCode(StatusCodes.Status201Created, result);
        }

        return result.StatusCode switch
        {
            1 => BadRequest(result),
            2 => Conflict(result),
            _ => StatusCode(StatusCodes.Status500InternalServerError, result)
        };
    }

    [HttpPost("{clientId:guid}/staff")]
    [ProducesResponseType(typeof(ClientStaffCommandResult), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ClientStaffCommandResult), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ClientStaffCommandResult), StatusCodes.Status409Conflict)]
    [ProducesResponseType(typeof(ClientStaffCommandResult), StatusCodes.Status500InternalServerError)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ClientStaffCommandResult>> CreateStaff(
        Guid clientId,
        [FromBody] ClientStaffCreateRequest request,
        CancellationToken cancellationToken)
    {
        if (clientId == Guid.Empty)
        {
            return BadRequest(new { Message = "Please provide a valid client ID." });
        }

        var result = await _clientDirectoryService.AddClientStaffAsync(clientId, request, ResolveActor(), cancellationToken);
        if (result.Success)
        {
            return CreatedAtAction(nameof(GetStaffRecord), new { clientStaffId = result.ClientStaffId, includeDeleted = true }, result);
        }

        return result.StatusCode switch
        {
            1 => BadRequest(result),
            2 => Conflict(result),
            _ => StatusCode(StatusCodes.Status500InternalServerError, result)
        };
    }

    [HttpPut("{clientId:guid}")]
    [ProducesResponseType(typeof(ClientCommandResult), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ClientCommandResult), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ClientCommandResult), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ClientCommandResult), StatusCodes.Status409Conflict)]
    [ProducesResponseType(typeof(ClientCommandResult), StatusCodes.Status500InternalServerError)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ClientCommandResult>> UpdateClient(
        Guid clientId,
        [FromBody] ClientUpdateRequest request,
        CancellationToken cancellationToken)
    {
        if (clientId == Guid.Empty)
        {
            return BadRequest(new { Message = "Please provide a valid client ID." });
        }

        var result = await _clientDirectoryService.UpdateClientAsync(clientId, request, ResolveActor(), cancellationToken);

        if (result.Success)
        {
            return Ok(result);
        }

        if (result.StatusCode == 2)
        {
            return Conflict(result);
        }

        if (result.StatusCode == 1
            && result.Message.StartsWith("Client not found", StringComparison.OrdinalIgnoreCase))
        {
            return NotFound(result);
        }

        return result.StatusCode switch
        {
            1 => BadRequest(result),
            _ => StatusCode(StatusCodes.Status500InternalServerError, result)
        };
    }

    [HttpPut("departments/{clientDepartmentId:guid}")]
    [ProducesResponseType(typeof(ClientDepartmentCommandResult), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ClientDepartmentCommandResult), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ClientDepartmentCommandResult), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ClientDepartmentCommandResult), StatusCodes.Status409Conflict)]
    [ProducesResponseType(typeof(ClientDepartmentCommandResult), StatusCodes.Status500InternalServerError)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ClientDepartmentCommandResult>> UpdateDepartment(
        Guid clientDepartmentId,
        [FromBody] ClientDepartmentUpdateRequest request,
        CancellationToken cancellationToken)
    {
        if (clientDepartmentId == Guid.Empty)
        {
            return BadRequest(new { Message = "Please provide a valid client department ID." });
        }

        var result = await _clientDirectoryService.UpdateClientDepartmentAsync(clientDepartmentId, request, ResolveActor(), cancellationToken);
        if (result.Success)
        {
            return Ok(result);
        }

        if (result.StatusCode == 2)
        {
            return Conflict(result);
        }

        if (result.Message.Contains("not found", StringComparison.OrdinalIgnoreCase)
            || result.Message.Contains("already deleted", StringComparison.OrdinalIgnoreCase))
        {
            return NotFound(result);
        }

        return result.StatusCode switch
        {
            1 => BadRequest(result),
            _ => StatusCode(StatusCodes.Status500InternalServerError, result)
        };
    }

    [HttpPut("staff/{clientStaffId:guid}")]
    [ProducesResponseType(typeof(ClientStaffCommandResult), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ClientStaffCommandResult), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ClientStaffCommandResult), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ClientStaffCommandResult), StatusCodes.Status409Conflict)]
    [ProducesResponseType(typeof(ClientStaffCommandResult), StatusCodes.Status500InternalServerError)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ClientStaffCommandResult>> UpdateStaff(
        Guid clientStaffId,
        [FromBody] ClientStaffUpdateRequest request,
        CancellationToken cancellationToken)
    {
        if (clientStaffId == Guid.Empty)
        {
            return BadRequest(new { Message = "Please provide a valid client staff ID." });
        }

        var result = await _clientDirectoryService.UpdateClientStaffAsync(clientStaffId, request, ResolveActor(), cancellationToken);
        if (result.Success)
        {
            return Ok(result);
        }

        if (result.StatusCode == 2)
        {
            return Conflict(result);
        }

        if (result.Message.Contains("not found", StringComparison.OrdinalIgnoreCase)
            || result.Message.Contains("already deleted", StringComparison.OrdinalIgnoreCase))
        {
            return NotFound(result);
        }

        return result.StatusCode switch
        {
            1 => BadRequest(result),
            _ => StatusCode(StatusCodes.Status500InternalServerError, result)
        };
    }

    [HttpDelete("{clientId:guid}")]
    [ProducesResponseType(typeof(ClientCommandResult), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ClientCommandResult), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ClientCommandResult), StatusCodes.Status500InternalServerError)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ClientCommandResult>> DeleteClient(
        Guid clientId,
        CancellationToken cancellationToken)
    {
        if (clientId == Guid.Empty)
        {
            return BadRequest(new { Message = "Please provide a valid client ID." });
        }

        var result = await _clientDirectoryService.DeleteClientAsync(clientId, ResolveActor(), cancellationToken);
        if (result.Success)
        {
            return Ok(result);
        }

        if (result.Message.StartsWith("Unable to delete", StringComparison.OrdinalIgnoreCase))
        {
            return StatusCode(StatusCodes.Status500InternalServerError, result);
        }

        if (result.Message.Contains("does not exist", StringComparison.OrdinalIgnoreCase)
            || result.Message.Contains("already deleted", StringComparison.OrdinalIgnoreCase)
            || result.Message.StartsWith("Client not found", StringComparison.OrdinalIgnoreCase))
        {
            return NotFound(result);
        }

        return BadRequest(result);
    }

    [HttpDelete("departments/{clientDepartmentId:guid}")]
    [ProducesResponseType(typeof(ClientDepartmentCommandResult), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ClientDepartmentCommandResult), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ClientDepartmentCommandResult), StatusCodes.Status409Conflict)]
    [ProducesResponseType(typeof(ClientDepartmentCommandResult), StatusCodes.Status500InternalServerError)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ClientDepartmentCommandResult>> DeleteDepartment(
        Guid clientDepartmentId,
        CancellationToken cancellationToken)
    {
        if (clientDepartmentId == Guid.Empty)
        {
            return BadRequest(new { Message = "Please provide a valid client department ID." });
        }

        var result = await _clientDirectoryService.DeleteClientDepartmentAsync(clientDepartmentId, ResolveActor(), cancellationToken);
        if (result.Success)
        {
            return Ok(result);
        }

        if (result.StatusCode == 2)
        {
            return Conflict(result);
        }

        if (result.Message.Contains("not found", StringComparison.OrdinalIgnoreCase)
            || result.Message.Contains("already deleted", StringComparison.OrdinalIgnoreCase))
        {
            return NotFound(result);
        }

        if (result.Message.StartsWith("Unable to delete", StringComparison.OrdinalIgnoreCase))
        {
            return StatusCode(StatusCodes.Status500InternalServerError, result);
        }

        return BadRequest(result);
    }

    [HttpDelete("staff/{clientStaffId:guid}")]
    [ProducesResponseType(typeof(ClientStaffCommandResult), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ClientStaffCommandResult), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ClientStaffCommandResult), StatusCodes.Status500InternalServerError)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ClientStaffCommandResult>> DeleteStaff(
        Guid clientStaffId,
        CancellationToken cancellationToken)
    {
        if (clientStaffId == Guid.Empty)
        {
            return BadRequest(new { Message = "Please provide a valid client staff ID." });
        }

        var result = await _clientDirectoryService.DeleteClientStaffAsync(clientStaffId, ResolveActor(), cancellationToken);
        if (result.Success)
        {
            return Ok(result);
        }

        if (result.Message.StartsWith("Unable to delete", StringComparison.OrdinalIgnoreCase))
        {
            return StatusCode(StatusCodes.Status500InternalServerError, result);
        }

        if (result.Message.Contains("not found", StringComparison.OrdinalIgnoreCase)
            || result.Message.Contains("already deleted", StringComparison.OrdinalIgnoreCase))
        {
            return NotFound(result);
        }

        return BadRequest(result);
    }

    [HttpGet("{clientId:guid}")]
    [ProducesResponseType(typeof(ClientRecordDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ClientLookupResult), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ClientLookupResult), StatusCodes.Status500InternalServerError)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ClientRecordDto>> GetClient(
        Guid clientId,
        [FromQuery] bool includeDeleted,
        CancellationToken cancellationToken)
    {
        if (clientId == Guid.Empty)
        {
            return BadRequest(new { Message = "Please provide a valid client ID." });
        }

        var result = await _clientDirectoryService.GetClientAsync(clientId, includeDeleted, cancellationToken);
        if (!result.Found)
        {
            if (result.Message.StartsWith("Unable to retrieve", StringComparison.OrdinalIgnoreCase)
                || result.Message.StartsWith("Failed to retrieve", StringComparison.OrdinalIgnoreCase))
            {
                return StatusCode(StatusCodes.Status500InternalServerError, result);
            }

            return NotFound(result);
        }

        return Ok(result.Client);
    }

    [HttpGet("staff/{clientStaffId:guid}")]
    [ProducesResponseType(typeof(ClientStaffDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ClientStaffLookupResult), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ClientStaffLookupResult), StatusCodes.Status500InternalServerError)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ClientStaffDto>> GetStaffRecord(
        Guid clientStaffId,
        [FromQuery] bool includeDeleted,
        CancellationToken cancellationToken)
    {
        if (clientStaffId == Guid.Empty)
        {
            return BadRequest(new { Message = "Please provide a valid client staff ID." });
        }

        var result = await _clientDirectoryService.GetClientStaffRecordAsync(clientStaffId, includeDeleted, cancellationToken);
        if (!result.Found)
        {
            if (result.Message.StartsWith("Unable to retrieve", StringComparison.OrdinalIgnoreCase)
                || result.Message.StartsWith("Failed to retrieve", StringComparison.OrdinalIgnoreCase))
            {
                return StatusCode(StatusCodes.Status500InternalServerError, result);
            }

            return NotFound(result);
        }

        return Ok(result.Staff);
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

    private string ResolveActor()
    {
        var principal = User;
        var actor =
            principal?.FindFirstValue("name")
            ?? principal?.FindFirstValue(ClaimTypes.Name)
            ?? principal?.Identity?.Name;

        if (!string.IsNullOrWhiteSpace(actor))
        {
            return actor.Trim();
        }

        return "API";
    }
}
