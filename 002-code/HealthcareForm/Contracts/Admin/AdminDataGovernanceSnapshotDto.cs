namespace HealthcareForm.Contracts.Admin;

// Snapshot returned by the admin data-governance endpoint.
public sealed class AdminDataGovernanceSnapshotDto
{
    // Configuration checks surfaced to administrators.
    public IReadOnlyList<AdminConfigurationItemDto> ConfigurationItems { get; init; } = [];

    // Governance details for managed templates or forms.
    public IReadOnlyList<AdminTemplateGovernanceItemDto> TemplateItems { get; init; } = [];

    // Health details for supporting lookup data.
    public IReadOnlyList<AdminLookupHealthItemDto> LookupItems { get; init; } = [];
}
