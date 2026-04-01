namespace HealthcareForm.Contracts.Admin;

// Template-governance row shown in the data-governance snapshot.
public sealed class AdminTemplateGovernanceItemDto
{
    // Friendly template or form name.
    public string TemplateName { get; init; } = string.Empty;

    // Current template version label.
    public string Version { get; init; } = string.Empty;

    // Current governance state such as draft or published.
    public string Status { get; init; } = string.Empty;

    // Person or team responsible for the template.
    public string Owner { get; init; } = string.Empty;

    // Date the template was last approved, formatted for display.
    public string LastApproved { get; init; } = string.Empty;

    // Date the next governance review is expected.
    public string NextReview { get; init; } = string.Empty;
}
