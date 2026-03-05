namespace HealthcareForm.Security;

public sealed class JwtSettings
{
    public string Issuer { get; init; } = string.Empty;
    public string Audience { get; init; } = string.Empty;
    public string Key { get; init; } = string.Empty;
    public int TokenExpiryMinutes { get; init; } = 60;
}
