using System.ComponentModel.DataAnnotations;

namespace HealthcareForm.Contracts.Clients;

// Request body used to update an existing client profile.
public sealed class ClientUpdateRequest : IValidatableObject
{
    [Required, MaxLength(50)]
    public string ClientCode { get; init; } = string.Empty;

    [Required, MaxLength(250)]
    public string FirstName { get; init; } = string.Empty;

    [Required, MaxLength(250)]
    public string LastName { get; init; } = string.Empty;

    public DateTime? DateOfBirth { get; init; }

    [MaxLength(250)]
    public string? IdNumber { get; init; }

    [EmailAddress, MaxLength(250)]
    public string? Email { get; init; }

    [MaxLength(25)]
    public string? PhoneNumber { get; init; }

    [MaxLength(250)]
    public string? Line1 { get; init; }

    [MaxLength(250)]
    public string? Line2 { get; init; }

    public int? CityId { get; init; }

    public int? ClientClinicCategoryId { get; init; }

    public bool IsActive { get; init; } = true;

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        var hasAddressInput =
            !string.IsNullOrWhiteSpace(Line1)
            || !string.IsNullOrWhiteSpace(Line2)
            || CityId.HasValue;

        if (!hasAddressInput)
        {
            yield break;
        }

        if (string.IsNullOrWhiteSpace(Line1))
        {
            yield return new ValidationResult(
                "Address line 1 is required when saving an address.",
                [nameof(Line1)]);
        }

        if (string.IsNullOrWhiteSpace(Line2))
        {
            yield return new ValidationResult(
                "Address line 2 is required when saving an address.",
                [nameof(Line2)]);
        }

        if (!CityId.HasValue || CityId.Value <= 0)
        {
            yield return new ValidationResult(
                "A valid city is required when saving an address.",
                [nameof(CityId)]);
        }
    }
}
