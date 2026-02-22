namespace HealthcareForm.Contracts.Admin;

public sealed class AdminAuditEventDto
{
    public DateTime OccurredAtUtc { get; init; }
    public string Actor { get; init; } = string.Empty;
    public string ActorRole { get; init; } = string.Empty;
    public string Category { get; init; } = string.Empty;
    public string EventName { get; init; } = string.Empty;
    public string Resource { get; init; } = string.Empty;
    public string Outcome { get; init; } = string.Empty;
    public string IpAddress { get; init; } = string.Empty;
    public string CorrelationId { get; init; } = string.Empty;
    public bool Privileged { get; init; }
}
