using System.ComponentModel.DataAnnotations;

namespace HealthcareForm.Contracts.Patients;

public sealed class PatientUpdateRequest
{
    [Required, MaxLength(30)]
    public string FirstName { get; init; } = string.Empty;

    [Required, MaxLength(30)]
    public string LastName { get; init; } = string.Empty;

    [Required]
    public DateTime DateOfBirth { get; init; }

    [Range(1, int.MaxValue)]
    public int GenderId { get; init; }

    [Required]
    public string PhoneNumber { get; init; } = string.Empty;

    [Required, EmailAddress]
    public string Email { get; init; } = string.Empty;

    [Required]
    public string Line1 { get; init; } = string.Empty;

    [Required]
    public string Line2 { get; init; } = string.Empty;

    [Range(1, int.MaxValue)]
    public int CityId { get; init; }

    [Range(1, int.MaxValue)]
    public int ProvinceId { get; init; }

    [Range(1, int.MaxValue)]
    public int CountryId { get; init; }

    [Range(1, int.MaxValue)]
    public int MaritalStatusId { get; init; }

    [Required]
    public string EmergencyName { get; init; } = string.Empty;

    [Required]
    public string EmergencyLastName { get; init; } = string.Empty;

    [Required]
    public string EmergencyPhoneNumber { get; init; } = string.Empty;

    [Required]
    public string Relationship { get; init; } = string.Empty;

    [Required]
    public DateTime EmergencyDateOfBirth { get; init; }

    public string MedicationList { get; init; } = string.Empty;
}
