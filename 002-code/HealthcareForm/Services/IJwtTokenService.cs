using HealthcareForm.Contracts.Auth;

namespace HealthcareForm.Services;

public interface IJwtTokenService
{
    AuthTokenResponse CreateToken(AuthUserDto user);
}
