namespace HealthcareForm.Contracts.Patients;

// Full patient record returned by the lookup endpoint.
public sealed class PatientRecordDto
{
    // National ID number used as the primary lookup key.
    public string IdNumber { get; init; } = string.Empty;

    // Patient given name.
    public string FirstName { get; init; } = string.Empty;

    // Patient family name.
    public string LastName { get; init; } = string.Empty;

    // Patient date of birth.
    public DateTime DateOfBirth { get; init; }

    // Lookup identifier for gender.
    public int GenderId { get; init; }

    // Primary contact number.
    public string PhoneNumber { get; init; } = string.Empty;

    // Primary email address.
    public string Email { get; init; } = string.Empty;

    // Address line one.
    public string Line1 { get; init; } = string.Empty;

    // Address line two.
    public string Line2 { get; init; } = string.Empty;

    // Lookup identifier for city.
    public int CityId { get; init; }

    // Lookup identifier for province or state.
    public int ProvinceId { get; init; }

    // Lookup identifier for country.
    public int CountryId { get; init; }

    // Lookup identifier for marital status.
    public int MaritalStatusId { get; init; }

    // Free-text medication list captured on the core patient record.
    public string MedicationList { get; init; } = string.Empty;

    // Emergency contact given name.
    public string EmergencyName { get; init; } = string.Empty;

    // Emergency contact family name.
    public string EmergencyLastName { get; init; } = string.Empty;

    // Emergency contact phone number.
    public string EmergencyPhoneNumber { get; init; } = string.Empty;

    // Relationship between the patient and emergency contact.
    public string Relationship { get; init; } = string.Empty;

    // Emergency contact date of birth.
    public DateTime EmergencyDateOfBirth { get; init; }
}
