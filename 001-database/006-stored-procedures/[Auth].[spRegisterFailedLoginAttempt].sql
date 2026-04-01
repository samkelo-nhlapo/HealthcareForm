USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
