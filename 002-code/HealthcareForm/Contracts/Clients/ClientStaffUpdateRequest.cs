using System.ComponentModel.DataAnnotations;

namespace HealthcareForm.Contracts.Clients;

public sealed class ClientStaffUpdateRequest : IValidatableObject
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

    public DateTime? TerminationDate { get; init; }

    public bool IsPrimaryContact { get; init; }

    public bool IsActive { get; init; } = true;

    public Guid? PrimaryDepartmentId { get; init; }

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (PrimaryDepartmentId.HasValue && PrimaryDepartmentId.Value == Guid.Empty)
        {
            yield return new ValidationResult(
                "PrimaryDepartmentId must be a valid department ID when supplied.",
                [nameof(PrimaryDepartmentId)]);
        }

        if (TerminationDate.HasValue && HireDate.HasValue && TerminationDate.Value < HireDate.Value)
        {
            yield return new ValidationResult(
                "TerminationDate cannot be before HireDate.",
                [nameof(TerminationDate), nameof(HireDate)]);
        }
    }
}
