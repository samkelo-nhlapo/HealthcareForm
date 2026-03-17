namespace HealthcareForm.Contracts.Patients;

public sealed class PatientMedicationDto
{
    public Guid MedicationId { get; init; }
    public string MedicationName { get; init; } = string.Empty;
    public string Dosage { get; init; } = string.Empty;
    public string Frequency { get; init; } = string.Empty;
    public string Route { get; init; } = string.Empty;
    public string Indication { get; init; } = string.Empty;
    public string PrescribedBy { get; init; } = string.Empty;
    public DateTime PrescriptionDate { get; init; }
    public DateTime StartDate { get; init; }
    public DateTime? EndDate { get; init; }
    public string Status { get; init; } = string.Empty;
    public string SideEffects { get; init; } = string.Empty;
    public string Notes { get; init; } = string.Empty;
    public bool IsActive { get; init; }
    public DateTime? UpdatedDate { get; init; }
}
