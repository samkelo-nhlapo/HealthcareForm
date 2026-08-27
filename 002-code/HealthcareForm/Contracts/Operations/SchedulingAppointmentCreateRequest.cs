using System.ComponentModel.DataAnnotations;

namespace HealthcareForm.Contracts.Operations;

// Request body used to create a new scheduling appointment.
public sealed class SchedulingAppointmentCreateRequest : IValidatableObject
{
    // Clinic or hospital the appointment is being created for.
    [Required]
    public Guid? ClientId { get; init; }

    // National ID number used to resolve the patient record.
    [Required]
    public string PatientIdNumber { get; init; } = string.Empty;

    // Client-provider affiliation selected for the appointment booking.
    public Guid? ClientProviderAffiliationId { get; init; }

    // Optional client-staff identifier when the affiliation is tied to an employee record.
    public Guid? ClientStaffId { get; init; }

    // Appointment start date and time.
    [Required]
    public DateTime? AppointmentDateTime { get; init; }

    // Appointment duration in minutes.
    [Range(5, 480)]
    public int DurationMinutes { get; init; } = 30;

    // Appointment type shown in downstream workflows.
    [MaxLength(100)]
    public string AppointmentType { get; init; } = "Consultation";

    // Free-text reason associated with the booking.
    [MaxLength(4000)]
    public string? Reason { get; init; }

    // Optional location or room assignment.
    [MaxLength(250)]
    public string? Location { get; init; }

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (!ClientId.HasValue || ClientId.Value == Guid.Empty)
        {
            yield return new ValidationResult(
                "A valid clinic or hospital is required.",
                [nameof(ClientId)]);
        }

        var normalizedId = (PatientIdNumber ?? string.Empty).Trim();
        if (normalizedId.Length != 13 || normalizedId.Any(ch => !char.IsDigit(ch)))
        {
            yield return new ValidationResult(
                "Patient ID number must be exactly 13 digits.",
                [nameof(PatientIdNumber)]);
        }

        var hasAffiliation = ClientProviderAffiliationId.HasValue && ClientProviderAffiliationId.Value != Guid.Empty;
        var hasClientStaff = ClientStaffId.HasValue && ClientStaffId.Value != Guid.Empty;

        if (!hasAffiliation && !hasClientStaff)
        {
            yield return new ValidationResult(
                "A valid provider affiliation is required.",
                [nameof(ClientProviderAffiliationId), nameof(ClientStaffId)]);
        }

        if (!AppointmentDateTime.HasValue || AppointmentDateTime.Value == default)
        {
            yield return new ValidationResult(
                "A valid appointment date and time is required.",
                [nameof(AppointmentDateTime)]);
        }
    }
}
