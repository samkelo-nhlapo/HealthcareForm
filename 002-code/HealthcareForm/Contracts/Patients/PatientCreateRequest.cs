using System.ComponentModel.DataAnnotations;

namespace HealthcareForm.Contracts.Patients;

// Request body used to create a new patient.
public sealed class PatientCreateRequest : IValidatableObject
{
    // Primary clinic or hospital the patient is registered under.
    [Required]
    public Guid? PrimaryClientId { get; init; }

    // Additional clinics or hospitals the patient is shared with.
    public IReadOnlyList<Guid> SecondaryClientIds { get; init; } = [];

    // Patient given name.
    [Required, MaxLength(30)]
    public string FirstName { get; init; } = string.Empty;

    // Patient family name.
    [Required, MaxLength(30)]
    public string LastName { get; init; } = string.Empty;

    // National ID number used as the primary lookup key.
    [Required]
    public string IdNumber { get; init; } = string.Empty;

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

    // Free-text medication list captured at registration time.
    public string MedicationList { get; init; } = string.Empty;

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (!PatientRequestRules.IsValidIdNumber(IdNumber))
        {
            yield return new ValidationResult(
                "ID number must be exactly 13 digits.",
                [nameof(IdNumber)]);
        }

        foreach (var result in PatientRequestRules.ValidateRequiredDate(DateOfBirth, nameof(DateOfBirth), "Date of birth"))
        {
            yield return result;
        }

        foreach (var result in PatientRequestRules.ValidateRequiredDate(
                     EmergencyDateOfBirth,
                     nameof(EmergencyDateOfBirth),
                     "Emergency date of birth"))
        {
            yield return result;
        }
    }
}
