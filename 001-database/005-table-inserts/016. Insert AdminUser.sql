USE HealthcareForm
GO

-- =================================================================================================
-- Author:      Samkelo Nhlapo
-- Create date: 14/02/2026
-- Description: Insert initial admin user and assign ADMIN role for system bootstrap
-- IMPORTANT: This script does NOT set or print a default password in the repository.
--            Set the admin password at deploy time from a secure secret and rotate immediately.
-- =================================================================================================

DECLARE @DefaultDate DATETIME = GETDATE();
DECLARE @AdminRoleId UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'ADMIN');
DECLARE @AdminUserId UNIQUEIDENTIFIER;
DECLARE @AdminPasswordHash VARCHAR(MAX) = '$(ADMIN_PASSWORD_HASH)';
DECLARE @AdminPasswordHashPlaceholder VARCHAR(64) = CHAR(36) + '(ADMIN_PASSWORD_HASH)';

SELECT @AdminUserId = UserId
FROM Auth.Users
WHERE Username = 'admin';

-- Insert admin user (password hash must be provided by secure process)
IF @AdminUserId IS NULL
BEGIN
    IF NULLIF(LTRIM(RTRIM(ISNULL(@AdminPasswordHash, ''))), '') IS NULL
       OR @AdminPasswordHash = @AdminPasswordHashPlaceholder
        THROW 50001, 'ADMIN_PASSWORD_HASH is required to create admin user.', 1;

    SET @AdminUserId = NEWID();

    INSERT INTO Auth.Users (UserId, Username, Email, PasswordHash, FirstName, LastName, IsActive, LastLoginDate, CreatedDate, CreatedBy)
    VALUES (@AdminUserId, 'admin', 'admin@healthcareform.local', @AdminPasswordHash, 'System', 'Administrator', 1, NULL, @DefaultDate, 'SYSTEM');
END

-- Assign ADMIN role to user
IF NOT EXISTS
(
    SELECT 1
    FROM Auth.UserRoles UR
    WHERE UR.UserIdFK = @AdminUserId
      AND UR.RoleIdFK = @AdminRoleId
)
BEGIN
    INSERT INTO Auth.UserRoles (UserRoleId, UserIdFK, RoleIdFK, CreatedDate, CreatedBy)
    VALUES (NEWID(), @AdminUserId, @AdminRoleId, @DefaultDate, 'SYSTEM');
END

PRINT 'Admin user created successfully';
PRINT 'Username: admin';
PRINT 'Admin password must be set via secure secret and rotated immediately.';
GO
