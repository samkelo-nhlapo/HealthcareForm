namespace HealthcareForm.Contracts.Admin;

// Snapshot returned by the admin audit-log endpoint.
public sealed class AdminAuditLogSnapshotDto
{
    // Distinct actor values that can be used as filter options in the UI.
    public IReadOnlyList<string> ActorOptions { get; init; } = [];

    // Audit events for the current page.
    public IReadOnlyList<AdminAuditEventDto> Events { get; init; } = [];

    // Current one-based page number after normalization.
    public int Page { get; init; }

    // Page size applied by the service.
    public int PageSize { get; init; }

    // Total number of matching records before paging.
    public int TotalCount { get; init; }

    // Total number of available pages for the current filter.
    public int TotalPages { get; init; }
}
