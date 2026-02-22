namespace HealthcareForm.Contracts.Admin;

public sealed class AdminLookupHealthItemDto
{
    public string Name { get; init; } = string.Empty;
    public int Records { get; init; }
    public string Source { get; init; } = string.Empty;
    public string RefreshCadence { get; init; } = string.Empty;
    public string LastSync { get; init; } = string.Empty;
    public string State { get; init; } = string.Empty;
}
