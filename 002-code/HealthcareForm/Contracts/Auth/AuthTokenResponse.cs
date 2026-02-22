namespace HealthcareForm.Contracts.Auth;

public sealed class AuthTokenResponse
{
    public string TokenType { get; init; } = "Bearer";
    public string AccessToken { get; init; } = string.Empty;
    public DateTime ExpiresAtUtc { get; init; }
    public AuthUserDto User { get; init; } = new();
}
