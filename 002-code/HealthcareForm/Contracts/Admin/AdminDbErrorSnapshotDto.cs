namespace HealthcareForm.Contracts.Admin;

public sealed class AdminDbErrorSnapshotDto
{
    public int MaxRows { get; init; }
    public DateTime? SinceUtc { get; init; }
    public int TotalCount { get; init; }
    public IReadOnlyList<AdminDbErrorDto> Errors { get; init; } = [];
}
