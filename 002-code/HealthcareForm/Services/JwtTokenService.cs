using HealthcareForm.Contracts.Auth;
using HealthcareForm.Security;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;
using System.Text;

namespace HealthcareForm.Services;

public sealed class JwtTokenService : IJwtTokenService
{
    // Standard short-form JWT claim names (RFC 7519 / OIDC Core §5.1).
    // Avoids the long Microsoft ClaimTypes URIs that bloat the token payload.
    private const string ClaimName       = "name";
    private const string ClaimEmail      = "email";
    private const string ClaimGivenName  = "given_name";
    private const string ClaimFamilyName = "family_name";
    private const string ClaimRole       = "role";
    private const string ClaimSuperAdmin = "is_super_admin";

    private readonly JwtSettings _settings;
    private readonly ILogger<JwtTokenService> _logger;
    private readonly SigningCredentials _signingCredentials;
    private readonly JsonWebTokenHandler _tokenHandler;

    public JwtTokenService(IOptions<JwtSettings> options, ILogger<JwtTokenService> logger)
    {
        _settings = options.Value;
        _logger   = logger;

        // Fail-fast: validate config and decode key bytes in a single pass.
        byte[] keyBytes = ValidateAndGetKey(_settings);

        var signingKey     = new SymmetricSecurityKey(keyBytes);
        _signingCredentials = new SigningCredentials(signingKey, SecurityAlgorithms.HmacSha256);
        _tokenHandler      = new JsonWebTokenHandler();

        _logger.LogInformation(
            "JwtTokenService initialised. Issuer: {Issuer} | Expiry: {Expiry} min",
            _settings.Issuer,
            _settings.TokenExpiryMinutes);
    }

    public AuthTokenResponse CreateToken(AuthUserDto user)
    {
        ArgumentNullException.ThrowIfNull(user);

        var now          = DateTime.UtcNow;
        var expiresAtUtc = now.AddMinutes(_settings.TokenExpiryMinutes);

        // Dictionary<string, object> is the correct API for JsonWebTokenHandler —
        // it writes values directly into the payload without the ClaimTypes URI
        // re-mapping that ClaimsIdentity/Subject triggers.
        var claims = new Dictionary<string, object>
        {
            // ── RFC 7519 registered claims ──────────────────────────────────
            [JwtRegisteredClaimNames.Sub] = user.UserId.ToString(),
            [JwtRegisteredClaimNames.Jti] = Guid.NewGuid().ToString(),

            // iat must be a numeric value per RFC 7519 §4.1.6, not a string.
            [JwtRegisteredClaimNames.Iat] = new DateTimeOffset(now).ToUnixTimeSeconds(),

            // ── OIDC standard claims (short names, no Microsoft URI bloat) ──
            [ClaimName]       = user.Username,
            [ClaimEmail]      = user.Email,
            [ClaimGivenName]  = user.FirstName  ?? string.Empty,  // guard nullable
            [ClaimFamilyName] = user.LastName   ?? string.Empty,  // guard nullable

            // ── Application-specific claims ─────────────────────────────────
            [ClaimSuperAdmin] = user.IsSuperAdmin.ToString().ToLowerInvariant(),

            // JsonWebTokenHandler serialises IEnumerable<string> as a JSON array,
            // producing multiple role values correctly. Null-coalesced to an empty
            // collection so the claim is omitted rather than written as null.
            [ClaimRole] = (IEnumerable<string>)(user.Roles ?? Array.Empty<string>())
        };

        var descriptor = new SecurityTokenDescriptor
        {
            Issuer             = _settings.Issuer,
            Audience           = _settings.Audience,
            Claims             = claims,       // dictionary path, not Subject/ClaimsIdentity
            Expires            = expiresAtUtc,
            SigningCredentials  = _signingCredentials
        };

        string tokenString = _tokenHandler.CreateToken(descriptor);

        return new AuthTokenResponse
        {
            AccessToken  = tokenString,
            ExpiresAtUtc = expiresAtUtc,
            User         = user
        };
    }

    // Validates all JWT settings at startup and returns key bytes.
    // Throwing here keeps the app from starting with a broken or unsafe token setup.
    private static byte[] ValidateAndGetKey(JwtSettings settings)
    {
        if (string.IsNullOrWhiteSpace(settings.Issuer))
            throw new InvalidOperationException("JWT Issuer is not configured.");

        if (string.IsNullOrWhiteSpace(settings.Audience))
            throw new InvalidOperationException("JWT Audience is not configured.");

        // Lower bound: must be positive.
        // Upper bound (from V1): caps at one week so a fat-fingered config value
        // (e.g. 99999) cannot silently issue near-permanent tokens — critical in
        // a healthcare context where session hygiene is a compliance concern.
        if (settings.TokenExpiryMinutes <= 0 || settings.TokenExpiryMinutes > 10_080)
            throw new InvalidOperationException(
                "JWT TokenExpiryMinutes must be between 1 and 10 080 (one week).");

        if (string.IsNullOrWhiteSpace(settings.Key)
            || settings.Key.StartsWith("__SET_", StringComparison.Ordinal)
            || settings.Key.StartsWith("REPLACE_WITH_", StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("JWT Key is not properly configured.");

        if (settings.Key.Length < 32)
            throw new InvalidOperationException("JWT Key must be at least 32 characters.");

        return Encoding.UTF8.GetBytes(settings.Key);
    }
}
