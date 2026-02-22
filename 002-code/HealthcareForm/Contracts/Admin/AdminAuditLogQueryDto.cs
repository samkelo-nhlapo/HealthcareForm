namespace HealthcareForm.Contracts.Admin;

public sealed class AdminAuditLogQueryDto
{
    public string? Actor { get; set; }
    public string? Category { get; set; }
    public string? Outcome { get; set; }
    public DateTime? FromUtc { get; set; }
    public DateTime? ToUtc { get; set; }
    public string? Search { get; set; }
    public bool? PrivilegedOnly { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 50;
}
