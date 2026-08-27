namespace HealthcareForm.Contracts.Patients;

// One row in the patient directory.
public sealed class PatientDirectoryItemDto
{
    public Guid PatientId { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string IdNumber { get; set; } = string.Empty;
    public DateTime? DateOfBirth { get; set; }
    public int GenderId { get; set; }
    public int MaritalStatusId { get; set; }
    public Guid? ClientId { get; set; }
    public string ClientCode { get; set; } = string.Empty;
    public string ClientName { get; set; } = string.Empty;
    public string ClientClinicCategoryName { get; set; } = string.Empty;
    public IReadOnlyList<PatientClientAssignmentDto> Clients { get; set; } = [];
    public string MedicationList { get; set; } = string.Empty;
    public bool IsDeleted { get; set; }
    public string Email { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string Line1 { get; set; } = string.Empty;
    public string Line2 { get; set; } = string.Empty;
    public int CityId { get; set; }
    public string CityName { get; set; } = string.Empty;
    public int ProvinceId { get; set; }
    public string ProvinceName { get; set; } = string.Empty;
    public int CountryId { get; set; }
    public string CountryName { get; set; } = string.Empty;
    public DateTime CreatedDate { get; set; }
    public DateTime UpdatedDate { get; set; }
}
