namespace HealthcareForm.Contracts.Admin;

// Filters supported by the admin database-error endpoint.
public sealed class AdminDbErrorQueryDto
{
    // Optional maximum number of rows to return before clamping.
    public int? MaxRows { get; init; }

    // Optional UTC lower bound for error timestamps.
    public DateTime? SinceUtc { get; init; }
}
