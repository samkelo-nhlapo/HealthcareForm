namespace HealthcareForm.Contracts.Patients;

// Query options for the searchable patient directory.
public sealed class PatientDirectoryQueryDto
{
    // Free-text match against name, ID number, email, or phone.
    public string? SearchTerm { get; set; }

    // Optional gender filter.
    public int? GenderId { get; set; }

    // Optional marital-status filter.
    public int? MaritalStatusId { get; set; }

    // Optional client filter.
    public Guid? ClientId { get; set; }

    // Optional soft-delete filter: false = active, true = deleted, null = all.
    public bool? IsDeleted { get; set; }

    // Requested page number.
    public int PageNumber { get; set; } = 1;

    // Requested page size.
    public int PageSize { get; set; } = 25;
}
