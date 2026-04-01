namespace HealthcareForm.Contracts.Admin;

// Snapshot returned by the admin database-error endpoint.
public sealed class AdminDbErrorSnapshotDto
{
    // Row limit applied after service-side normalization.
    public int MaxRows { get; init; }

    // UTC lower bound that was applied to the query, if any.
    public DateTime? SinceUtc { get; init; }

    // Number of error rows returned in this snapshot.
    public int TotalCount { get; init; }

    // Database errors returned for the current query.
    public IReadOnlyList<AdminDbErrorDto> Errors { get; init; } = [];
}
