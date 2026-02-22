using HealthcareForm.Contracts.Operations;

namespace HealthcareForm.Services;

public interface IOperationsService
{
    Task<SchedulingSnapshotDto> GetSchedulingSnapshotAsync(CancellationToken cancellationToken = default);
    Task<TaskQueueSnapshotDto> GetTaskQueueSnapshotAsync(CancellationToken cancellationToken = default);
}
