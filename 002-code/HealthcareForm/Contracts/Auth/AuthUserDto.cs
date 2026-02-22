namespace HealthcareForm.Contracts.Auth;

public sealed class AuthUserDto
{
    public Guid UserId { get; init; }
    public string Username { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string FirstName { get; init; } = string.Empty;
    public string LastName { get; init; } = string.Empty;
    public bool IsSuperAdmin { get; init; }
    public IReadOnlyList<string> Roles { get; init; } = [];
}
