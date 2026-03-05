using HealthcareForm.Contracts.Auth;
using System.Data;
using System.Data.SqlClient;
using System.Security.Cryptography;
using System.Text;

namespace HealthcareForm.Services;

public sealed class AuthService : IAuthService
{
    private const int MaxFailedAttempts = 5;
    private static readonly TimeSpan LockoutWindow = TimeSpan.FromMinutes(15);

    private readonly IConfiguration _configuration;
    private readonly ILogger<AuthService> _logger;

    public AuthService(IConfiguration configuration, ILogger<AuthService> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<AuthLoginResult> AuthenticateAsync(string usernameOrEmail, string password, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(usernameOrEmail) || string.IsNullOrWhiteSpace(password))
        {
            return new AuthLoginResult
            {
                Success = false,
                Message = "Username/email and password are required."
            };
        }

        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await connection.OpenAsync(cancellationToken);

            var userRecord = await GetUserAsync(connection, usernameOrEmail.Trim(), cancellationToken);
            if (userRecord is null)
            {
                return new AuthLoginResult
                {
                    Success = false,
                    Message = "Invalid username/email or password."
                };
            }

            if (!userRecord.IsActive)
            {
                return new AuthLoginResult
                {
                    Success = false,
                    Message = "User account is inactive."
                };
            }

            if (userRecord.AccountLockedUntilUtc.HasValue && userRecord.AccountLockedUntilUtc.Value > DateTime.UtcNow)
            {
                return new AuthLoginResult
                {
                    Success = false,
                    Message = "Account is temporarily locked due to failed login attempts."
                };
            }

            var passwordValid = VerifyPassword(password, userRecord.PasswordHash);
            if (!passwordValid)
            {
                await RegisterFailedAttemptAsync(connection, userRecord, cancellationToken);
                return new AuthLoginResult
                {
                    Success = false,
                    Message = "Invalid username/email or password."
                };
            }

            await ResetFailedAttemptsAndUpdateLastLoginAsync(connection, userRecord.UserId, cancellationToken);
            var roles = await GetUserRolesAsync(connection, userRecord.UserId, cancellationToken);

            return new AuthLoginResult
            {
                Success = true,
                Message = string.Empty,
                User = new AuthUserDto
                {
                    UserId = userRecord.UserId,
                    Username = userRecord.Username,
                    Email = userRecord.Email,
                    FirstName = userRecord.FirstName,
                    LastName = userRecord.LastName,
                    IsSuperAdmin = userRecord.IsSuperAdmin,
                    Roles = roles
                }
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Login failed for principal {Principal}.", usernameOrEmail);
            return new AuthLoginResult
            {
                Success = false,
                Message = "Unable to login right now. Please try again."
            };
        }
    }

    private async Task<UserRecord?> GetUserAsync(SqlConnection connection, string usernameOrEmail, CancellationToken cancellationToken)
    {
        await using var command = new SqlCommand("Auth.spGetUserByPrincipal", connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        command.Parameters.Add(new SqlParameter("@Principal", SqlDbType.VarChar, 250) { Value = usernameOrEmail });

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        return new UserRecord
        {
            UserId = reader.GetGuid(reader.GetOrdinal("UserId")),
            Username = reader.GetString(reader.GetOrdinal("Username")),
            Email = reader.GetString(reader.GetOrdinal("Email")),
            PasswordHash = reader.GetString(reader.GetOrdinal("PasswordHash")),
            FirstName = reader.GetString(reader.GetOrdinal("FirstName")),
            LastName = reader.GetString(reader.GetOrdinal("LastName")),
            IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
            IsSuperAdmin = reader.GetBoolean(reader.GetOrdinal("IsSuperAdmin")),
            FailedLoginAttempts = reader.GetInt32(reader.GetOrdinal("FailedLoginAttempts")),
            AccountLockedUntilUtc = reader.IsDBNull(reader.GetOrdinal("AccountLockedUntil"))
                ? null
                : reader.GetDateTime(reader.GetOrdinal("AccountLockedUntil"))
        };
    }

    private async Task<List<string>> GetUserRolesAsync(SqlConnection connection, Guid userId, CancellationToken cancellationToken)
    {
        var roles = new List<string>();

        await using var command = new SqlCommand("Auth.spGetUserActiveRoles", connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        command.Parameters.Add(new SqlParameter("@UserId", SqlDbType.UniqueIdentifier) { Value = userId });

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            roles.Add(reader.GetString(0));
        }

        return roles;
    }

    private async Task RegisterFailedAttemptAsync(SqlConnection connection, UserRecord userRecord, CancellationToken cancellationToken)
    {
        var newFailedCount = userRecord.FailedLoginAttempts + 1;
        var lockUntil = newFailedCount >= MaxFailedAttempts ? DateTime.UtcNow.Add(LockoutWindow) : (DateTime?)null;

        await using var command = new SqlCommand("Auth.spRegisterFailedLoginAttempt", connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        command.Parameters.Add(new SqlParameter("@FailedAttempts", SqlDbType.Int) { Value = newFailedCount });
        command.Parameters.Add(new SqlParameter("@AccountLockedUntilUtc", SqlDbType.DateTime)
        {
            Value = lockUntil.HasValue ? lockUntil.Value : DBNull.Value
        });
        command.Parameters.Add(new SqlParameter("@UserId", SqlDbType.UniqueIdentifier) { Value = userRecord.UserId });
        command.Parameters.Add(new SqlParameter("@UpdatedBy", SqlDbType.VarChar, 250) { Value = "API" });

        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private async Task ResetFailedAttemptsAndUpdateLastLoginAsync(SqlConnection connection, Guid userId, CancellationToken cancellationToken)
    {
        await using var command = new SqlCommand("Auth.spRegisterSuccessfulLogin", connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        command.Parameters.Add(new SqlParameter("@UserId", SqlDbType.UniqueIdentifier) { Value = userId });
        command.Parameters.Add(new SqlParameter("@UpdatedBy", SqlDbType.VarChar, 250) { Value = "API" });
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private string GetConnectionString()
    {
        var connection = _configuration.GetConnectionString("HealthcareEntity");
        if (string.IsNullOrWhiteSpace(connection) || connection.StartsWith("__SET_CONNECTIONSTRINGS__", StringComparison.Ordinal))
        {
            throw new InvalidOperationException("Connection string 'HealthcareEntity' is not configured.");
        }

        return connection;
    }

    private static bool VerifyPassword(string password, string storedHash)
    {
        if (string.IsNullOrWhiteSpace(storedHash))
        {
            return false;
        }

        if (storedHash.StartsWith("$2", StringComparison.Ordinal))
        {
            return BCrypt.Net.BCrypt.Verify(password, storedHash);
        }

        var input = Encoding.UTF8.GetBytes(password);
        var stored = Encoding.UTF8.GetBytes(storedHash);

        return input.Length == stored.Length && CryptographicOperations.FixedTimeEquals(input, stored);
    }

    private sealed class UserRecord
    {
        public Guid UserId { get; init; }
        public string Username { get; init; } = string.Empty;
        public string Email { get; init; } = string.Empty;
        public string PasswordHash { get; init; } = string.Empty;
        public string FirstName { get; init; } = string.Empty;
        public string LastName { get; init; } = string.Empty;
        public bool IsActive { get; init; }
        public bool IsSuperAdmin { get; init; }
        public DateTime? AccountLockedUntilUtc { get; init; }
        public int FailedLoginAttempts { get; init; }
    }
}
