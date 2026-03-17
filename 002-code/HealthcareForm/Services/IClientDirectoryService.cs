using HealthcareForm.Contracts.Clients;

namespace HealthcareForm.Services;

public interface IClientDirectoryService
{
    Task<IReadOnlyList<ClientClinicCategoryDto>> GetClinicCategoriesAsync(
        ClientClinicCategoryQueryDto query,
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
}
