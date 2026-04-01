namespace HealthcareForm.Contracts.Patients;

// Lightweight patient row shown in the worklist.
public sealed class PatientWorklistItemDto
{
    // National ID number used as the primary lookup key.
    public string IdNumber { get; init; } = string.Empty;

    // Patient display name shown in the list.
    public string Patient { get; init; } = string.Empty;

    // Current worklist status.
    public string Status { get; init; } = "Waiting";

    // Clinic lane used to group the patient in the worklist.
    public string Clinic { get; init; } = "General";

    // Derived risk label used by the dashboard.
    public string Risk { get; init; } = "Low";

    // Last update date formatted for display.
    public string UpdatedOn { get; init; } = string.Empty;
}
