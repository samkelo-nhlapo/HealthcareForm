using HealthcareForm.Contracts.Revenue;

namespace HealthcareForm.Services;

// Revenue dashboard queries used by the billing API.
public interface IRevenueService
{
    // Builds the current claims snapshot.
    Task<RevenueClaimsSnapshotDto> GetClaimsSnapshotAsync(CancellationToken cancellationToken = default);
}
