namespace HealthcareForm.Contracts.Admin;

// Single audit event returned to the admin workspace.
public sealed class AdminAuditEventDto
{
    // UTC timestamp for when the event occurred.
    public DateTime OccurredAtUtc { get; init; }

    // Actor associated with the event.
    public string Actor { get; init; } = string.Empty;

    // Normalized role for the actor at the time of the event.
    public string ActorRole { get; init; } = string.Empty;

    // High-level category used for grouping and filtering.
    public string Category { get; init; } = string.Empty;

    // Specific event name shown to administrators.
    public string EventName { get; init; } = string.Empty;

    // Resource or subsystem associated with the event.
    public string Resource { get; init; } = string.Empty;

    // Normalized outcome, usually success or failure.
    public string Outcome { get; init; } = string.Empty;

    // Source IP address captured for the event, when available.
    public string IpAddress { get; init; } = string.Empty;

    // Correlation identifier used to stitch related activity together.
    public string CorrelationId { get; init; } = string.Empty;

    // Indicates whether the event should be treated as privileged activity.
    public bool Privileged { get; init; }
}
