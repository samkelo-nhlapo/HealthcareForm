using HealthcareForm.Contracts.Admin;

namespace HealthcareForm.Services;

// Builds the snapshot payloads that drive the admin area.
public interface IAdminService
{
    // Builds the access-control view used by the admin workspace.
    Task<AdminAccessControlSnapshotDto> GetAccessControlAsync(CancellationToken cancellationToken = default);

    // Builds the filtered audit-log view used by the admin workspace.
    Task<AdminAuditLogSnapshotDto> GetAuditLogAsync(AdminAuditLogQueryDto query, CancellationToken cancellationToken = default);

    // Builds the data-governance view used by the admin workspace.
    Task<AdminDataGovernanceSnapshotDto> GetDataGovernanceAsync(CancellationToken cancellationToken = default);

    // Builds the database-error view used by the admin workspace.
    Task<AdminDbErrorSnapshotDto> GetDbErrorsAsync(AdminDbErrorQueryDto query, CancellationToken cancellationToken = default);
}
