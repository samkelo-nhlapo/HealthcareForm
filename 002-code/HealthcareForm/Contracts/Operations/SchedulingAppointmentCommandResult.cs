namespace HealthcareForm.Contracts.Operations;

// Standard command result for scheduling appointment creation.
public sealed class SchedulingAppointmentCommandResult
{
    // Indicates whether the command completed successfully.
    public bool Success { get; init; }

    // Human-readable outcome message from the service or stored procedure.
    public string Message { get; init; } = string.Empty;

    // Optional backend status code surfaced from the database layer.
    public int? StatusCode { get; init; }

    // Identifier of the created appointment when successful.
    public Guid? AppointmentId { get; init; }
}
