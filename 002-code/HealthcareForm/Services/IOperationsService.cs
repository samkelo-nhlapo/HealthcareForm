using HealthcareForm.Contracts.Operations;

namespace HealthcareForm.Services;

// Operational dashboard queries used by the scheduling and task-queue APIs.
public interface IOperationsService
{
    // Builds the current scheduling snapshot.
    Task<SchedulingSnapshotDto> GetSchedulingSnapshotAsync(CancellationToken cancellationToken = default);

    // Builds the current task-queue snapshot.
    Task<TaskQueueSnapshotDto> GetTaskQueueSnapshotAsync(CancellationToken cancellationToken = default);
}
