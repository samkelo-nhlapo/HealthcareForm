using HealthcareForm.Contracts.Admin;

namespace HealthcareForm.Services;

public interface IAdminService
{
    Task<AdminAccessControlSnapshotDto> GetAccessControlAsync(CancellationToken cancellationToken = default);
    Task<AdminAuditLogSnapshotDto> GetAuditLogAsync(AdminAuditLogQueryDto query, CancellationToken cancellationToken = default);
    Task<AdminDataGovernanceSnapshotDto> GetDataGovernanceAsync(CancellationToken cancellationToken = default);
}
