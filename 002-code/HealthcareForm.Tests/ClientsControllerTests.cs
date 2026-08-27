using HealthcareForm.Contracts.Clients;
using HealthcareForm.Controllers.Api;
using HealthcareForm.Services;
using Microsoft.AspNetCore.Mvc;
using System.ComponentModel.DataAnnotations;

namespace HealthcareForm.Tests;

public sealed class ClientsControllerTests
{
    [Fact]
    public async Task CreateClient_ReturnsCreated_WhenServiceSucceeds()
    {
        var createdClientId = Guid.NewGuid();
        var controller = new ClientsController(new FakeClientDirectoryService
        {
            CreateResult = new ClientCommandResult
            {
                Success = true,
                Message = string.Empty,
                StatusCode = 0,
                ClientId = createdClientId
            }
        });

        var result = await controller.CreateClient(new ClientCreateRequest
        {
            ClientCode = "CLI-001",
            FirstName = "Hope",
            LastName = "Clinic"
        }, CancellationToken.None);

        var created = Assert.IsType<CreatedAtActionResult>(result.Result);
        Assert.Equal(nameof(ClientsController.GetClient), created.ActionName);
        var payload = Assert.IsType<ClientCommandResult>(created.Value);
        Assert.True(payload.Success);
        Assert.Equal(createdClientId, payload.ClientId);
    }

    [Fact]
    public async Task CreateClient_ReturnsConflict_WhenServiceReportsDuplicate()
    {
        var controller = new ClientsController(new FakeClientDirectoryService
        {
            CreateResult = new ClientCommandResult
            {
                Success = false,
                Message = "ClientCode already exists.",
                StatusCode = 2,
                ClientId = null
            }
        });

        var result = await controller.CreateClient(new ClientCreateRequest
        {
            ClientCode = "CLI-001",
            FirstName = "Hope",
            LastName = "Clinic"
        }, CancellationToken.None);

        var conflict = Assert.IsType<ConflictObjectResult>(result.Result);
        var payload = Assert.IsType<ClientCommandResult>(conflict.Value);
        Assert.False(payload.Success);
        Assert.Equal(2, payload.StatusCode);
    }

    [Fact]
    public async Task CreateDepartment_ReturnsCreated_WhenServiceSucceeds()
    {
        var departmentId = Guid.NewGuid();
        var controller = new ClientsController(new FakeClientDirectoryService
        {
            DepartmentCreateResult = new ClientDepartmentCommandResult
            {
                Success = true,
                Message = string.Empty,
                StatusCode = 0,
                ClientDepartmentId = departmentId
            }
        });

        var result = await controller.CreateDepartment(Guid.NewGuid(), new ClientDepartmentCreateRequest
        {
            DepartmentName = "Radiology",
            DepartmentType = "Clinical"
        }, CancellationToken.None);

        var created = Assert.IsType<ObjectResult>(result.Result);
        Assert.Equal(201, created.StatusCode);
        var payload = Assert.IsType<ClientDepartmentCommandResult>(created.Value);
        Assert.True(payload.Success);
        Assert.Equal(departmentId, payload.ClientDepartmentId);
    }

    [Fact]
    public async Task CreateStaff_ReturnsCreated_WhenServiceSucceeds()
    {
        var clientStaffId = Guid.NewGuid();
        var controller = new ClientsController(new FakeClientDirectoryService
        {
            StaffCreateResult = new ClientStaffCommandResult
            {
                Success = true,
                Message = string.Empty,
                StatusCode = 0,
                ClientStaffId = clientStaffId
            }
        });

        var result = await controller.CreateStaff(Guid.NewGuid(), new ClientStaffCreateRequest
        {
            StaffCode = "STF-001",
            FirstName = "Avery",
            LastName = "Moyo",
            StaffType = "Administrative",
            EmploymentType = "Full-Time"
        }, CancellationToken.None);

        var created = Assert.IsType<CreatedAtActionResult>(result.Result);
        Assert.Equal(nameof(ClientsController.GetStaffRecord), created.ActionName);
        var payload = Assert.IsType<ClientStaffCommandResult>(created.Value);
        Assert.True(payload.Success);
        Assert.Equal(clientStaffId, payload.ClientStaffId);
    }

    [Fact]
    public async Task UpdateClient_ReturnsOk_WhenServiceSucceeds()
    {
        var clientId = Guid.NewGuid();
        var controller = new ClientsController(new FakeClientDirectoryService
        {
            UpdateResult = new ClientCommandResult
            {
                Success = true,
                Message = string.Empty,
                StatusCode = 0,
                ClientId = clientId
            }
        });

        var result = await controller.UpdateClient(clientId, new ClientUpdateRequest
        {
            ClientCode = "CLI-001",
            FirstName = "Hope",
            LastName = "Clinic",
            IsActive = true
        }, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var payload = Assert.IsType<ClientCommandResult>(ok.Value);
        Assert.True(payload.Success);
        Assert.Equal(clientId, payload.ClientId);
    }

    [Fact]
    public async Task UpdateClient_ReturnsNotFound_WhenServiceReportsMissingRecord()
    {
        var controller = new ClientsController(new FakeClientDirectoryService
        {
            UpdateResult = new ClientCommandResult
            {
                Success = false,
                Message = "Client not found or already deleted.",
                StatusCode = 1,
                ClientId = null
            }
        });

        var result = await controller.UpdateClient(Guid.NewGuid(), new ClientUpdateRequest
        {
            ClientCode = "CLI-001",
            FirstName = "Hope",
            LastName = "Clinic",
            IsActive = true
        }, CancellationToken.None);

        var notFound = Assert.IsType<NotFoundObjectResult>(result.Result);
        var payload = Assert.IsType<ClientCommandResult>(notFound.Value);
        Assert.False(payload.Success);
    }

    [Fact]
    public async Task DeleteClient_ReturnsOk_WhenServiceSucceeds()
    {
        var clientId = Guid.NewGuid();
        var controller = new ClientsController(new FakeClientDirectoryService
        {
            DeleteResult = new ClientCommandResult
            {
                Success = true,
                Message = string.Empty,
                StatusCode = 0,
                ClientId = clientId
            }
        });

        var result = await controller.DeleteClient(clientId, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var payload = Assert.IsType<ClientCommandResult>(ok.Value);
        Assert.True(payload.Success);
        Assert.Equal(clientId, payload.ClientId);
    }

    [Fact]
    public async Task DeleteClient_ReturnsNotFound_WhenServiceReportsMissingRecord()
    {
        var controller = new ClientsController(new FakeClientDirectoryService
        {
            DeleteResult = new ClientCommandResult
            {
                Success = false,
                Message = "Client does not exist or is already deleted.",
                StatusCode = 1,
                ClientId = null
            }
        });

        var result = await controller.DeleteClient(Guid.NewGuid(), CancellationToken.None);

        var notFound = Assert.IsType<NotFoundObjectResult>(result.Result);
        var payload = Assert.IsType<ClientCommandResult>(notFound.Value);
        Assert.False(payload.Success);
    }

    [Fact]
    public async Task DeleteDepartment_ReturnsConflict_WhenServiceReportsAssignedStaff()
    {
        var controller = new ClientsController(new FakeClientDirectoryService
        {
            DepartmentDeleteResult = new ClientDepartmentCommandResult
            {
                Success = false,
                Message = "Department cannot be deleted while staff are assigned to it.",
                StatusCode = 2,
                ClientDepartmentId = null
            }
        });

        var result = await controller.DeleteDepartment(Guid.NewGuid(), CancellationToken.None);

        var conflict = Assert.IsType<ConflictObjectResult>(result.Result);
        var payload = Assert.IsType<ClientDepartmentCommandResult>(conflict.Value);
        Assert.False(payload.Success);
        Assert.Equal(2, payload.StatusCode);
    }

    [Fact]
    public async Task GetClient_ReturnsBadRequest_WhenClientIdIsEmpty()
    {
        var controller = new ClientsController(new FakeClientDirectoryService());

        var result = await controller.GetClient(Guid.Empty, includeDeleted: false, CancellationToken.None);

        var badRequest = Assert.IsType<BadRequestObjectResult>(result.Result);
        Assert.Equal(400, badRequest.StatusCode);
    }

    [Fact]
    public async Task GetClient_ReturnsOk_WhenServiceSucceeds()
    {
        var controller = new ClientsController(new FakeClientDirectoryService
        {
            LookupResult = new ClientLookupResult
            {
                Found = true,
                Client = new ClientRecordDto
                {
                    ClientId = Guid.NewGuid(),
                    ClientCode = "CLI-001",
                    FirstName = "Hope",
                    LastName = "Clinic"
                }
            }
        });

        var result = await controller.GetClient(Guid.NewGuid(), includeDeleted: false, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var payload = Assert.IsType<ClientRecordDto>(ok.Value);
        Assert.Equal("CLI-001", payload.ClientCode);
    }

    [Fact]
    public async Task GetClient_ReturnsNotFound_WhenServiceReturnsBusinessFailure()
    {
        var controller = new ClientsController(new FakeClientDirectoryService
        {
            LookupResult = new ClientLookupResult
            {
                Found = false,
                Message = "Client not found.",
                Client = null
            }
        });

        var result = await controller.GetClient(Guid.NewGuid(), includeDeleted: true, CancellationToken.None);

        var notFound = Assert.IsType<NotFoundObjectResult>(result.Result);
        var payload = Assert.IsType<ClientLookupResult>(notFound.Value);
        Assert.False(payload.Found);
    }

    [Fact]
    public async Task GetStaffRecord_ReturnsOk_WhenServiceSucceeds()
    {
        var controller = new ClientsController(new FakeClientDirectoryService
        {
            StaffLookupResult = new ClientStaffLookupResult
            {
                Found = true,
                Staff = new ClientStaffDto
                {
                    ClientStaffId = Guid.NewGuid(),
                    StaffCode = "STF-001",
                    FirstName = "Avery",
                    LastName = "Moyo"
                }
            }
        });

        var result = await controller.GetStaffRecord(Guid.NewGuid(), includeDeleted: true, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var payload = Assert.IsType<ClientStaffDto>(ok.Value);
        Assert.Equal("STF-001", payload.StaffCode);
    }

    [Fact]
    public void ClientCreateRequest_FailsValidation_ForPartialAddress()
    {
        var request = new ClientCreateRequest
        {
            ClientCode = "CLI-001",
            FirstName = "Hope",
            LastName = "Clinic",
            Line1 = "1 Main Road"
        };

        var validationResults = Validate(request);

        Assert.Contains(validationResults, (result) => result.MemberNames.Contains(nameof(ClientCreateRequest.Line2)));
        Assert.Contains(validationResults, (result) => result.MemberNames.Contains(nameof(ClientCreateRequest.CityId)));
    }

    [Fact]
    public void ClientCreateRequest_PassesValidation_WhenAddressIsComplete()
    {
        var request = new ClientCreateRequest
        {
            ClientCode = "CLI-001",
            FirstName = "Hope",
            LastName = "Clinic",
            Line1 = "1 Main Road",
            Line2 = "Reception",
            CityId = 1
        };

        var validationResults = Validate(request);

        Assert.Empty(validationResults);
    }

    [Fact]
    public void ClientUpdateRequest_FailsValidation_ForPartialAddress()
    {
        var request = new ClientUpdateRequest
        {
            ClientCode = "CLI-001",
            FirstName = "Hope",
            LastName = "Clinic",
            IsActive = true,
            Line2 = "Reception"
        };

        var validationResults = Validate(request);

        Assert.Contains(validationResults, (result) => result.MemberNames.Contains(nameof(ClientUpdateRequest.Line1)));
        Assert.Contains(validationResults, (result) => result.MemberNames.Contains(nameof(ClientUpdateRequest.CityId)));
    }

    private static List<ValidationResult> Validate(object instance)
    {
        var validationResults = new List<ValidationResult>();
        Validator.TryValidateObject(instance, new ValidationContext(instance), validationResults, validateAllProperties: true);
        return validationResults;
    }

    private sealed class FakeClientDirectoryService : IClientDirectoryService
    {
        public ClientCommandResult CreateResult { get; init; } = new()
        {
            Success = false,
            Message = "Not configured.",
            StatusCode = null,
            ClientId = null
        };

        public ClientCommandResult UpdateResult { get; init; } = new()
        {
            Success = false,
            Message = "Not configured.",
            StatusCode = null,
            ClientId = null
        };

        public ClientDepartmentCommandResult DepartmentCreateResult { get; init; } = new()
        {
            Success = false,
            Message = "Not configured.",
            StatusCode = null,
            ClientDepartmentId = null
        };

        public ClientDepartmentCommandResult DepartmentUpdateResult { get; init; } = new()
        {
            Success = false,
            Message = "Not configured.",
            StatusCode = null,
            ClientDepartmentId = null
        };

        public ClientDepartmentCommandResult DepartmentDeleteResult { get; init; } = new()
        {
            Success = false,
            Message = "Not configured.",
            StatusCode = null,
            ClientDepartmentId = null
        };

        public ClientStaffCommandResult StaffCreateResult { get; init; } = new()
        {
            Success = false,
            Message = "Not configured.",
            StatusCode = null,
            ClientStaffId = null
        };

        public ClientStaffCommandResult StaffUpdateResult { get; init; } = new()
        {
            Success = false,
            Message = "Not configured.",
            StatusCode = null,
            ClientStaffId = null
        };

        public ClientStaffCommandResult StaffDeleteResult { get; init; } = new()
        {
            Success = false,
            Message = "Not configured.",
            StatusCode = null,
            ClientStaffId = null
        };

        public ClientLookupResult LookupResult { get; init; } = new()
        {
            Found = false,
            Message = "Not configured.",
            Client = null
        };

        public ClientStaffLookupResult StaffLookupResult { get; init; } = new()
        {
            Found = false,
            Message = "Not configured.",
            Staff = null
        };

        public ClientCommandResult DeleteResult { get; init; } = new()
        {
            Success = false,
            Message = "Not configured.",
            StatusCode = null,
            ClientId = null
        };

        public Task<ClientCommandResult> AddClientAsync(
            ClientCreateRequest request,
            string actor,
            CancellationToken cancellationToken = default)
            => Task.FromResult(CreateResult);

        public Task<ClientCommandResult> UpdateClientAsync(
            Guid clientId,
            ClientUpdateRequest request,
            string actor,
            CancellationToken cancellationToken = default)
            => Task.FromResult(UpdateResult);

        public Task<ClientDepartmentCommandResult> AddClientDepartmentAsync(
            Guid clientId,
            ClientDepartmentCreateRequest request,
            string actor,
            CancellationToken cancellationToken = default)
            => Task.FromResult(DepartmentCreateResult);

        public Task<ClientStaffCommandResult> AddClientStaffAsync(
            Guid clientId,
            ClientStaffCreateRequest request,
            string actor,
            CancellationToken cancellationToken = default)
            => Task.FromResult(StaffCreateResult);

        public Task<ClientDepartmentCommandResult> UpdateClientDepartmentAsync(
            Guid clientDepartmentId,
            ClientDepartmentUpdateRequest request,
            string actor,
            CancellationToken cancellationToken = default)
            => Task.FromResult(DepartmentUpdateResult);

        public Task<ClientStaffCommandResult> UpdateClientStaffAsync(
            Guid clientStaffId,
            ClientStaffUpdateRequest request,
            string actor,
            CancellationToken cancellationToken = default)
            => Task.FromResult(StaffUpdateResult);

        public Task<ClientCommandResult> DeleteClientAsync(
            Guid clientId,
            string actor,
            CancellationToken cancellationToken = default)
            => Task.FromResult(DeleteResult);

        public Task<ClientDepartmentCommandResult> DeleteClientDepartmentAsync(
            Guid clientDepartmentId,
            string actor,
            CancellationToken cancellationToken = default)
            => Task.FromResult(DepartmentDeleteResult);

        public Task<ClientStaffCommandResult> DeleteClientStaffAsync(
            Guid clientStaffId,
            string actor,
            CancellationToken cancellationToken = default)
            => Task.FromResult(StaffDeleteResult);

        public Task<IReadOnlyList<ClientClinicCategoryDto>> GetClinicCategoriesAsync(
            ClientClinicCategoryQueryDto query,
            CancellationToken cancellationToken = default)
            => throw new NotImplementedException();

        public Task<ClientLookupResult> GetClientAsync(
            Guid clientId,
            bool includeDeleted,
            CancellationToken cancellationToken = default)
            => Task.FromResult(LookupResult);

        public Task<ClientDirectorySnapshotDto> GetClientsAsync(
            ClientDirectoryQueryDto query,
            CancellationToken cancellationToken = default)
            => throw new NotImplementedException();

        public Task<ClientDepartmentSnapshotDto> GetClientDepartmentsAsync(
            ClientDepartmentQueryDto query,
            CancellationToken cancellationToken = default)
            => throw new NotImplementedException();

        public Task<ClientStaffSnapshotDto> GetClientStaffAsync(
            ClientStaffQueryDto query,
            CancellationToken cancellationToken = default)
            => throw new NotImplementedException();

        public Task<ClientStaffLookupResult> GetClientStaffRecordAsync(
            Guid clientStaffId,
            bool includeDeleted,
            CancellationToken cancellationToken = default)
            => Task.FromResult(StaffLookupResult);
    }
}
