-- V5__seed_auth_and_admin.sql
-- Seed auth data: roles, permissions, role-permissions mapping, and initial admin user.
-- Keep credentials out of repository; use secrets to set passwords and rotate immediately.

-- Example placeholders:
-- INSERT INTO Auth.Roles (...) VALUES (...);
-- INSERT INTO Auth.Permissions (...) VALUES (...);
-- INSERT INTO Auth.RolePermissions (...) SELECT ... FROM Auth.Permissions;
-- INSERT INTO Auth.Users (...) VALUES (...);
PRINT 'V5 no-op: auth/admin seed bootstrap is already included in V1 baseline.';
