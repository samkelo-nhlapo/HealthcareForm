USE HealthcareForm;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- Looks up one auth user by username or email.
-- Used by the login flow before password verification and role loading.
CREATE OR ALTER PROC [Auth].[spGetUserByPrincipal]
(
    @Principal VARCHAR(250)
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (1)
        U.UserId,
        U.Username,
        U.Email,
        U.PasswordHash,
        U.FirstName,
        U.LastName,
        U.IsActive,
        U.IsSuperAdmin,
        U.AccountLockedUntil,
        U.FailedLoginAttempts
    FROM Auth.Users U
    WHERE U.Username = @Principal
       OR U.Email = @Principal;
END
GO

-- Returns the user's active, non-expired roles for token creation and authorization checks.
CREATE OR ALTER PROC [Auth].[spGetUserActiveRoles]
(
    @UserId UNIQUEIDENTIFIER
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT R.RoleName
    FROM Auth.UserRoles UR
    INNER JOIN Auth.Roles R
        ON R.RoleId = UR.RoleIdFK
    WHERE UR.UserIdFK = @UserId
      AND UR.IsActive = 1
      AND R.IsActive = 1
      AND (UR.ExpiryDate IS NULL OR UR.ExpiryDate > GETDATE());
END
GO

-- Persists failed-login counters and an optional lockout timestamp.
CREATE OR ALTER PROC [Auth].[spRegisterFailedLoginAttempt]
(
    @UserId UNIQUEIDENTIFIER,
    @FailedAttempts INT,
    @AccountLockedUntilUtc DATETIME = NULL,
    @UpdatedBy VARCHAR(250) = 'API'
)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Auth.Users
    SET FailedLoginAttempts = @FailedAttempts,
        AccountLockedUntil = @AccountLockedUntilUtc,
        UpdatedDate = GETDATE(),
        UpdatedBy = COALESCE(NULLIF(@UpdatedBy, ''), 'API')
    WHERE UserId = @UserId;
END
GO

-- Resets failure counters and records the last successful login timestamp.
CREATE OR ALTER PROC [Auth].[spRegisterSuccessfulLogin]
(
    @UserId UNIQUEIDENTIFIER,
    @UpdatedBy VARCHAR(250) = 'API'
)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Auth.Users
    SET FailedLoginAttempts = 0,
        AccountLockedUntil = NULL,
        LastLoginDate = GETDATE(),
        UpdatedDate = GETDATE(),
        UpdatedBy = COALESCE(NULLIF(@UpdatedBy, ''), 'API')
    WHERE UserId = @UserId;
END
GO
