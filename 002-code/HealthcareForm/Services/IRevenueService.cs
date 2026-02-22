using HealthcareForm.Contracts.Revenue;

namespace HealthcareForm.Services;

public interface IRevenueService
{
    Task<RevenueClaimsSnapshotDto> GetClaimsSnapshotAsync(CancellationToken cancellationToken = default);
}
