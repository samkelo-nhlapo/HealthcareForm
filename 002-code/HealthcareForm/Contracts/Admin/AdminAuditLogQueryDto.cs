namespace HealthcareForm.Contracts.Admin;

// Filters supported by the admin audit-log endpoint.
public sealed class AdminAuditLogQueryDto
{
    // Optional actor username or label filter.
    public string? Actor { get; set; }

    // Optional event category filter.
    public string? Category { get; set; }

    // Optional outcome filter such as success or failure.
    public string? Outcome { get; set; }

    // Inclusive start of the UTC time window.
    public DateTime? FromUtc { get; set; }

    // Inclusive end of the UTC time window.
    public DateTime? ToUtc { get; set; }

    // Free-text search applied to the event details.
    public string? Search { get; set; }

    // When true, returns only privileged admin-style events.
    public bool? PrivilegedOnly { get; set; }

    // One-based page number. Defaults to 1.
    public int Page { get; set; } = 1;

    // Requested page size before service-side clamping.
    public int PageSize { get; set; } = 50;
}
