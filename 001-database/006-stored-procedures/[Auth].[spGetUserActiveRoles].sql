USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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
