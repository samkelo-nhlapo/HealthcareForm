using HealthcareForm.Contracts.Auth;

namespace HealthcareForm.Services;

public interface IAuthService
{
    Task<AuthLoginResult> AuthenticateAsync(string usernameOrEmail, string password, CancellationToken cancellationToken = default);
}
