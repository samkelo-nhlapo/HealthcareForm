USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Returns raw audit events for the admin audit-log experience.
-- The proc combines user-activity and table-audit streams into one flat event feed.
CREATE OR ALTER PROC [Auth].[spGetAdminAuditEventSourceRows]
(
    @MaxRows INT = 500
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @MaxRows IS NULL OR @MaxRows < 1
    BEGIN
        SET @MaxRows = 500;
    END

    -- UserActivityAudit gives the higher-fidelity application events.
    ;WITH UserActivityEvents AS
    (
        SELECT TOP (@MaxRows)
            OccurredAtUtc = UAA.ActivityDateTime,
            Actor = COALESCE(NULLIF(U.Username, ''), 'unknown'),
            ActorRole = COALESCE(NULLIF(RolePick.RoleName, ''), 'ANONYMOUS'),
            ActivityType = COALESCE(NULLIF(UAA.ActivityType, ''), 'UNKNOWN'),
            Resource = COALESCE(NULLIF(UAA.TableName, ''), 'Auth.UserActivityAudit'),
            EventName = COALESCE(NULLIF(UAA.Description, ''), NULLIF(UAA.ActivityType, ''), 'Unknown activity'),
            Status = COALESCE(NULLIF(UAA.Status, ''), 'Success'),
            IpAddress = COALESCE(NULLIF(UAA.IPAddress, ''), 'N/A'),
            CorrelationId = 'UA-' + UPPER(LEFT(REPLACE(CONVERT(VARCHAR(36), UAA.UserActivityId), '-', ''), 8))
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
        ORDER BY UAA.ActivityDateTime DESC
    ),
    -- Auth.AuditLog fills in table-level changes that did not flow through UserActivityAudit.
    TableAuditEvents AS
    (
        SELECT TOP (@MaxRows)
            OccurredAtUtc = AL.ModifiedTime,
            Actor = COALESCE(NULLIF(AL.ModifiedBy, ''), 'SYSTEM'),
            ActorRole = CASE
                WHEN UPPER(COALESCE(NULLIF(AL.ModifiedBy, ''), 'SYSTEM')) IN ('SYSTEM', 'API')
                    THEN 'SYSTEM'
                ELSE COALESCE(NULLIF(ActorRolePick.RoleName, ''), CASE WHEN ActorUser.IsSuperAdmin = 1 THEN 'ADMIN' ELSE 'ANONYMOUS' END)
            END,
            ActivityType = COALESCE(NULLIF(AL.Operation, ''), 'Updated'),
            Resource = CASE
                WHEN LTRIM(RTRIM(ISNULL(AL.SchemaName, ''))) = '' OR LTRIM(RTRIM(ISNULL(AL.TableName, ''))) = ''
                    THEN 'Auth.AuditLog'
                ELSE LTRIM(RTRIM(AL.SchemaName)) + '.' + LTRIM(RTRIM(AL.TableName))
            END,
            EventName = COALESCE(NULLIF(AL.Operation, ''), 'Updated'),
            Status = 'Success',
            IpAddress = 'N/A',
            CorrelationId = 'AL-' + RIGHT('000000' + CAST(AL.AuditLogID AS VARCHAR(6)), 6)
        FROM Auth.AuditLog AL
        OUTER APPLY
        (
            SELECT TOP (1)
                U.UserId,
                U.IsSuperAdmin
            FROM Auth.Users U
            WHERE U.Username = AL.ModifiedBy
               OR U.Email = AL.ModifiedBy
            ORDER BY
                CASE WHEN U.Username = AL.ModifiedBy THEN 0 ELSE 1 END,
                U.UserId
        ) ActorUser
        OUTER APPLY
        (
            SELECT TOP (1) R.RoleName
            FROM Auth.UserRoles UR
            INNER JOIN Auth.Roles R
                ON R.RoleId = UR.RoleIdFK
               AND R.IsActive = 1
            WHERE UR.UserIdFK = ActorUser.UserId
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
        ) ActorRolePick
        ORDER BY AL.ModifiedTime DESC
    )
    -- Keep the union output column order stable because the API reads this as a single feed.
    SELECT
        OccurredAtUtc,
        Actor,
        ActorRole,
        ActivityType,
        Resource,
        EventName,
        Status,
        IpAddress,
        CorrelationId
    FROM UserActivityEvents
    UNION ALL
    SELECT
        OccurredAtUtc,
        Actor,
        ActorRole,
        ActivityType,
        Resource,
        EventName,
        Status,
        IpAddress,
        CorrelationId
    FROM TableAuditEvents;
END
GO
