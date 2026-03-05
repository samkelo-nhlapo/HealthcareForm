using HealthcareForm.Contracts.Admin;
using System.Data;
using System.Data.SqlClient;

namespace HealthcareForm.Services;

public sealed class AdminService : IAdminService
{
    private const string ConnectionStringKey = "HealthcareEntity";
    private const int MaxAuditEvents = 500;
    private const int DefaultAuditPageSize = 50;
    private const int MaxAuditPageSize = 200;

    private static readonly string[] DefaultRoleColumns =
    [
        "ADMIN",
        "DOCTOR",
        "NURSE",
        "BILLING",
        "RECEPTIONIST",
        "PHARMACIST"
    ];

    private readonly IConfiguration _configuration;
    private readonly IHostEnvironment _hostEnvironment;
    private readonly ILogger<AdminService> _logger;

    public AdminService(
        IConfiguration configuration,
        IHostEnvironment hostEnvironment,
        ILogger<AdminService> logger)
    {
        _configuration = configuration;
        _hostEnvironment = hostEnvironment;
        _logger = logger;
    }

    public async Task<AdminAccessControlSnapshotDto> GetAccessControlAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await connection.OpenAsync(cancellationToken);

            return await GetAccessControlSnapshotFromProcedureAsync(connection, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to build admin access-control snapshot.");
            return new AdminAccessControlSnapshotDto
            {
                RoleColumns = DefaultRoleColumns,
                Users = [],
                Permissions = []
            };
        }
    }

    private async Task<AdminAccessControlSnapshotDto> GetAccessControlSnapshotFromProcedureAsync(
        SqlConnection connection,
        CancellationToken cancellationToken)
    {
        var roleColumns = new List<string>();
        var usersById = new Dictionary<Guid, AccessUserAccumulator>();
        var permissionsByKey = new Dictionary<string, PermissionAccumulator>(StringComparer.OrdinalIgnoreCase);

        await using var command = new SqlCommand("Auth.spGetAdminAccessControlSnapshot", connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        var roleNameOrdinal = reader.GetOrdinal("RoleName");
        while (await reader.ReadAsync(cancellationToken))
        {
            var roleName = GetString(reader, roleNameOrdinal).Trim().ToUpperInvariant();
            if (!string.IsNullOrWhiteSpace(roleName))
            {
                roleColumns.Add(roleName);
            }
        }

        if (roleColumns.Count == 0)
        {
            roleColumns.AddRange(DefaultRoleColumns);
        }

        if (await reader.NextResultAsync(cancellationToken))
        {
            var userIdOrdinal = reader.GetOrdinal("UserId");
            var usernameOrdinal = reader.GetOrdinal("Username");
            var emailOrdinal = reader.GetOrdinal("Email");
            var firstNameOrdinal = reader.GetOrdinal("FirstName");
            var lastNameOrdinal = reader.GetOrdinal("LastName");
            var isActiveOrdinal = reader.GetOrdinal("IsActive");
            var accountLockedUntilOrdinal = reader.GetOrdinal("AccountLockedUntil");
            var failedLoginAttemptsOrdinal = reader.GetOrdinal("FailedLoginAttempts");
            var lastLoginDateOrdinal = reader.GetOrdinal("LastLoginDate");
            var mustChangePasswordOrdinal = reader.GetOrdinal("MustChangePasswordOnLogin");
            var accessRoleNameOrdinal = reader.GetOrdinal("RoleName");

            while (await reader.ReadAsync(cancellationToken))
            {
                var userId = reader.GetGuid(userIdOrdinal);
                if (!usersById.TryGetValue(userId, out var user))
                {
                    user = new AccessUserAccumulator
                    {
                        Username = GetString(reader, usernameOrdinal),
                        FullName = BuildFullName(
                            GetString(reader, firstNameOrdinal),
                            GetString(reader, lastNameOrdinal)),
                        Email = GetString(reader, emailOrdinal),
                        IsActive = GetBoolean(reader, isActiveOrdinal),
                        AccountLockedUntil = GetNullableDateTime(reader, accountLockedUntilOrdinal),
                        FailedLoginAttempts = GetInt32(reader, failedLoginAttemptsOrdinal),
                        MustChangePasswordOnLogin = GetBoolean(reader, mustChangePasswordOrdinal),
                        LastLoginDate = GetNullableDateTime(reader, lastLoginDateOrdinal)
                    };

                    usersById[userId] = user;
                }

                var roleName = GetString(reader, accessRoleNameOrdinal).Trim().ToUpperInvariant();
                if (!string.IsNullOrWhiteSpace(roleName) && !roleName.Equals("PATIENT", StringComparison.OrdinalIgnoreCase))
                {
                    user.Roles.Add(roleName);
                }
            }
        }

        if (await reader.NextResultAsync(cancellationToken))
        {
            var permissionNameOrdinal = reader.GetOrdinal("PermissionName");
            var moduleOrdinal = reader.GetOrdinal("Module");
            var actionOrdinal = reader.GetOrdinal("ActionType");
            var permissionRoleNameOrdinal = reader.GetOrdinal("RoleName");

            while (await reader.ReadAsync(cancellationToken))
            {
                var permissionName = GetString(reader, permissionNameOrdinal);
                var module = GetString(reader, moduleOrdinal).ToUpperInvariant();
                var action = GetString(reader, actionOrdinal).ToUpperInvariant();
                var key = $"{permissionName}|{module}|{action}";

                if (!permissionsByKey.TryGetValue(key, out var permission))
                {
                    permission = new PermissionAccumulator
                    {
                        PermissionName = permissionName,
                        Module = module,
                        Action = action
                    };

                    permissionsByKey[key] = permission;
                }

                var roleName = GetString(reader, permissionRoleNameOrdinal).Trim().ToUpperInvariant();
                if (!string.IsNullOrWhiteSpace(roleName) && !roleName.Equals("PATIENT", StringComparison.OrdinalIgnoreCase))
                {
                    permission.Roles.Add(roleName);
                }
            }
        }

        return new AdminAccessControlSnapshotDto
        {
            RoleColumns = roleColumns
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .OrderBy(GetRoleSortOrder)
                .ThenBy(item => item, StringComparer.OrdinalIgnoreCase)
                .ToList(),
            Users = usersById.Values
                .Select(user => new AdminAccessUserDto
                {
                    Username = user.Username,
                    FullName = user.FullName,
                    Email = user.Email,
                    Roles = user.Roles
                        .OrderBy(GetRoleSortOrder)
                        .ThenBy(item => item, StringComparer.OrdinalIgnoreCase)
                        .ToList(),
                    Status = ResolveUserStatus(user.IsActive, user.AccountLockedUntil, user.FailedLoginAttempts),
                    Mfa = user.MustChangePasswordOnLogin ? "Pending" : "Enrolled",
                    LastLogin = user.LastLoginDate.HasValue
                        ? user.LastLoginDate.Value.ToString("yyyy-MM-dd HH:mm")
                        : "Never"
                })
                .OrderBy(user => user.Username, StringComparer.OrdinalIgnoreCase)
                .ToList(),
            Permissions = permissionsByKey.Values
                .Select(permission => new AdminPermissionMatrixRowDto
                {
                    PermissionName = permission.PermissionName,
                    Module = permission.Module,
                    Action = permission.Action,
                    Roles = permission.Roles
                        .OrderBy(GetRoleSortOrder)
                        .ThenBy(item => item, StringComparer.OrdinalIgnoreCase)
                        .ToList()
                })
                .OrderBy(item => item.Module, StringComparer.OrdinalIgnoreCase)
                .ThenBy(item => item.PermissionName, StringComparer.OrdinalIgnoreCase)
                .ToList()
        };
    }

    public async Task<AdminAuditLogSnapshotDto> GetAuditLogAsync(
        AdminAuditLogQueryDto query,
        CancellationToken cancellationToken = default)
    {
        var normalizedQuery = NormalizeAuditLogQuery(query);

        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await connection.OpenAsync(cancellationToken);

            var events = await GetAuditEventSourceRowsAsync(connection, cancellationToken);

            var orderedEvents = events
                .OrderByDescending(item => item.OccurredAtUtc)
                .Take(MaxAuditEvents)
                .ToList();

            var actorOptions = orderedEvents
                .Select(item => item.Actor)
                .Where(actor => !string.IsNullOrWhiteSpace(actor))
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .OrderBy(actor => actor, StringComparer.OrdinalIgnoreCase)
                .ToList();

            var filteredEvents = ApplyAuditLogFilters(orderedEvents, normalizedQuery);
            var totalCount = filteredEvents.Count;
            var totalPages = totalCount == 0
                ? 0
                : (int)Math.Ceiling(totalCount / (double)normalizedQuery.PageSize);
            var pageOffset = (normalizedQuery.Page - 1) * normalizedQuery.PageSize;
            var pagedEvents = filteredEvents
                .Skip(pageOffset)
                .Take(normalizedQuery.PageSize)
                .ToList();

            return new AdminAuditLogSnapshotDto
            {
                ActorOptions = actorOptions,
                Events = pagedEvents,
                Page = normalizedQuery.Page,
                PageSize = normalizedQuery.PageSize,
                TotalCount = totalCount,
                TotalPages = totalPages
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to build admin audit-log snapshot.");
            return new AdminAuditLogSnapshotDto
            {
                ActorOptions = [],
                Events = [],
                Page = normalizedQuery.Page,
                PageSize = normalizedQuery.PageSize,
                TotalCount = 0,
                TotalPages = 0
            };
        }
    }

    private async Task<IReadOnlyList<AdminAuditEventDto>> GetAuditEventSourceRowsAsync(
        SqlConnection connection,
        CancellationToken cancellationToken)
    {
        var events = new List<AdminAuditEventDto>(capacity: MaxAuditEvents * 2);

        await using var command = new SqlCommand("Auth.spGetAdminAuditEventSourceRows", connection)
        {
            CommandType = CommandType.StoredProcedure
        };
        command.Parameters.Add(new SqlParameter("@MaxRows", MaxAuditEvents));

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        var occurredAtOrdinal = reader.GetOrdinal("OccurredAtUtc");
        var actorOrdinal = reader.GetOrdinal("Actor");
        var actorRoleOrdinal = reader.GetOrdinal("ActorRole");
        var activityTypeOrdinal = reader.GetOrdinal("ActivityType");
        var resourceOrdinal = reader.GetOrdinal("Resource");
        var eventNameOrdinal = reader.GetOrdinal("EventName");
        var statusOrdinal = reader.GetOrdinal("Status");
        var ipAddressOrdinal = reader.GetOrdinal("IpAddress");
        var correlationIdOrdinal = reader.GetOrdinal("CorrelationId");

        while (await reader.ReadAsync(cancellationToken))
        {
            var activityType = GetString(reader, activityTypeOrdinal);
            var resource = GetString(reader, resourceOrdinal, "Auth.AuditLog");
            var eventName = GetString(reader, eventNameOrdinal, activityType);
            var actorRole = NormalizeRole(GetString(reader, actorRoleOrdinal), "ANONYMOUS");
            var category = CategorizeAuditEvent(activityType, resource, eventName);

            events.Add(new AdminAuditEventDto
            {
                OccurredAtUtc = ToUtc(GetDateTime(reader, occurredAtOrdinal, DateTime.UtcNow)),
                Actor = GetString(reader, actorOrdinal, "unknown"),
                ActorRole = actorRole,
                Category = category,
                EventName = eventName,
                Resource = resource,
                Outcome = NormalizeOutcome(GetString(reader, statusOrdinal)),
                IpAddress = GetString(reader, ipAddressOrdinal, "N/A"),
                CorrelationId = GetString(reader, correlationIdOrdinal),
                Privileged = IsPrivileged(actorRole, category, resource, eventName)
            });
        }

        return events;
    }

    public async Task<AdminDataGovernanceSnapshotDto> GetDataGovernanceAsync(CancellationToken cancellationToken = default)
    {
        var configurationItems = BuildConfigurationItems();

        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await connection.OpenAsync(cancellationToken);

            var source = await GetDataGovernanceSourceRowsFromProcedureAsync(connection, cancellationToken);

            return new AdminDataGovernanceSnapshotDto
            {
                ConfigurationItems = configurationItems,
                TemplateItems = source.TemplateItems,
                LookupItems = source.LookupItems
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to build admin data-governance snapshot.");
            return new AdminDataGovernanceSnapshotDto
            {
                ConfigurationItems = configurationItems,
                TemplateItems = [],
                LookupItems = []
            };
        }
    }

    private async Task<GovernanceSourceSnapshot> GetDataGovernanceSourceRowsFromProcedureAsync(
        SqlConnection connection,
        CancellationToken cancellationToken)
    {
        var templateItems = new List<AdminTemplateGovernanceItemDto>();
        var lookupItems = new List<AdminLookupHealthItemDto>();

        await using var command = new SqlCommand("Auth.spGetAdminDataGovernanceSourceRows", connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        var templateNameOrdinal = reader.GetOrdinal("FormName");
        var versionOrdinal = reader.GetOrdinal("FormVersion");
        var isActiveOrdinal = reader.GetOrdinal("IsActive");
        var ownerOrdinal = reader.GetOrdinal("Owner");
        var templateUpdatedDateOrdinal = reader.GetOrdinal("TemplateUpdatedDate");
        var lastApprovedDateOrdinal = reader.GetOrdinal("LastApprovedDate");
        var hasDraftOrdinal = reader.GetOrdinal("HasDraft");

        while (await reader.ReadAsync(cancellationToken))
        {
            var isActive = GetBoolean(reader, isActiveOrdinal);
            var hasDraft = GetInt32(reader, hasDraftOrdinal) > 0;
            var status = !isActive
                ? "Retired"
                : hasDraft
                    ? "Draft"
                    : "Published";

            var templateUpdated = GetNullableDateTime(reader, templateUpdatedDateOrdinal) ?? DateTime.UtcNow;
            var lastApproved = GetNullableDateTime(reader, lastApprovedDateOrdinal) ?? templateUpdated;
            var nextReview = lastApproved.AddDays(30);

            templateItems.Add(new AdminTemplateGovernanceItemDto
            {
                TemplateName = GetString(reader, templateNameOrdinal),
                Version = GetString(reader, versionOrdinal),
                Status = status,
                Owner = GetString(reader, ownerOrdinal, "Operations"),
                LastApproved = lastApproved.ToString("yyyy-MM-dd"),
                NextReview = nextReview.ToString("yyyy-MM-dd")
            });
        }

        if (await reader.NextResultAsync(cancellationToken))
        {
            var lookupNameOrdinal = reader.GetOrdinal("LookupName");
            var recordsOrdinal = reader.GetOrdinal("Records");
            var lastSyncOrdinal = reader.GetOrdinal("LastSync");
            var sourceOrdinal = reader.GetOrdinal("Source");
            var refreshCadenceOrdinal = reader.GetOrdinal("RefreshCadence");

            while (await reader.ReadAsync(cancellationToken))
            {
                var records = GetInt32(reader, recordsOrdinal);
                var lastSync = GetNullableDateTime(reader, lastSyncOrdinal);
                var refreshCadence = GetString(reader, refreshCadenceOrdinal);

                lookupItems.Add(new AdminLookupHealthItemDto
                {
                    Name = GetString(reader, lookupNameOrdinal),
                    Records = records,
                    Source = GetString(reader, sourceOrdinal),
                    RefreshCadence = refreshCadence,
                    LastSync = lastSync.HasValue
                        ? lastSync.Value.ToString("yyyy-MM-dd HH:mm")
                        : "N/A",
                    State = ResolveLookupHealthState(records, lastSync, refreshCadence)
                });
            }
        }

        return new GovernanceSourceSnapshot
        {
            TemplateItems = templateItems,
            LookupItems = lookupItems
        };
    }

    private async Task<IReadOnlyList<string>> GetRoleColumnsAsync(SqlConnection connection, CancellationToken cancellationToken)
    {
        var roles = new List<string>();

        await using var command = new SqlCommand(
            @"
SELECT R.RoleName
FROM Auth.Roles R
WHERE R.IsActive = 1
  AND R.RoleName <> 'PATIENT';",
            connection);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            var roleName = GetString(reader, 0).Trim().ToUpperInvariant();
            if (!string.IsNullOrWhiteSpace(roleName))
            {
                roles.Add(roleName);
            }
        }

        if (roles.Count == 0)
        {
            return DefaultRoleColumns;
        }

        return roles
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .OrderBy(GetRoleSortOrder)
            .ThenBy(item => item, StringComparer.OrdinalIgnoreCase)
            .ToList();
    }

    private async Task<IReadOnlyList<AdminAccessUserDto>> GetAccessUsersAsync(SqlConnection connection, CancellationToken cancellationToken)
    {
        var usersById = new Dictionary<Guid, AccessUserAccumulator>();

        await using var command = new SqlCommand(
            @"
SELECT
    U.UserId,
    U.Username,
    U.Email,
    U.FirstName,
    U.LastName,
    U.IsActive,
    U.AccountLockedUntil,
    U.FailedLoginAttempts,
    U.LastLoginDate,
    U.MustChangePasswordOnLogin,
    R.RoleName
FROM Auth.Users U
LEFT JOIN Auth.UserRoles UR
    ON UR.UserIdFK = U.UserId
   AND UR.IsActive = 1
   AND (UR.ExpiryDate IS NULL OR UR.ExpiryDate > GETDATE())
LEFT JOIN Auth.Roles R
    ON R.RoleId = UR.RoleIdFK
   AND R.IsActive = 1
ORDER BY U.Username;",
            connection);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        var userIdOrdinal = reader.GetOrdinal("UserId");
        var usernameOrdinal = reader.GetOrdinal("Username");
        var emailOrdinal = reader.GetOrdinal("Email");
        var firstNameOrdinal = reader.GetOrdinal("FirstName");
        var lastNameOrdinal = reader.GetOrdinal("LastName");
        var isActiveOrdinal = reader.GetOrdinal("IsActive");
        var accountLockedUntilOrdinal = reader.GetOrdinal("AccountLockedUntil");
        var failedLoginAttemptsOrdinal = reader.GetOrdinal("FailedLoginAttempts");
        var lastLoginDateOrdinal = reader.GetOrdinal("LastLoginDate");
        var mustChangePasswordOrdinal = reader.GetOrdinal("MustChangePasswordOnLogin");
        var roleNameOrdinal = reader.GetOrdinal("RoleName");

        while (await reader.ReadAsync(cancellationToken))
        {
            var userId = reader.GetGuid(userIdOrdinal);
            if (!usersById.TryGetValue(userId, out var user))
            {
                user = new AccessUserAccumulator
                {
                    Username = GetString(reader, usernameOrdinal),
                    FullName = BuildFullName(
                        GetString(reader, firstNameOrdinal),
                        GetString(reader, lastNameOrdinal)),
                    Email = GetString(reader, emailOrdinal),
                    IsActive = GetBoolean(reader, isActiveOrdinal),
                    AccountLockedUntil = GetNullableDateTime(reader, accountLockedUntilOrdinal),
                    FailedLoginAttempts = GetInt32(reader, failedLoginAttemptsOrdinal),
                    MustChangePasswordOnLogin = GetBoolean(reader, mustChangePasswordOrdinal),
                    LastLoginDate = GetNullableDateTime(reader, lastLoginDateOrdinal)
                };

                usersById[userId] = user;
            }

            var roleName = GetString(reader, roleNameOrdinal).Trim().ToUpperInvariant();
            if (!string.IsNullOrWhiteSpace(roleName) && !roleName.Equals("PATIENT", StringComparison.OrdinalIgnoreCase))
            {
                user.Roles.Add(roleName);
            }
        }

        return usersById.Values
            .Select(user => new AdminAccessUserDto
            {
                Username = user.Username,
                FullName = user.FullName,
                Email = user.Email,
                Roles = user.Roles
                    .OrderBy(GetRoleSortOrder)
                    .ThenBy(item => item, StringComparer.OrdinalIgnoreCase)
                    .ToList(),
                Status = ResolveUserStatus(user.IsActive, user.AccountLockedUntil, user.FailedLoginAttempts),
                Mfa = user.MustChangePasswordOnLogin ? "Pending" : "Enrolled",
                LastLogin = user.LastLoginDate.HasValue
                    ? user.LastLoginDate.Value.ToString("yyyy-MM-dd HH:mm")
                    : "Never"
            })
            .OrderBy(user => user.Username, StringComparer.OrdinalIgnoreCase)
            .ToList();
    }

    private async Task<IReadOnlyList<AdminPermissionMatrixRowDto>> GetPermissionMatrixAsync(SqlConnection connection, CancellationToken cancellationToken)
    {
        var permissionsByKey = new Dictionary<string, PermissionAccumulator>(StringComparer.OrdinalIgnoreCase);

        await using var command = new SqlCommand(
            @"
SELECT
    P.PermissionName,
    P.Module,
    P.ActionType,
    R.RoleName
FROM Auth.Permissions P
LEFT JOIN Auth.RolePermissions RP
    ON RP.PermissionIdFK = P.PermissionId
   AND RP.IsActive = 1
LEFT JOIN Auth.Roles R
    ON R.RoleId = RP.RoleIdFK
   AND R.IsActive = 1
WHERE P.IsActive = 1
ORDER BY P.Module, P.PermissionName;",
            connection);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        var permissionNameOrdinal = reader.GetOrdinal("PermissionName");
        var moduleOrdinal = reader.GetOrdinal("Module");
        var actionOrdinal = reader.GetOrdinal("ActionType");
        var roleNameOrdinal = reader.GetOrdinal("RoleName");

        while (await reader.ReadAsync(cancellationToken))
        {
            var permissionName = GetString(reader, permissionNameOrdinal);
            var module = GetString(reader, moduleOrdinal).ToUpperInvariant();
            var action = GetString(reader, actionOrdinal).ToUpperInvariant();
            var key = $"{permissionName}|{module}|{action}";

            if (!permissionsByKey.TryGetValue(key, out var permission))
            {
                permission = new PermissionAccumulator
                {
                    PermissionName = permissionName,
                    Module = module,
                    Action = action
                };

                permissionsByKey[key] = permission;
            }

            var roleName = GetString(reader, roleNameOrdinal).Trim().ToUpperInvariant();
            if (!string.IsNullOrWhiteSpace(roleName) && !roleName.Equals("PATIENT", StringComparison.OrdinalIgnoreCase))
            {
                permission.Roles.Add(roleName);
            }
        }

        return permissionsByKey.Values
            .Select(permission => new AdminPermissionMatrixRowDto
            {
                PermissionName = permission.PermissionName,
                Module = permission.Module,
                Action = permission.Action,
                Roles = permission.Roles
                    .OrderBy(GetRoleSortOrder)
                    .ThenBy(item => item, StringComparer.OrdinalIgnoreCase)
                    .ToList()
            })
            .OrderBy(item => item.Module, StringComparer.OrdinalIgnoreCase)
            .ThenBy(item => item.PermissionName, StringComparer.OrdinalIgnoreCase)
            .ToList();
    }

    private async Task<Dictionary<string, string>> GetPrincipalRoleMapAsync(SqlConnection connection, CancellationToken cancellationToken)
    {
        var map = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

        await using var command = new SqlCommand(
            @"
SELECT
    U.Username,
    U.Email,
    COALESCE(RolePick.RoleName, CASE WHEN U.IsSuperAdmin = 1 THEN 'ADMIN' ELSE 'USER' END) AS PrimaryRole
FROM Auth.Users U
OUTER APPLY
(
    SELECT TOP (1) R.RoleName
    FROM Auth.UserRoles UR
    INNER JOIN Auth.Roles R
        ON R.RoleId = UR.RoleIdFK
       AND R.IsActive = 1
    WHERE UR.UserIdFK = U.UserId
      AND UR.IsActive = 1
      AND (UR.ExpiryDate IS NULL OR UR.ExpiryDate > GETDATE())
    ORDER BY
        CASE R.RoleName
            WHEN 'ADMIN' THEN 0
            WHEN 'DOCTOR' THEN 1
            WHEN 'NURSE' THEN 2
            WHEN 'BILLING' THEN 3
            WHEN 'RECEPTIONIST' THEN 4
            WHEN 'PHARMACIST' THEN 5
            ELSE 99
        END,
        R.RoleName
) RolePick;",
            connection);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        var usernameOrdinal = reader.GetOrdinal("Username");
        var emailOrdinal = reader.GetOrdinal("Email");
        var roleOrdinal = reader.GetOrdinal("PrimaryRole");

        while (await reader.ReadAsync(cancellationToken))
        {
            var role = NormalizeRole(GetString(reader, roleOrdinal), "USER");
            var username = GetString(reader, usernameOrdinal);
            var email = GetString(reader, emailOrdinal);

            if (!string.IsNullOrWhiteSpace(username))
            {
                map[username] = role;
            }

            if (!string.IsNullOrWhiteSpace(email))
            {
                map[email] = role;
            }
        }

        return map;
    }

    private async Task<IReadOnlyList<AdminAuditEventDto>> GetUserActivityEventsAsync(SqlConnection connection, CancellationToken cancellationToken)
    {
        var events = new List<AdminAuditEventDto>();

        await using var command = new SqlCommand(
            $@"
SELECT TOP ({MaxAuditEvents})
    UAA.UserActivityId,
    UAA.ActivityDateTime,
    COALESCE(NULLIF(U.Username, ''), 'unknown') AS Actor,
    COALESCE(NULLIF(RolePick.RoleName, ''), 'ANONYMOUS') AS ActorRole,
    UAA.ActivityType,
    UAA.TableName,
    UAA.Description,
    UAA.Status,
    UAA.IPAddress
FROM Auth.UserActivityAudit UAA
LEFT JOIN Auth.Users U
    ON U.UserId = UAA.UserIdFK
OUTER APPLY
(
    SELECT TOP (1) R.RoleName
    FROM Auth.UserRoles UR
    INNER JOIN Auth.Roles R
        ON R.RoleId = UR.RoleIdFK
       AND R.IsActive = 1
    WHERE UR.UserIdFK = UAA.UserIdFK
      AND UR.IsActive = 1
      AND (UR.ExpiryDate IS NULL OR UR.ExpiryDate > GETDATE())
    ORDER BY
        CASE R.RoleName
            WHEN 'ADMIN' THEN 0
            WHEN 'DOCTOR' THEN 1
            WHEN 'NURSE' THEN 2
            WHEN 'BILLING' THEN 3
            WHEN 'RECEPTIONIST' THEN 4
            WHEN 'PHARMACIST' THEN 5
            ELSE 99
        END,
        R.RoleName
) RolePick
ORDER BY UAA.ActivityDateTime DESC;",
            connection);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        var userActivityIdOrdinal = reader.GetOrdinal("UserActivityId");
        var occurredAtOrdinal = reader.GetOrdinal("ActivityDateTime");
        var actorOrdinal = reader.GetOrdinal("Actor");
        var actorRoleOrdinal = reader.GetOrdinal("ActorRole");
        var activityTypeOrdinal = reader.GetOrdinal("ActivityType");
        var tableNameOrdinal = reader.GetOrdinal("TableName");
        var descriptionOrdinal = reader.GetOrdinal("Description");
        var statusOrdinal = reader.GetOrdinal("Status");
        var ipAddressOrdinal = reader.GetOrdinal("IPAddress");

        while (await reader.ReadAsync(cancellationToken))
        {
            var activityType = GetString(reader, activityTypeOrdinal);
            var resource = GetString(reader, tableNameOrdinal);
            if (string.IsNullOrWhiteSpace(resource))
            {
                resource = "Auth.UserActivityAudit";
            }

            var eventName = GetString(reader, descriptionOrdinal);
            if (string.IsNullOrWhiteSpace(eventName))
            {
                eventName = activityType;
            }

            var actorRole = NormalizeRole(GetString(reader, actorRoleOrdinal), "ANONYMOUS");
            var category = CategorizeAuditEvent(activityType, resource, eventName);
            var correlationId = $"UA-{reader.GetGuid(userActivityIdOrdinal).ToString("N")[..8].ToUpperInvariant()}";

            events.Add(new AdminAuditEventDto
            {
                OccurredAtUtc = ToUtc(reader.GetDateTime(occurredAtOrdinal)),
                Actor = GetString(reader, actorOrdinal),
                ActorRole = actorRole,
                Category = category,
                EventName = eventName,
                Resource = resource,
                Outcome = NormalizeOutcome(GetString(reader, statusOrdinal)),
                IpAddress = GetString(reader, ipAddressOrdinal, "N/A"),
                CorrelationId = correlationId,
                Privileged = IsPrivileged(actorRole, category, resource, eventName)
            });
        }

        return events;
    }

    private async Task<IReadOnlyList<AdminAuditEventDto>> GetTableAuditEventsAsync(
        SqlConnection connection,
        IReadOnlyDictionary<string, string> principalRoleMap,
        CancellationToken cancellationToken)
    {
        var events = new List<AdminAuditEventDto>();

        await using var command = new SqlCommand(
            $@"
SELECT TOP ({MaxAuditEvents})
    AL.AuditLogID,
    AL.ModifiedTime,
    AL.ModifiedBy,
    AL.Operation,
    AL.SchemaName,
    AL.TableName
FROM Auth.AuditLog AL
ORDER BY AL.ModifiedTime DESC;",
            connection);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        var auditLogIdOrdinal = reader.GetOrdinal("AuditLogID");
        var modifiedTimeOrdinal = reader.GetOrdinal("ModifiedTime");
        var modifiedByOrdinal = reader.GetOrdinal("ModifiedBy");
        var operationOrdinal = reader.GetOrdinal("Operation");
        var schemaNameOrdinal = reader.GetOrdinal("SchemaName");
        var tableNameOrdinal = reader.GetOrdinal("TableName");

        while (await reader.ReadAsync(cancellationToken))
        {
            var actor = GetString(reader, modifiedByOrdinal, "SYSTEM");
            var actorRole = ResolveActorRole(actor, principalRoleMap);
            var operation = GetString(reader, operationOrdinal);
            var schemaName = GetString(reader, schemaNameOrdinal);
            var tableName = GetString(reader, tableNameOrdinal);
            var resource = string.IsNullOrWhiteSpace(schemaName) || string.IsNullOrWhiteSpace(tableName)
                ? "Auth.AuditLog"
                : $"{schemaName}.{tableName}";
            var category = CategorizeAuditEvent(operation, resource, operation);
            var auditLogId = GetInt32(reader, auditLogIdOrdinal);

            events.Add(new AdminAuditEventDto
            {
                OccurredAtUtc = ToUtc(reader.GetDateTime(modifiedTimeOrdinal)),
                Actor = actor,
                ActorRole = actorRole,
                Category = category,
                EventName = operation,
                Resource = resource,
                Outcome = "Success",
                IpAddress = "N/A",
                CorrelationId = $"AL-{auditLogId:D6}",
                Privileged = IsPrivileged(actorRole, category, resource, operation)
            });
        }

        return events;
    }

    private IReadOnlyList<AdminConfigurationItemDto> BuildConfigurationItems()
    {
        var appSettingsUpdatedAt = ResolveAppSettingsUpdatedAt();
        var corsOrigins = _configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? [];
        var corsCurrentValue = corsOrigins.Length > 0
            ? string.Join(", ", corsOrigins)
            : "(none)";

        var tokenExpiryCurrentValue = _configuration["Jwt:TokenExpiryMinutes"] ?? "60";
        var httpsCurrentValue = _configuration
            .GetValue("HttpsRedirection:Enabled", false)
            .ToString()
            .ToLowerInvariant();

        return
        [
            BuildConfigurationItem(
                key: "Cors:AllowedOrigins",
                owner: "Platform Team",
                currentValue: corsCurrentValue,
                baselineValue: "http://localhost:4200",
                lastUpdated: appSettingsUpdatedAt),
            BuildConfigurationItem(
                key: "Jwt:TokenExpiryMinutes",
                owner: "Security Team",
                currentValue: tokenExpiryCurrentValue,
                baselineValue: "30",
                lastUpdated: appSettingsUpdatedAt),
            BuildConfigurationItem(
                key: "HttpsRedirection:Enabled",
                owner: "Security Team",
                currentValue: httpsCurrentValue,
                baselineValue: "true",
                lastUpdated: appSettingsUpdatedAt)
        ];
    }

    private static AdminConfigurationItemDto BuildConfigurationItem(
        string key,
        string owner,
        string currentValue,
        string baselineValue,
        string lastUpdated)
    {
        return new AdminConfigurationItemDto
        {
            Key = key,
            Scope = "API",
            CurrentValue = currentValue,
            BaselineValue = baselineValue,
            LastUpdated = lastUpdated,
            Owner = owner,
            State = string.Equals(currentValue.Trim(), baselineValue.Trim(), StringComparison.OrdinalIgnoreCase)
                ? "Aligned"
                : "Drift"
        };
    }


    private static string ResolveUserStatus(bool isActive, DateTime? accountLockedUntil, int failedLoginAttempts)
    {
        if (!isActive)
        {
            return "Inactive";
        }

        if (accountLockedUntil.HasValue && accountLockedUntil.Value > DateTime.Now)
        {
            return "Locked";
        }

        return failedLoginAttempts >= 5
            ? "Locked"
            : "Active";
    }

    private static string BuildFullName(string firstName, string lastName)
    {
        var fullName = $"{firstName} {lastName}".Trim();
        return string.IsNullOrWhiteSpace(fullName)
            ? "Unknown User"
            : fullName;
    }

    private static AuditLogQueryNormalized NormalizeAuditLogQuery(AdminAuditLogQueryDto query)
    {
        var page = query.Page <= 0 ? 1 : query.Page;
        var pageSize = query.PageSize <= 0
            ? DefaultAuditPageSize
            : Math.Min(query.PageSize, MaxAuditPageSize);

        DateTime? fromUtc = query.FromUtc.HasValue ? ToUtc(query.FromUtc.Value) : null;
        DateTime? toUtc = query.ToUtc.HasValue ? ToUtc(query.ToUtc.Value) : null;

        if (fromUtc.HasValue && toUtc.HasValue && fromUtc.Value > toUtc.Value)
        {
            (fromUtc, toUtc) = (toUtc, fromUtc);
        }

        return new AuditLogQueryNormalized
        {
            Actor = NormalizeFilterValue(query.Actor),
            Category = NormalizeFilterValue(query.Category),
            Outcome = NormalizeFilterValue(query.Outcome),
            Search = NormalizeFilterValue(query.Search),
            PrivilegedOnly = query.PrivilegedOnly ?? false,
            FromUtc = fromUtc,
            ToUtc = toUtc,
            Page = page,
            PageSize = pageSize
        };
    }

    private static List<AdminAuditEventDto> ApplyAuditLogFilters(
        IReadOnlyList<AdminAuditEventDto> events,
        AuditLogQueryNormalized query)
    {
        return events
            .Where(eventItem =>
                (query.Actor is null || eventItem.Actor.Equals(query.Actor, StringComparison.OrdinalIgnoreCase))
                && (query.Category is null || eventItem.Category.Equals(query.Category, StringComparison.OrdinalIgnoreCase))
                && (query.Outcome is null || eventItem.Outcome.Equals(query.Outcome, StringComparison.OrdinalIgnoreCase))
                && (!query.FromUtc.HasValue || eventItem.OccurredAtUtc >= query.FromUtc.Value)
                && (!query.ToUtc.HasValue || eventItem.OccurredAtUtc <= query.ToUtc.Value)
                && (!query.PrivilegedOnly || eventItem.Privileged)
                && (query.Search is null || MatchesAuditLogSearch(eventItem, query.Search)))
            .ToList();
    }

    private static bool MatchesAuditLogSearch(AdminAuditEventDto eventItem, string search)
    {
        return eventItem.Actor.Contains(search, StringComparison.OrdinalIgnoreCase)
            || eventItem.ActorRole.Contains(search, StringComparison.OrdinalIgnoreCase)
            || eventItem.Category.Contains(search, StringComparison.OrdinalIgnoreCase)
            || eventItem.EventName.Contains(search, StringComparison.OrdinalIgnoreCase)
            || eventItem.Resource.Contains(search, StringComparison.OrdinalIgnoreCase)
            || eventItem.Outcome.Contains(search, StringComparison.OrdinalIgnoreCase)
            || eventItem.IpAddress.Contains(search, StringComparison.OrdinalIgnoreCase)
            || eventItem.CorrelationId.Contains(search, StringComparison.OrdinalIgnoreCase);
    }

    private static string? NormalizeFilterValue(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        var normalized = value.Trim();
        return normalized.Equals("ALL", StringComparison.OrdinalIgnoreCase)
            ? null
            : normalized;
    }

    private static int GetRoleSortOrder(string role)
    {
        return role.ToUpperInvariant() switch
        {
            "ADMIN" => 0,
            "DOCTOR" => 1,
            "NURSE" => 2,
            "BILLING" => 3,
            "RECEPTIONIST" => 4,
            "PHARMACIST" => 5,
            _ => 99
        };
    }

    private static string CategorizeAuditEvent(string activityType, string resource, string eventName)
    {
        var text = $"{activityType} {resource} {eventName}".ToUpperInvariant();

        if (text.Contains("LOGIN", StringComparison.Ordinal) || text.Contains("LOGOUT", StringComparison.Ordinal))
        {
            return "Authentication";
        }

        if (text.Contains("AUTH.", StringComparison.Ordinal)
            || text.Contains("ROLE", StringComparison.Ordinal)
            || text.Contains("PERMISSION", StringComparison.Ordinal)
            || text.Contains("AUTHOR", StringComparison.Ordinal))
        {
            return "Authorization";
        }

        if (text.Contains("INVOICE", StringComparison.Ordinal)
            || text.Contains("PAYMENT", StringComparison.Ordinal)
            || text.Contains("CLAIM", StringComparison.Ordinal)
            || text.Contains("BILLING", StringComparison.Ordinal))
        {
            return "Billing";
        }

        if (text.Contains("FORMTEMPLATE", StringComparison.Ordinal)
            || text.Contains("CONFIG", StringComparison.Ordinal)
            || text.Contains("SETTING", StringComparison.Ordinal))
        {
            return "Configuration";
        }

        return "PatientData";
    }

    private static string NormalizeOutcome(string status)
    {
        if (string.IsNullOrWhiteSpace(status))
        {
            return "Success";
        }

        if (status.Contains("FAIL", StringComparison.OrdinalIgnoreCase)
            || status.Contains("DENY", StringComparison.OrdinalIgnoreCase)
            || status.Contains("ERROR", StringComparison.OrdinalIgnoreCase))
        {
            return "Failure";
        }

        if (status.Contains("WARN", StringComparison.OrdinalIgnoreCase)
            || status.Contains("PEND", StringComparison.OrdinalIgnoreCase))
        {
            return "Warning";
        }

        return "Success";
    }

    private static bool IsPrivileged(string actorRole, string category, string resource, string eventName)
    {
        if (actorRole.Equals("ADMIN", StringComparison.OrdinalIgnoreCase)
            || actorRole.Equals("SYSTEM", StringComparison.OrdinalIgnoreCase))
        {
            return true;
        }

        if (category.Equals("Authorization", StringComparison.OrdinalIgnoreCase)
            || category.Equals("Configuration", StringComparison.OrdinalIgnoreCase))
        {
            return true;
        }

        var text = $"{resource} {eventName}".ToUpperInvariant();
        return text.Contains("DELETE", StringComparison.Ordinal)
            || text.Contains("OVERRIDE", StringComparison.Ordinal)
            || text.Contains("ROLE", StringComparison.Ordinal);
    }

    private static string ResolveActorRole(string actor, IReadOnlyDictionary<string, string> principalRoleMap)
    {
        if (string.IsNullOrWhiteSpace(actor))
        {
            return "ANONYMOUS";
        }

        if (actor.Equals("SYSTEM", StringComparison.OrdinalIgnoreCase)
            || actor.Equals("API", StringComparison.OrdinalIgnoreCase))
        {
            return "SYSTEM";
        }

        return principalRoleMap.TryGetValue(actor, out var role)
            ? role
            : "ANONYMOUS";
    }

    private static string NormalizeRole(string role, string fallback)
    {
        if (string.IsNullOrWhiteSpace(role))
        {
            return fallback;
        }

        return role.Trim().ToUpperInvariant();
    }

    private static string ResolveLookupHealthState(int records, DateTime? lastSync, string refreshCadence)
    {
        if (records <= 0 || !lastSync.HasValue)
        {
            return "Stale";
        }

        var age = DateTime.UtcNow - ToUtc(lastSync.Value);
        var isDaily = refreshCadence.Equals("Daily", StringComparison.OrdinalIgnoreCase);
        var warningThreshold = isDaily ? TimeSpan.FromDays(1) : TimeSpan.FromDays(7);
        var staleThreshold = isDaily ? TimeSpan.FromDays(2) : TimeSpan.FromDays(14);

        if (age >= staleThreshold)
        {
            return "Stale";
        }

        return age >= warningThreshold
            ? "Warning"
            : "Healthy";
    }

    private string ResolveAppSettingsUpdatedAt()
    {
        try
        {
            var appSettingsPath = Path.Combine(_hostEnvironment.ContentRootPath, "appsettings.json");
            if (!File.Exists(appSettingsPath))
            {
                return DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm");
            }

            var updatedAtUtc = File.GetLastWriteTimeUtc(appSettingsPath);
            return updatedAtUtc.ToString("yyyy-MM-dd HH:mm");
        }
        catch
        {
            return DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm");
        }
    }

    private string GetConnectionString()
    {
        var connection = _configuration.GetConnectionString(ConnectionStringKey);
        if (string.IsNullOrWhiteSpace(connection) || connection.StartsWith("__SET_CONNECTIONSTRINGS__", StringComparison.Ordinal))
        {
            throw new InvalidOperationException($"Connection string '{ConnectionStringKey}' is not configured.");
        }

        return connection;
    }

    private static string GetString(SqlDataReader reader, int ordinal, string fallback = "")
    {
        if (reader.IsDBNull(ordinal))
        {
            return fallback;
        }

        return Convert.ToString(reader.GetValue(ordinal))?.Trim() ?? fallback;
    }

    private static int GetInt32(SqlDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal))
        {
            return 0;
        }

        return Convert.ToInt32(reader.GetValue(ordinal));
    }

    private static bool GetBoolean(SqlDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal))
        {
            return false;
        }

        return Convert.ToBoolean(reader.GetValue(ordinal));
    }

    private static DateTime? GetNullableDateTime(SqlDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal))
        {
            return null;
        }

        return Convert.ToDateTime(reader.GetValue(ordinal));
    }

    private static DateTime GetDateTime(SqlDataReader reader, int ordinal, DateTime fallback)
    {
        if (reader.IsDBNull(ordinal))
        {
            return fallback;
        }

        return Convert.ToDateTime(reader.GetValue(ordinal));
    }

    private static DateTime ToUtc(DateTime value)
    {
        return value.Kind switch
        {
            DateTimeKind.Utc => value,
            DateTimeKind.Local => value.ToUniversalTime(),
            _ => DateTime.SpecifyKind(value, DateTimeKind.Local).ToUniversalTime()
        };
    }

    private sealed class AuditLogQueryNormalized
    {
        public string? Actor { get; init; }
        public string? Category { get; init; }
        public string? Outcome { get; init; }
        public string? Search { get; init; }
        public bool PrivilegedOnly { get; init; }
        public DateTime? FromUtc { get; init; }
        public DateTime? ToUtc { get; init; }
        public int Page { get; init; }
        public int PageSize { get; init; }
    }

    private sealed class AccessUserAccumulator
    {
        public string Username { get; init; } = string.Empty;
        public string FullName { get; init; } = string.Empty;
        public string Email { get; init; } = string.Empty;
        public bool IsActive { get; init; }
        public DateTime? AccountLockedUntil { get; init; }
        public int FailedLoginAttempts { get; init; }
        public bool MustChangePasswordOnLogin { get; init; }
        public DateTime? LastLoginDate { get; init; }
        public HashSet<string> Roles { get; } = new(StringComparer.OrdinalIgnoreCase);
    }

    private sealed class PermissionAccumulator
    {
        public string PermissionName { get; init; } = string.Empty;
        public string Module { get; init; } = string.Empty;
        public string Action { get; init; } = string.Empty;
        public HashSet<string> Roles { get; } = new(StringComparer.OrdinalIgnoreCase);
    }

    private sealed class GovernanceSourceSnapshot
    {
        public IReadOnlyList<AdminTemplateGovernanceItemDto> TemplateItems { get; init; } = [];
        public IReadOnlyList<AdminLookupHealthItemDto> LookupItems { get; init; } = [];
    }
}
