namespace HealthcareForm.Contracts.Clients;

public sealed class ClientStaffLookupResult
{
    public bool Found { get; init; }
    public string Message { get; init; } = string.Empty;
    public ClientStaffDto? Staff { get; init; }
}
