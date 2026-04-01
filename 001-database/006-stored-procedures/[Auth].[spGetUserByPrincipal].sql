USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
