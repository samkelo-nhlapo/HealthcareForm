namespace HealthcareForm.Contracts.Admin;

public sealed class AdminAuditLogSnapshotDto
{
    public IReadOnlyList<string> ActorOptions { get; init; } = [];
    public IReadOnlyList<AdminAuditEventDto> Events { get; init; } = [];
    public int Page { get; init; }
    public int PageSize { get; init; }
    public int TotalCount { get; init; }
    public int TotalPages { get; init; }
}
