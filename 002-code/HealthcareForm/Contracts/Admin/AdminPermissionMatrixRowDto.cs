namespace HealthcareForm.Contracts.Admin;

// Permission row shown in the access-control matrix.
public sealed class AdminPermissionMatrixRowDto
{
    // Stable permission name used by the backend.
    public string PermissionName { get; init; } = string.Empty;

    // Functional area the permission belongs to.
    public string Module { get; init; } = string.Empty;

    // Allowed action for the permission, such as read or write.
    public string Action { get; init; } = string.Empty;

    // Roles that currently include this permission.
    public IReadOnlyList<string> Roles { get; init; } = [];
}
