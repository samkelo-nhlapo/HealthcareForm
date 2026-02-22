namespace HealthcareForm.Contracts.Admin;

public sealed class AdminAccessUserDto
{
    public string Username { get; init; } = string.Empty;
    public string FullName { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public IReadOnlyList<string> Roles { get; init; } = [];
    public string Status { get; init; } = string.Empty;
    public string Mfa { get; init; } = string.Empty;
    public string LastLogin { get; init; } = string.Empty;
}
