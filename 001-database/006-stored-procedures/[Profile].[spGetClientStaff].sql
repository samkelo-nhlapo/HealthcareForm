USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spGetClientStaff]
(
    @ClientStaffId UNIQUEIDENTIFIER = NULL,
    @StaffCode VARCHAR(50) = '',
    @IncludeDeleted BIT = 0,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET @Message = '';

    IF @ClientStaffId IS NULL AND LTRIM(RTRIM(@StaffCode)) = ''
    BEGIN
        SET @Message = 'ClientStaffId or StaffCode is required.';
        RETURN;
    END

    IF EXISTS
    (
        SELECT 1
        FROM Profile.ClientStaff CS
        WHERE ((@ClientStaffId IS NOT NULL AND CS.ClientStaffId = @ClientStaffId)
               OR (@ClientStaffId IS NULL AND CS.StaffCode = @StaffCode))
          AND (@IncludeDeleted = 1 OR CS.IsDeleted = 0)
    )
    BEGIN
        SELECT
            CS.ClientStaffId,
            CS.ClientIdFK,
            C.ClientCode,
            CS.RoleIdFK,
            R.RoleName,
            CS.UserIdFK,
            U.Username,
            CS.ProviderIdFK,
            CS.StaffCode,
            CS.FirstName,
            CS.LastName,
            CS.Email,
            CS.PhoneNumber,
            CS.JobTitle,
            CS.Department,
            CS.StaffDesignationIdFK,
            SD.DesignationName AS StaffDesignation,
            CS.PrimaryDepartmentIdFK,
            CD.DepartmentName AS PrimaryDepartmentName,
            CS.StaffType,
            CS.EmploymentType,
            CS.HireDate,
            CS.TerminationDate,
            CS.IsPrimaryContact,
            CS.IsActive,
            CS.IsDeleted,
            CS.CreatedDate,
            CS.CreatedBy,
            CS.UpdatedDate,
            CS.UpdatedBy
        FROM Profile.ClientStaff CS
        INNER JOIN Profile.Clients C ON C.ClientId = CS.ClientIdFK
        LEFT JOIN Auth.Roles R ON R.RoleId = CS.RoleIdFK
        LEFT JOIN Auth.Users U ON U.UserId = CS.UserIdFK
        LEFT JOIN Profile.StaffDesignations SD ON SD.StaffDesignationId = CS.StaffDesignationIdFK
        LEFT JOIN Profile.ClientDepartments CD ON CD.ClientDepartmentId = CS.PrimaryDepartmentIdFK
        WHERE ((@ClientStaffId IS NOT NULL AND CS.ClientStaffId = @ClientStaffId)
               OR (@ClientStaffId IS NULL AND CS.StaffCode = @StaffCode))
          AND (@IncludeDeleted = 1 OR CS.IsDeleted = 0);

        SET @Message = '';
    END
    ELSE
    BEGIN
        SET @Message = 'Client staff not found.';
    END

    SET NOCOUNT OFF;
END
GO
