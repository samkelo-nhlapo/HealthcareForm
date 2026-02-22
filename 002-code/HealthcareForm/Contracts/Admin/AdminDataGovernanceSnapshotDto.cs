namespace HealthcareForm.Contracts.Admin;

public sealed class AdminDataGovernanceSnapshotDto
{
    public IReadOnlyList<AdminConfigurationItemDto> ConfigurationItems { get; init; } = [];
    public IReadOnlyList<AdminTemplateGovernanceItemDto> TemplateItems { get; init; } = [];
    public IReadOnlyList<AdminLookupHealthItemDto> LookupItems { get; init; } = [];
}
