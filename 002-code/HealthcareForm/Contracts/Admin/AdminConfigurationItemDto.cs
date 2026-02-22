namespace HealthcareForm.Contracts.Admin;

public sealed class AdminConfigurationItemDto
{
    public string Key { get; init; } = string.Empty;
    public string Scope { get; init; } = string.Empty;
    public string CurrentValue { get; init; } = string.Empty;
    public string BaselineValue { get; init; } = string.Empty;
    public string LastUpdated { get; init; } = string.Empty;
    public string Owner { get; init; } = string.Empty;
    public string State { get; init; } = string.Empty;
}
