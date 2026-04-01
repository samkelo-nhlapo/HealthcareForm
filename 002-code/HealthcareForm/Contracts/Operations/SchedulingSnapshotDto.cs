namespace HealthcareForm.Contracts.Operations;

// Snapshot returned by the operations scheduling endpoint.
public sealed class SchedulingSnapshotDto
{
    // Provider workload rows shown in the scheduling board.
    public IReadOnlyList<SchedulingProviderLoadDto> Providers { get; init; } = [];

    // Resource utilization rows shown alongside provider workloads.
    public IReadOnlyList<SchedulingResourceLoadDto> Resources { get; init; } = [];

    // Time-block distribution used by the scheduling heatmap.
    public IReadOnlyList<SchedulingTimeBlockDto> Blocks { get; init; } = [];
}
