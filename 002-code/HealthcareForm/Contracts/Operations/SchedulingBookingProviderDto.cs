namespace HealthcareForm.Contracts.Operations;

// Provider option shown when creating a scheduling appointment.
public sealed class SchedulingBookingProviderDto
{
    // Client-provider affiliation identifier used for appointment creation.
    public string ClientProviderAffiliationId { get; init; } = string.Empty;

    // Optional client-staff identifier when the affiliation is tied to an employee row.
    public string ClientStaffId { get; init; } = string.Empty;

    // Provider identifier retained for display and compatibility.
    public string ProviderId { get; init; } = string.Empty;

    // Client identifier the provider is linked to.
    public string ClientId { get; init; } = string.Empty;

    // Provider display name.
    public string Provider { get; init; } = string.Empty;

    // Provider clinic/specialization lane.
    public string Clinic { get; init; } = "General";
}
