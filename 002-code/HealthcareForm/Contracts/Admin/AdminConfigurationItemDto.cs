namespace HealthcareForm.Contracts.Admin;

// Configuration comparison row shown in the data-governance snapshot.
public sealed class AdminConfigurationItemDto
{
    // Configuration key being reviewed.
    public string Key { get; init; } = string.Empty;

    // Scope or subsystem the key belongs to.
    public string Scope { get; init; } = string.Empty;

    // Value currently seen by the running application.
    public string CurrentValue { get; init; } = string.Empty;

    // Expected baseline or reference value.
    public string BaselineValue { get; init; } = string.Empty;

    // Last update timestamp already formatted for display.
    public string LastUpdated { get; init; } = string.Empty;

    // Team or owner responsible for the setting.
    public string Owner { get; init; } = string.Empty;

    // Human-readable state such as healthy, drifted, or missing.
    public string State { get; init; } = string.Empty;
}
