namespace HealthcareForm.Contracts.Auth;

public sealed class AuthLoginResult
{
    public bool Success { get; init; }
    public string Message { get; init; } = string.Empty;
    public AuthUserDto? User { get; init; }
}
