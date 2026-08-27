namespace HealthcareForm.Contracts.Clients;

public sealed class ClientRecordDto
{
    public Guid ClientId { get; set; }
    public Guid? PatientId { get; set; }
    public int RegisteredPatientCount { get; set; }
    public int ActivePatientCount { get; set; }
    public int? ClientClinicCategoryId { get; set; }
    public string ClientClinicCategoryName { get; set; } = string.Empty;
    public string ClinicSize { get; set; } = string.Empty;
    public string OwnershipType { get; set; } = string.Empty;
    public string ClientCode { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string OrganizationType { get; set; } = string.Empty;
    public string GroupOperator { get; set; } = string.Empty;
    public string NetworkSources { get; set; } = string.Empty;
    public string DirectoryExternalKey { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public DateTime? DateOfBirth { get; set; }
    public string IdNumber { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public Guid? AddressId { get; set; }
    public string Line1 { get; set; } = string.Empty;
    public string Line2 { get; set; } = string.Empty;
    public int? CityId { get; set; }
    public int? FacilityCityId { get; set; }
    public string FacilityTownName { get; set; } = string.Empty;
    public string FacilityProvinceName { get; set; } = string.Empty;
    public string FacilityCountryName { get; set; } = string.Empty;
    public string FacilityAddressText { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public bool IsDeleted { get; set; }
    public DateTime CreatedDate { get; set; }
    public string CreatedBy { get; set; } = string.Empty;
    public DateTime UpdatedDate { get; set; }
    public string UpdatedBy { get; set; } = string.Empty;
}
