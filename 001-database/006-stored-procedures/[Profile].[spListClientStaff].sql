USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spListClientStaff]
(
    @ClientIdFK UNIQUEIDENTIFIER = NULL,
    @SearchTerm VARCHAR(250) = '',
    @RoleIdFK UNIQUEIDENTIFIER = NULL,
    @StaffType VARCHAR(50) = '',
    @IsActive BIT = NULL,
    @IsDeleted BIT = 0,
    @PageNumber INT = 1,
    @PageSize INT = 25,
    @TotalRecords INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize < 1 SET @PageSize = 25;
    IF @PageSize > 200 SET @PageSize = 200;

    SET @TotalRecords = 0;
    SET @Message = '';

    ;WITH Base AS
    (
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
            CS.UpdatedDate
        FROM Profile.ClientStaff CS
        INNER JOIN Profile.Clients C ON C.ClientId = CS.ClientIdFK
        LEFT JOIN Auth.Roles R ON R.RoleId = CS.RoleIdFK
        LEFT JOIN Auth.Users U ON U.UserId = CS.UserIdFK
        LEFT JOIN Profile.StaffDesignations SD ON SD.StaffDesignationId = CS.StaffDesignationIdFK
        LEFT JOIN Profile.ClientDepartments CD ON CD.ClientDepartmentId = CS.PrimaryDepartmentIdFK
        WHERE (@ClientIdFK IS NULL OR CS.ClientIdFK = @ClientIdFK)
          AND (@RoleIdFK IS NULL OR CS.RoleIdFK = @RoleIdFK)
          AND (@StaffType = '' OR CS.StaffType = @StaffType)
          AND (@IsActive IS NULL OR CS.IsActive = @IsActive)
          AND (@IsDeleted IS NULL OR CS.IsDeleted = @IsDeleted)
          AND (
                @SearchTerm = ''
                OR CS.StaffCode LIKE '%' + @SearchTerm + '%'
                OR CS.FirstName LIKE '%' + @SearchTerm + '%'
                OR CS.LastName LIKE '%' + @SearchTerm + '%'
                OR ISNULL(CS.Email, '') LIKE '%' + @SearchTerm + '%'
                OR ISNULL(CS.PhoneNumber, '') LIKE '%' + @SearchTerm + '%'
                OR ISNULL(CS.JobTitle, '') LIKE '%' + @SearchTerm + '%'
              )
    ),
    Numbered AS
    (
        SELECT
            B.*,
            COUNT(1) OVER () AS TotalRows,
            ROW_NUMBER() OVER (ORDER BY B.LastName ASC, B.FirstName ASC, B.ClientStaffId ASC) AS RowNum
        FROM Base B
    )
    SELECT
        ClientStaffId,
        ClientIdFK,
        ClientCode,
        RoleIdFK,
        RoleName,
        UserIdFK,
        Username,
        ProviderIdFK,
        StaffCode,
        FirstName,
        LastName,
        Email,
        PhoneNumber,
        JobTitle,
        Department,
        StaffDesignationIdFK,
        StaffDesignation,
        PrimaryDepartmentIdFK,
        PrimaryDepartmentName,
        StaffType,
        EmploymentType,
        HireDate,
        TerminationDate,
        IsPrimaryContact,
        IsActive,
        IsDeleted,
        CreatedDate,
        UpdatedDate,
        TotalRows,
        RowNum
    INTO #Numbered
    FROM Numbered;

    SELECT
        ClientStaffId,
        ClientIdFK,
        ClientCode,
        RoleIdFK,
        RoleName,
        UserIdFK,
        Username,
        ProviderIdFK,
        StaffCode,
        FirstName,
        LastName,
        Email,
        PhoneNumber,
        JobTitle,
        Department,
        StaffDesignationIdFK,
        StaffDesignation,
        PrimaryDepartmentIdFK,
        PrimaryDepartmentName,
        StaffType,
        EmploymentType,
        HireDate,
        TerminationDate,
        IsPrimaryContact,
        IsActive,
        IsDeleted,
        CreatedDate,
        UpdatedDate
    FROM #Numbered
    WHERE RowNum > ((@PageNumber - 1) * @PageSize)
      AND RowNum <= ((@PageNumber - 1) * @PageSize + @PageSize)
    ORDER BY RowNum;

    SELECT @TotalRecords = ISNULL(MAX(TotalRows), 0)
    FROM #Numbered;

    DROP TABLE #Numbered;

    SET NOCOUNT OFF;
END
GO
