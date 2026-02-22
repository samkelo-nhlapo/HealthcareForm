namespace HealthcareForm.Contracts.Operations;

public sealed class SchedulingSnapshotDto
{
    public IReadOnlyList<SchedulingProviderLoadDto> Providers { get; init; } = [];
    public IReadOnlyList<SchedulingResourceLoadDto> Resources { get; init; } = [];
    public IReadOnlyList<SchedulingTimeBlockDto> Blocks { get; init; } = [];
}
