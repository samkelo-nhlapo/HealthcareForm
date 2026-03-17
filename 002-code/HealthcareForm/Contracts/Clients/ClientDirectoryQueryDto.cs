namespace HealthcareForm.Contracts.Clients;

public sealed class ClientDirectoryQueryDto
{
    public string? SearchTerm { get; set; }
    public int? ClientClinicCategoryId { get; set; }
    public string? ClinicSize { get; set; }
    public string? OwnershipType { get; set; }
    public bool? IsActive { get; set; }
    public bool? IsDeleted { get; set; }
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 25;
}
