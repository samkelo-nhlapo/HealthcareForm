namespace HealthcareForm.Contracts.Admin;

public sealed class AdminTemplateGovernanceItemDto
{
    public string TemplateName { get; init; } = string.Empty;
    public string Version { get; init; } = string.Empty;
    public string Status { get; init; } = string.Empty;
    public string Owner { get; init; } = string.Empty;
    public string LastApproved { get; init; } = string.Empty;
    public string NextReview { get; init; } = string.Empty;
}
