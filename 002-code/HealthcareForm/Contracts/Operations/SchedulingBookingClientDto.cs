namespace HealthcareForm.Contracts.Operations;

// Clinic/hospital option shown when creating a scheduling appointment.
public sealed class SchedulingBookingClientDto
{
    // Client identifier used during appointment creation.
    public string ClientId { get; init; } = string.Empty;

    // Human-readable client display name.
    public string ClientName { get; init; } = string.Empty;

    // Optional business/client code.
    public string ClientCode { get; init; } = string.Empty;

    // Clinic category label (for example private/public).
    public string ClientCategory { get; init; } = string.Empty;
}
