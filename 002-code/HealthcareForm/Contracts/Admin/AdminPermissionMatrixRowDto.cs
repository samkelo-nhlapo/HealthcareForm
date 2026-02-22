namespace HealthcareForm.Contracts.Admin;

public sealed class AdminPermissionMatrixRowDto
{
    public string PermissionName { get; init; } = string.Empty;
    public string Module { get; init; } = string.Empty;
    public string Action { get; init; } = string.Empty;
    public IReadOnlyList<string> Roles { get; init; } = [];
}
