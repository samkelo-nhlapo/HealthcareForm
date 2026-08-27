namespace HealthcareForm.Contracts.Patients;

// Paged patient-directory payload for list screens.
public sealed class PatientDirectorySnapshotDto
{
    public IReadOnlyList<PatientDirectoryItemDto> Patients { get; set; } = [];
    public int TotalRecords { get; set; }
}
