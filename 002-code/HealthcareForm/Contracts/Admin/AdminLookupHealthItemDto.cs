namespace HealthcareForm.Contracts.Admin;

// Lookup-health row shown in the data-governance snapshot.
public sealed class AdminLookupHealthItemDto
{
    // Friendly lookup name.
    public string Name { get; init; } = string.Empty;

    // Number of records currently present.
    public int Records { get; init; }

    // Upstream source or owning system.
    public string Source { get; init; } = string.Empty;

    // Expected refresh rhythm for the lookup.
    public string RefreshCadence { get; init; } = string.Empty;

    // Last successful sync timestamp formatted for display, or "N/A".
    public string LastSync { get; init; } = string.Empty;

    // Human-readable health state for the lookup.
    public string State { get; init; } = string.Empty;
}
