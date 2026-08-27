using System.ComponentModel.DataAnnotations;

namespace HealthcareForm.Contracts.Clients;

public sealed class ClientStaffCreateRequest : IValidatableObject
{
    [Required, MaxLength(50)]
    public string StaffCode { get; init; } = string.Empty;

    [Required, MaxLength(250)]
    public string FirstName { get; init; } = string.Empty;

    [Required, MaxLength(250)]
    public string LastName { get; init; } = string.Empty;

    [EmailAddress, MaxLength(250)]
    public string? Email { get; init; }

    [MaxLength(25)]
    public string? PhoneNumber { get; init; }

    [MaxLength(150)]
    public string? JobTitle { get; init; }

    [MaxLength(100)]
    public string? Department { get; init; }

    [Required, MaxLength(50)]
    public string StaffType { get; init; } = "Administrative";

    [Required, MaxLength(50)]
    public string EmploymentType { get; init; } = "Full-Time";

    public DateTime? HireDate { get; init; }

    public bool IsPrimaryContact { get; init; }

    public Guid? PrimaryDepartmentId { get; init; }

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (PrimaryDepartmentId.HasValue && PrimaryDepartmentId.Value == Guid.Empty)
        {
            yield return new ValidationResult(
                "PrimaryDepartmentId must be a valid department ID when supplied.",
                [nameof(PrimaryDepartmentId)]);
        }
    }
}
