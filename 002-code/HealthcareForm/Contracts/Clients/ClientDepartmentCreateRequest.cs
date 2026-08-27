using System.ComponentModel.DataAnnotations;

namespace HealthcareForm.Contracts.Clients;

public sealed class ClientDepartmentCreateRequest
{
    [Required, MaxLength(100)]
    public string DepartmentName { get; init; } = string.Empty;

    [MaxLength(50)]
    public string? DepartmentCode { get; init; }

    [Required, MaxLength(50)]
    public string DepartmentType { get; init; } = "Clinical";
}
