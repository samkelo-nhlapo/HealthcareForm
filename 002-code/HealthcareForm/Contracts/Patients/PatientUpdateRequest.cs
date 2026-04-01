using System.ComponentModel.DataAnnotations;

namespace HealthcareForm.Contracts.Patients;

// Request body used to update an existing patient.
public sealed class PatientUpdateRequest
{
    // Patient given name.
    [Required, MaxLength(30)]
    public string FirstName { get; init; } = string.Empty;

    // Patient family name.
    [Required, MaxLength(30)]
    public string LastName { get; init; } = string.Empty;

    // Patient date of birth.
    [Required]
    public DateTime DateOfBirth { get; init; }

    // Lookup identifier for gender.
    [Range(1, int.MaxValue)]
    public int GenderId { get; init; }

    // Primary contact number.
    [Required]
    public string PhoneNumber { get; init; } = string.Empty;

    // Primary email address.
    [Required, EmailAddress]
    public string Email { get; init; } = string.Empty;

    // Address line one.
    [Required]
    public string Line1 { get; init; } = string.Empty;

    // Address line two.
    [Required]
    public string Line2 { get; init; } = string.Empty;

    // Lookup identifier for city.
    [Range(1, int.MaxValue)]
    public int CityId { get; init; }

    // Lookup identifier for province or state.
    [Range(1, int.MaxValue)]
    public int ProvinceId { get; init; }

    // Lookup identifier for country.
    [Range(1, int.MaxValue)]
    public int CountryId { get; init; }

    // Lookup identifier for marital status.
    [Range(1, int.MaxValue)]
    public int MaritalStatusId { get; init; }

    // Emergency contact given name.
    [Required]
    public string EmergencyName { get; init; } = string.Empty;

    // Emergency contact family name.
    [Required]
    public string EmergencyLastName { get; init; } = string.Empty;

    // Emergency contact phone number.
    [Required]
    public string EmergencyPhoneNumber { get; init; } = string.Empty;

    // Relationship between the patient and emergency contact.
    [Required]
    public string Relationship { get; init; } = string.Empty;

    // Emergency contact date of birth.
    [Required]
    public DateTime EmergencyDateOfBirth { get; init; }

    // Free-text medication list captured on the patient record.
    public string MedicationList { get; init; } = string.Empty;
}
