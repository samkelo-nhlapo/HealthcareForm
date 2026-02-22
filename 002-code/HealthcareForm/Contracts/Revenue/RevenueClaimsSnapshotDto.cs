namespace HealthcareForm.Contracts.Revenue;

public sealed class RevenueClaimsSnapshotDto
{
    public IReadOnlyList<RevenueClaimRowDto> Claims { get; init; } = [];
}
