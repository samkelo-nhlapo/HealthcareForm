namespace HealthcareForm.Contracts.Clients;

public sealed class ClientDepartmentQueryDto
{
    public Guid? ClientId { get; set; }
    public string? DepartmentType { get; set; }
    public string? SearchTerm { get; set; }
    public bool? IsActive { get; set; }
    public bool? IsDeleted { get; set; }
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 25;
}
