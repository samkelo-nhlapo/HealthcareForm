namespace HealthcareForm.Contracts.Admin;

public sealed class AdminDbErrorQueryDto
{
    public int? MaxRows { get; init; }
    public DateTime? SinceUtc { get; init; }
}
