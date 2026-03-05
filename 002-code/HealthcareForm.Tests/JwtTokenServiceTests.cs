using System.Text;
using System.Text.Json;
using HealthcareForm.Contracts.Auth;
using HealthcareForm.Security;
using HealthcareForm.Services;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;

namespace HealthcareForm.Tests;

public sealed class JwtTokenServiceTests
{
    [Fact]
    public void Constructor_WithShortKey_ThrowsInvalidOperationException()
    {
        var settings = new JwtSettings
        {
            Issuer = "HealthcareForm.Api",
            Audience = "HealthcareForm.Angular",
            Key = "too-short-key",
            TokenExpiryMinutes = 60
        };

        var action = () => CreateService(settings);

        var exception = Assert.Throws<InvalidOperationException>(action);
        Assert.Contains("at least 32 characters", exception.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Constructor_WithOutOfRangeExpiry_ThrowsInvalidOperationException()
    {
        var settings = new JwtSettings
        {
            Issuer = "HealthcareForm.Api",
            Audience = "HealthcareForm.Angular",
            Key = new string('k', 40),
            TokenExpiryMinutes = 0
        };

        var action = () => CreateService(settings);

        var exception = Assert.Throws<InvalidOperationException>(action);
        Assert.Contains("TokenExpiryMinutes", exception.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void CreateToken_WithValidSettings_WritesExpectedClaims()
    {
        var settings = new JwtSettings
        {
            Issuer = "HealthcareForm.Api",
            Audience = "HealthcareForm.Angular",
            Key = new string('k', 40),
            TokenExpiryMinutes = 60
        };

        var service = CreateService(settings);
        var user = new AuthUserDto
        {
            UserId = Guid.Parse("F9922175-12E8-4DD8-B6B4-EF1D42B0143A"),
            Username = "nurse.jane",
            Email = "nurse.jane@example.com",
            FirstName = "Jane",
            LastName = "Doe",
            IsSuperAdmin = false,
            Roles = ["NURSE", "ADMIN"]
        };

        var token = service.CreateToken(user);
        var payload = ReadJwtPayload(token.AccessToken);

        Assert.Equal("Bearer", token.TokenType);
        Assert.Equal(user.UserId.ToString(), payload.GetProperty("sub").GetString());
        Assert.Equal(user.Username, payload.GetProperty("name").GetString());
        Assert.Equal(user.Email, payload.GetProperty("email").GetString());
        Assert.Equal("false", payload.GetProperty("is_super_admin").GetString());

        var roleValues = payload.GetProperty("role").EnumerateArray().Select(item => item.GetString()).ToList();
        Assert.Contains("NURSE", roleValues);
        Assert.Contains("ADMIN", roleValues);
    }

    private static JwtTokenService CreateService(JwtSettings settings)
    {
        return new JwtTokenService(Options.Create(settings), NullLogger<JwtTokenService>.Instance);
    }

    private static JsonElement ReadJwtPayload(string token)
    {
        var segments = token.Split('.');
        Assert.True(segments.Length >= 2, "JWT token should contain at least 2 segments.");

        var payloadSegment = segments[1];
        var normalized = payloadSegment.Replace('-', '+').Replace('_', '/');
        var padding = normalized.Length % 4;
        if (padding > 0)
        {
            normalized = normalized.PadRight(normalized.Length + (4 - padding), '=');
        }

        var payloadBytes = Convert.FromBase64String(normalized);
        using var document = JsonDocument.Parse(payloadBytes);
        return document.RootElement.Clone();
    }
}
