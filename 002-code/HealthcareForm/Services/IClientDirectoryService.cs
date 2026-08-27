using HealthcareForm.Contracts.Clients;

namespace HealthcareForm.Services;

public interface IClientDirectoryService
{
    Task<ClientCommandResult> AddClientAsync(
        ClientCreateRequest request,
        string actor,
        CancellationToken cancellationToken = default);

    Task<ClientDepartmentCommandResult> AddClientDepartmentAsync(
        Guid clientId,
        ClientDepartmentCreateRequest request,
        string actor,
        CancellationToken cancellationToken = default);

    Task<ClientStaffCommandResult> AddClientStaffAsync(
        Guid clientId,
        ClientStaffCreateRequest request,
        string actor,
        CancellationToken cancellationToken = default);

    Task<ClientCommandResult> UpdateClientAsync(
        Guid clientId,
        ClientUpdateRequest request,
        string actor,
        CancellationToken cancellationToken = default);

    Task<ClientDepartmentCommandResult> UpdateClientDepartmentAsync(
        Guid clientDepartmentId,
        ClientDepartmentUpdateRequest request,
        string actor,
        CancellationToken cancellationToken = default);

    Task<ClientStaffCommandResult> UpdateClientStaffAsync(
        Guid clientStaffId,
        ClientStaffUpdateRequest request,
        string actor,
        CancellationToken cancellationToken = default);

    Task<ClientCommandResult> DeleteClientAsync(
        Guid clientId,
        string actor,
        CancellationToken cancellationToken = default);

    Task<ClientDepartmentCommandResult> DeleteClientDepartmentAsync(
        Guid clientDepartmentId,
        string actor,
        CancellationToken cancellationToken = default);

    Task<ClientStaffCommandResult> DeleteClientStaffAsync(
        Guid clientStaffId,
        string actor,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<ClientClinicCategoryDto>> GetClinicCategoriesAsync(
        ClientClinicCategoryQueryDto query,
        CancellationToken cancellationToken = default);

    Task<ClientLookupResult> GetClientAsync(
        Guid clientId,
        bool includeDeleted,
        CancellationToken cancellationToken = default);

    Task<ClientDirectorySnapshotDto> GetClientsAsync(
        ClientDirectoryQueryDto query,
        CancellationToken cancellationToken = default);

    Task<ClientDepartmentSnapshotDto> GetClientDepartmentsAsync(
        ClientDepartmentQueryDto query,
        CancellationToken cancellationToken = default);

    Task<ClientStaffSnapshotDto> GetClientStaffAsync(
        ClientStaffQueryDto query,
        CancellationToken cancellationToken = default);

    Task<ClientStaffLookupResult> GetClientStaffRecordAsync(
        Guid clientStaffId,
        bool includeDeleted,
        CancellationToken cancellationToken = default);
}
