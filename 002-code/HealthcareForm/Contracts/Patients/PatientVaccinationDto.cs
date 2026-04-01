namespace HealthcareForm.Contracts.Patients;

// Vaccination entry returned for a patient.
public sealed class PatientVaccinationDto
{
    // Unique identifier for the vaccination record.
    public Guid VaccinationId { get; init; }

    // Vaccine display name.
    public string VaccineName { get; init; } = string.Empty;

    // Vaccine code captured by the source system.
    public string VaccineCode { get; init; } = string.Empty;

    // Administration date.
    public DateTime AdministrationDate { get; init; }

    // Due date for the next dose when one is known.
    public DateTime? DueDate { get; init; }

    // Person or role that administered the vaccine.
    public string AdministeredBy { get; init; } = string.Empty;

    // Vaccine lot number.
    public string Lot { get; init; } = string.Empty;

    // Administration site.
    public string Site { get; init; } = string.Empty;

    // Route of administration.
    public string Route { get; init; } = string.Empty;

    // Recorded reaction, if any.
    public string Reaction { get; init; } = string.Empty;

    // Current vaccination status.
    public string Status { get; init; } = string.Empty;

    // Free-form vaccination notes.
    public string Notes { get; init; } = string.Empty;

    // Last update timestamp from the source system.
    public DateTime? UpdatedDate { get; init; }
}
