namespace HealthcareForm.Contracts.Operations;

// Booking options returned for scheduling appointment creation.
public sealed class SchedulingBookingOptionsDto
{
    // Available clinics/hospitals a user can schedule against.
    public IReadOnlyList<SchedulingBookingClientDto> Clients { get; init; } = [];

    // Active doctor providers linked to those clients.
    public IReadOnlyList<SchedulingBookingProviderDto> Providers { get; init; } = [];
}
