namespace HealthcareForm.Contracts.Clients;

public sealed class ClientDepartmentCommandResult
{
    public bool Success { get; init; }
    public string Message { get; init; } = string.Empty;
    public int? StatusCode { get; init; }
    public Guid? ClientDepartmentId { get; init; }
}
