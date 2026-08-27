namespace HealthcareForm.Contracts.Clients;

// Standard command result for client create, update, and delete operations.
public sealed class ClientCommandResult
{
    // Indicates whether the command completed successfully.
    public bool Success { get; init; }

    // Human-readable outcome message from the service or stored procedure.
    public string Message { get; init; } = string.Empty;

    // Optional backend status code surfaced from the database layer.
    public int? StatusCode { get; init; }

    // Identifier of the affected client when the command creates a record.
    public Guid? ClientId { get; init; }
}
