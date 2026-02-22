namespace HealthcareForm.Contracts.Patients;

public sealed class PatientRecordDto
{
    public string IdNumber { get; init; } = string.Empty;
    public string FirstName { get; init; } = string.Empty;
    public string LastName { get; init; } = string.Empty;
    public DateTime DateOfBirth { get; init; }
    public int GenderId { get; init; }
    public string PhoneNumber { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string Line1 { get; init; } = string.Empty;
    public string Line2 { get; init; } = string.Empty;
    public int CityId { get; init; }
    public int ProvinceId { get; init; }
    public int CountryId { get; init; }
    public int MaritalStatusId { get; init; }
    public string MedicationList { get; init; } = string.Empty;
    public string EmergencyName { get; init; } = string.Empty;
    public string EmergencyLastName { get; init; } = string.Empty;
    public string EmergencyPhoneNumber { get; init; } = string.Empty;
    public string Relationship { get; init; } = string.Empty;
    public DateTime EmergencyDateOfBirth { get; init; }
}
