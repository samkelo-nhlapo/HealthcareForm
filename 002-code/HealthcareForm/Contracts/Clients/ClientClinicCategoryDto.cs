namespace HealthcareForm.Contracts.Clients;

public sealed class ClientClinicCategoryDto
{
    public int ClientClinicCategoryId { get; set; }
    public string CategoryName { get; set; } = string.Empty;
    public string ClinicSize { get; set; } = string.Empty;
    public string OwnershipType { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public DateTime CreatedDate { get; set; }
    public DateTime UpdatedDate { get; set; }
}
