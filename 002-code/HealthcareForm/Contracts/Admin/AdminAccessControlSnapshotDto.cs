namespace HealthcareForm.Contracts.Admin;

public sealed class AdminAccessControlSnapshotDto
{
    public IReadOnlyList<string> RoleColumns { get; init; } = [];
    public IReadOnlyList<AdminAccessUserDto> Users { get; init; } = [];
    public IReadOnlyList<AdminPermissionMatrixRowDto> Permissions { get; init; } = [];
}
