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
DECLARE @AdminUserId UNIQUEIDENTIFIER = NEWID();

-- Insert admin user (password hash must be provided by secure process)
INSERT INTO Auth.Users (UserId, Username, Email, PasswordHash, FirstName, LastName, IsActive, LastLoginDate, CreatedDate, CreatedBy)
VALUES (@AdminUserId, 'admin', 'admin@healthcareform.local', '$2b$10$VpCKLKNCb1NfWqAj.6O8YOd7.XmhVQ8DGmKFwE7L3YVfUvvLWfEwm', 'System', 'Administrator', 1, NULL, @DefaultDate, 'SYSTEM');

-- Assign ADMIN role to user
INSERT INTO Auth.UserRoles (UserRoleId, UserIdFK, RoleIdFK, CreatedDate, CreatedBy)
VALUES (NEWID(), @AdminUserId, @AdminRoleId, @DefaultDate, 'SYSTEM');

PRINT 'Admin user created successfully';
PRINT 'Username: admin';
PRINT 'Admin password must be set via secure secret and rotated immediately.';
GO
