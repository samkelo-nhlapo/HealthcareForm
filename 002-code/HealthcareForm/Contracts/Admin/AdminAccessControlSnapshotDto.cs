namespace HealthcareForm.Contracts.Admin;

// Snapshot returned by the admin access-control endpoint.
public sealed class AdminAccessControlSnapshotDto
{
    // Ordered role labels used as columns in the access matrix.
    public IReadOnlyList<string> RoleColumns { get; init; } = [];

    // Users included in the current access-control view.
    public IReadOnlyList<AdminAccessUserDto> Users { get; init; } = [];

    // Permission rows shown beneath the role columns.
    public IReadOnlyList<AdminPermissionMatrixRowDto> Permissions { get; init; } = [];
}
