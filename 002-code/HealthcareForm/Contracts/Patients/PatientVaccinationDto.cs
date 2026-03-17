namespace HealthcareForm.Contracts.Patients;

public sealed class PatientVaccinationDto
{
    public Guid VaccinationId { get; init; }
    public string VaccineName { get; init; } = string.Empty;
    public string VaccineCode { get; init; } = string.Empty;
    public DateTime AdministrationDate { get; init; }
    public DateTime? DueDate { get; init; }
    public string AdministeredBy { get; init; } = string.Empty;
    public string Lot { get; init; } = string.Empty;
    public string Site { get; init; } = string.Empty;
    public string Route { get; init; } = string.Empty;
    public string Reaction { get; init; } = string.Empty;
    public string Status { get; init; } = string.Empty;
    public string Notes { get; init; } = string.Empty;
    public DateTime? UpdatedDate { get; init; }
}
