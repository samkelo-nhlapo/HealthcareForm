namespace HealthcareForm.Contracts.Revenue;

// Snapshot returned by the revenue claims endpoint.
public sealed class RevenueClaimsSnapshotDto
{
    // Claims currently shown in the billing workspace.
    public IReadOnlyList<RevenueClaimRowDto> Claims { get; init; } = [];
}
