namespace HealthcareForm.Contracts.Clients;

// Result returned when looking up one client record by ID.
public sealed class ClientLookupResult
{
    // Indicates whether the client record was found.
    public bool Found { get; init; }

    // Human-readable message for not-found or error cases.
    public string Message { get; init; } = string.Empty;

    // Client record when the lookup succeeds.
    public ClientRecordDto? Client { get; init; }
}
