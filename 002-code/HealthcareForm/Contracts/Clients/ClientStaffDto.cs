namespace HealthcareForm.Contracts.Clients;

public sealed class ClientStaffDto
{
    public Guid ClientStaffId { get; set; }
    public Guid ClientId { get; set; }
    public string ClientCode { get; set; } = string.Empty;
    public Guid? RoleId { get; set; }
    public string RoleName { get; set; } = string.Empty;
    public Guid? UserId { get; set; }
    public string Username { get; set; } = string.Empty;
    public Guid? ProviderId { get; set; }
    public string StaffCode { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string JobTitle { get; set; } = string.Empty;
    public string Department { get; set; } = string.Empty;
    public Guid? StaffDesignationId { get; set; }
    public string StaffDesignation { get; set; } = string.Empty;
    public Guid? PrimaryDepartmentId { get; set; }
    public string PrimaryDepartmentName { get; set; } = string.Empty;
    public string StaffType { get; set; } = string.Empty;
    public string EmploymentType { get; set; } = string.Empty;
    public DateTime? HireDate { get; set; }
    public DateTime? TerminationDate { get; set; }
    public bool IsPrimaryContact { get; set; }
    public bool IsActive { get; set; }
    public bool IsDeleted { get; set; }
    public DateTime CreatedDate { get; set; }
    public DateTime UpdatedDate { get; set; }
}
