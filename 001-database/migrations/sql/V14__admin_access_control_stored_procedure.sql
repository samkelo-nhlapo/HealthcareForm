USE HealthcareForm;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- Returns three result sets in a fixed order for the admin access-control screen.
-- 1. Active non-patient roles. 2. User rows with active role assignments. 3. Permission-to-role mappings.
CREATE OR ALTER PROC [Auth].[spGetAdminAccessControlSnapshot]
AS
BEGIN
    SET NOCOUNT ON;

    -- Result set 1: role columns used to build the matrix header.
    SELECT
        R.RoleName
    FROM Auth.Roles R
    WHERE R.IsActive = 1
      AND R.RoleName <> 'PATIENT'
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
        R.RoleName;

    -- Result set 2: users with their currently active roles.
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
    ORDER BY U.Username;

    -- Result set 3: permissions expanded to the roles that currently grant them.
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
    ORDER BY P.Module, P.PermissionName;
END
GO
