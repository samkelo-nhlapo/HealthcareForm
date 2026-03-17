namespace HealthcareForm.Contracts.Clients;

public sealed class ClientStaffQueryDto
{
    public Guid? ClientId { get; set; }
    public string? SearchTerm { get; set; }
    public Guid? RoleId { get; set; }
    public string? StaffType { get; set; }
    public bool? IsActive { get; set; }
    public bool? IsDeleted { get; set; }
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 25;
}
