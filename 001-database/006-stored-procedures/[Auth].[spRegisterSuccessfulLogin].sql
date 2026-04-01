USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
