USE HealthcareForm;
GO

IF OBJECT_ID(N'[Profile].[StaffDesignations]', N'U') IS NULL
BEGIN
    CREATE TABLE [Profile].[StaffDesignations](
        [StaffDesignationId] [uniqueidentifier] NOT NULL,
        [DesignationName] [varchar](100) NOT NULL UNIQUE,
        [Category] [varchar](50) NOT NULL DEFAULT 'Clinical',
        [Description] [varchar](250) NULL,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        [CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
        [CreatedBy] [varchar](250) NULL,
        [UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
        [UpdatedBy] [varchar](250) NULL,
    PRIMARY KEY CLUSTERED
    (
        [StaffDesignationId] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
    ) ON [PRIMARY];
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.default_constraints dc
    INNER JOIN sys.columns c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[StaffDesignations]')
      AND c.name = 'StaffDesignationId'
)
    ALTER TABLE [Profile].[StaffDesignations] ADD CONSTRAINT [DF_StaffDesignations_StaffDesignationId] DEFAULT (newid()) FOR [StaffDesignationId];
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_StaffDesignations_Category')
BEGIN
    ALTER TABLE [Profile].[StaffDesignations] WITH CHECK
    ADD CONSTRAINT CK_StaffDesignations_Category CHECK ([Category] IN ('Clinical', 'Administrative', 'Support', 'Management', 'Allied'));
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[StaffDesignations]') AND name = 'IX_StaffDesignations_IsActive')
    CREATE INDEX IX_StaffDesignations_IsActive ON [Profile].[StaffDesignations]([IsActive]);
GO

IF OBJECT_ID(N'[Profile].[ClientDepartments]', N'U') IS NULL
BEGIN
    CREATE TABLE [Profile].[ClientDepartments](
        [ClientDepartmentId] [uniqueidentifier] NOT NULL,
        [ClientIdFK] [uniqueidentifier] NOT NULL,
        [DepartmentCode] [varchar](50) NULL,
        [DepartmentName] [varchar](100) NOT NULL,
        [DepartmentType] [varchar](50) NOT NULL DEFAULT 'Clinical',
        [IsActive] [bit] NOT NULL DEFAULT 1,
        [IsDeleted] [bit] NOT NULL DEFAULT 0,
        [CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
        [CreatedBy] [varchar](250) NULL,
        [UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
        [UpdatedBy] [varchar](250) NULL,
    PRIMARY KEY CLUSTERED
    (
        [ClientDepartmentId] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
    ) ON [PRIMARY];
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.default_constraints dc
    INNER JOIN sys.columns c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[ClientDepartments]')
      AND c.name = 'ClientDepartmentId'
)
    ALTER TABLE [Profile].[ClientDepartments] ADD CONSTRAINT [DF_ClientDepartments_ClientDepartmentId] DEFAULT (newid()) FOR [ClientDepartmentId];
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ClientDepartments_DepartmentType')
BEGIN
    ALTER TABLE [Profile].[ClientDepartments] WITH CHECK
    ADD CONSTRAINT CK_ClientDepartments_DepartmentType CHECK ([DepartmentType] IN ('Clinical', 'Administrative', 'Support', 'Management', 'Allied'));
END
GO

IF OBJECT_ID(N'[Profile].[Clients]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ClientDepartments_Client')
BEGIN
    ALTER TABLE [Profile].[ClientDepartments] WITH CHECK
    ADD CONSTRAINT [FK_ClientDepartments_Client] FOREIGN KEY([ClientIdFK]) REFERENCES [Profile].[Clients]([ClientId]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientDepartments]') AND name = 'UX_ClientDepartments_Client_DepartmentName')
    CREATE UNIQUE INDEX UX_ClientDepartments_Client_DepartmentName
    ON [Profile].[ClientDepartments]([ClientIdFK], [DepartmentName])
    WHERE [IsDeleted] = 0;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientDepartments]') AND name = 'IX_ClientDepartments_ClientIdFK')
    CREATE INDEX IX_ClientDepartments_ClientIdFK ON [Profile].[ClientDepartments]([ClientIdFK]);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientDepartments]') AND name = 'IX_ClientDepartments_IsActive')
    CREATE INDEX IX_ClientDepartments_IsActive ON [Profile].[ClientDepartments]([IsActive]);
GO

IF OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH('Profile.ClientStaff', 'StaffDesignationIdFK') IS NULL
        ALTER TABLE [Profile].[ClientStaff] ADD [StaffDesignationIdFK] [uniqueidentifier] NULL;

    IF COL_LENGTH('Profile.ClientStaff', 'PrimaryDepartmentIdFK') IS NULL
        ALTER TABLE [Profile].[ClientStaff] ADD [PrimaryDepartmentIdFK] [uniqueidentifier] NULL;
END
GO

IF OBJECT_ID(N'[Profile].[StaffDesignations]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ClientStaff_StaffDesignation')
BEGIN
    ALTER TABLE [Profile].[ClientStaff] WITH CHECK
    ADD CONSTRAINT [FK_ClientStaff_StaffDesignation] FOREIGN KEY([StaffDesignationIdFK]) REFERENCES [Profile].[StaffDesignations]([StaffDesignationId]);
END
GO

IF OBJECT_ID(N'[Profile].[ClientDepartments]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ClientStaff_PrimaryDepartment')
BEGIN
    ALTER TABLE [Profile].[ClientStaff] WITH CHECK
    ADD CONSTRAINT [FK_ClientStaff_PrimaryDepartment] FOREIGN KEY([PrimaryDepartmentIdFK]) REFERENCES [Profile].[ClientDepartments]([ClientDepartmentId]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientStaff]') AND name = 'IX_ClientStaff_StaffDesignationIdFK')
    CREATE INDEX IX_ClientStaff_StaffDesignationIdFK ON [Profile].[ClientStaff]([StaffDesignationIdFK]);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientStaff]') AND name = 'IX_ClientStaff_PrimaryDepartmentIdFK')
    CREATE INDEX IX_ClientStaff_PrimaryDepartmentIdFK ON [Profile].[ClientStaff]([PrimaryDepartmentIdFK]);
GO

INSERT INTO [Profile].[StaffDesignations] (StaffDesignationId, DesignationName, Category, Description, IsActive, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy)
SELECT NEWID(), V.DesignationName, V.Category, V.Description, 1, GETDATE(), 'SYSTEM', GETDATE(), 'SYSTEM'
FROM
(
    VALUES
    ('Doctor', 'Clinical', 'General medical practitioner'),
    ('Specialist', 'Clinical', 'Specialized medical practitioner'),
    ('Nurse', 'Clinical', 'Registered or enrolled nurse'),
    ('Assistant', 'Support', 'Clinical or administrative assistant')
) V(DesignationName, Category, Description)
WHERE NOT EXISTS
(
    SELECT 1
    FROM [Profile].[StaffDesignations] SD
    WHERE SD.DesignationName = V.DesignationName
);
GO

CREATE OR ALTER PROC [Profile].[spAddClientDepartment]
(
    @ClientIdFK UNIQUEIDENTIFIER,
    @DepartmentName VARCHAR(100),
    @DepartmentCode VARCHAR(50) = NULL,
    @DepartmentType VARCHAR(50) = 'Clinical',
    @CreatedBy VARCHAR(250) = NULL,
    @ClientDepartmentIdOutput UNIQUEIDENTIFIER OUTPUT,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE();

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @ClientDepartmentIdOutput = NULL;
    SET @StatusCode = -1;
    SET @Message = '';

    IF @ClientIdFK IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientIdFK is required.';
        RETURN;
    END

    IF LTRIM(RTRIM(ISNULL(@DepartmentName, ''))) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'DepartmentName is required.';
        RETURN;
    END

    IF @DepartmentType NOT IN ('Clinical', 'Administrative', 'Support', 'Management', 'Allied')
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Invalid DepartmentType.';
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Profile.Clients WHERE ClientId = @ClientIdFK AND IsDeleted = 0)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Client does not exist or is deleted.';
        RETURN;
    END

    IF EXISTS
    (
        SELECT 1
        FROM Profile.ClientDepartments
        WHERE ClientIdFK = @ClientIdFK
          AND DepartmentName = LTRIM(RTRIM(@DepartmentName))
          AND IsDeleted = 0
    )
    BEGIN
        SET @StatusCode = 2;
        SET @Message = 'Department already exists for this client.';
        RETURN;
    END

    SET @ClientDepartmentIdOutput = NEWID();

    INSERT INTO Profile.ClientDepartments
    (
        ClientDepartmentId,
        ClientIdFK,
        DepartmentCode,
        DepartmentName,
        DepartmentType,
        IsActive,
        IsDeleted,
        CreatedDate,
        CreatedBy,
        UpdatedDate,
        UpdatedBy
    )
    VALUES
    (
        @ClientDepartmentIdOutput,
        @ClientIdFK,
        NULLIF(LTRIM(RTRIM(ISNULL(@DepartmentCode, ''))), ''),
        LTRIM(RTRIM(@DepartmentName)),
        @DepartmentType,
        1,
        0,
        @Now,
        COALESCE(NULLIF(@CreatedBy, ''), SUSER_SNAME()),
        @Now,
        COALESCE(NULLIF(@CreatedBy, ''), SUSER_SNAME())
    );

    SET @StatusCode = 0;
    SET @Message = '';
    SET NOCOUNT OFF;
END
GO

CREATE OR ALTER PROC [Profile].[spListClientDepartments]
(
    @ClientIdFK UNIQUEIDENTIFIER = NULL,
    @DepartmentType VARCHAR(50) = '',
    @SearchTerm VARCHAR(100) = '',
    @IsActive BIT = NULL,
    @IsDeleted BIT = 0,
    @PageNumber INT = 1,
    @PageSize INT = 25,
    @TotalRecords INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Offset INT;

    SET NOCOUNT ON;

    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize < 1 SET @PageSize = 25;
    IF @PageSize > 200 SET @PageSize = 200;

    IF @DepartmentType <> ''
       AND @DepartmentType NOT IN ('Clinical', 'Administrative', 'Support', 'Management', 'Allied')
    BEGIN
        SET @TotalRecords = 0;
        SET @Message = 'Invalid DepartmentType.';
        RETURN;
    END

    SET @Offset = (@PageNumber - 1) * @PageSize;
    SET @TotalRecords = 0;
    SET @Message = '';

    ;WITH Base AS
    (
        SELECT
            CD.ClientDepartmentId,
            CD.ClientIdFK,
            C.ClientCode,
            C.FirstName AS ClientFirstName,
            C.LastName AS ClientLastName,
            CD.DepartmentCode,
            CD.DepartmentName,
            CD.DepartmentType,
            CD.IsActive,
            CD.IsDeleted,
            CD.CreatedDate,
            CD.CreatedBy,
            CD.UpdatedDate,
            CD.UpdatedBy
        FROM Profile.ClientDepartments CD
        INNER JOIN Profile.Clients C ON C.ClientId = CD.ClientIdFK
        WHERE (@ClientIdFK IS NULL OR CD.ClientIdFK = @ClientIdFK)
          AND (@DepartmentType = '' OR CD.DepartmentType = @DepartmentType)
          AND (@IsActive IS NULL OR CD.IsActive = @IsActive)
          AND (@IsDeleted IS NULL OR CD.IsDeleted = @IsDeleted)
          AND
          (
                @SearchTerm = ''
                OR CD.DepartmentName LIKE '%' + @SearchTerm + '%'
                OR ISNULL(CD.DepartmentCode, '') LIKE '%' + @SearchTerm + '%'
                OR C.ClientCode LIKE '%' + @SearchTerm + '%'
          )
    ),
    Numbered AS
    (
        SELECT
            B.*,
            COUNT(1) OVER () AS TotalRows,
            ROW_NUMBER() OVER (ORDER BY B.DepartmentName ASC, B.ClientDepartmentId ASC) AS RowNum
        FROM Base B
    )
    SELECT
        ClientDepartmentId,
        ClientIdFK,
        ClientCode,
        ClientFirstName,
        ClientLastName,
        DepartmentCode,
        DepartmentName,
        DepartmentType,
        IsActive,
        IsDeleted,
        CreatedDate,
        CreatedBy,
        UpdatedDate,
        UpdatedBy
    FROM Numbered
    WHERE RowNum > @Offset
      AND RowNum <= (@Offset + @PageSize)
    ORDER BY RowNum;

    SELECT @TotalRecords = ISNULL(MAX(TotalRows), 0)
    FROM Numbered;

    SET @Message = '';
    SET NOCOUNT OFF;
END
GO

CREATE OR ALTER PROC [Profile].[spUpdateClientDepartment]
(
    @ClientDepartmentId UNIQUEIDENTIFIER,
    @DepartmentName VARCHAR(100),
    @DepartmentCode VARCHAR(50) = NULL,
    @DepartmentType VARCHAR(50),
    @IsActive BIT = 1,
    @UpdatedBy VARCHAR(250) = NULL,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE(),
            @ClientIdFK UNIQUEIDENTIFIER;

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @StatusCode = -1;
    SET @Message = '';

    IF @ClientDepartmentId IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientDepartmentId is required.';
        RETURN;
    END

    IF LTRIM(RTRIM(ISNULL(@DepartmentName, ''))) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'DepartmentName is required.';
        RETURN;
    END

    IF @DepartmentType NOT IN ('Clinical', 'Administrative', 'Support', 'Management', 'Allied')
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Invalid DepartmentType.';
        RETURN;
    END

    SELECT @ClientIdFK = ClientIdFK
    FROM Profile.ClientDepartments
    WHERE ClientDepartmentId = @ClientDepartmentId
      AND IsDeleted = 0;

    IF @ClientIdFK IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Client department not found or already deleted.';
        RETURN;
    END

    IF EXISTS
    (
        SELECT 1
        FROM Profile.ClientDepartments
        WHERE ClientIdFK = @ClientIdFK
          AND DepartmentName = LTRIM(RTRIM(@DepartmentName))
          AND ClientDepartmentId <> @ClientDepartmentId
          AND IsDeleted = 0
    )
    BEGIN
        SET @StatusCode = 2;
        SET @Message = 'Department name already exists for this client.';
        RETURN;
    END

    UPDATE Profile.ClientDepartments
    SET DepartmentCode = NULLIF(LTRIM(RTRIM(ISNULL(@DepartmentCode, ''))), ''),
        DepartmentName = LTRIM(RTRIM(@DepartmentName)),
        DepartmentType = @DepartmentType,
        IsActive = @IsActive,
        UpdatedDate = @Now,
        UpdatedBy = COALESCE(NULLIF(@UpdatedBy, ''), SUSER_SNAME())
    WHERE ClientDepartmentId = @ClientDepartmentId
      AND IsDeleted = 0;

    SET @StatusCode = 0;
    SET @Message = '';
    SET NOCOUNT OFF;
END
GO

CREATE OR ALTER PROC [Profile].[spDeleteClientDepartment]
(
    @ClientDepartmentId UNIQUEIDENTIFIER,
    @UpdatedBy VARCHAR(250) = NULL,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE();

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @StatusCode = -1;
    SET @Message = '';

    IF @ClientDepartmentId IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientDepartmentId is required.';
        RETURN;
    END

    IF NOT EXISTS
    (
        SELECT 1
        FROM Profile.ClientDepartments
        WHERE ClientDepartmentId = @ClientDepartmentId
          AND IsDeleted = 0
    )
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Client department not found or already deleted.';
        RETURN;
    END

    IF EXISTS
    (
        SELECT 1
        FROM Profile.ClientStaff
        WHERE PrimaryDepartmentIdFK = @ClientDepartmentId
          AND IsDeleted = 0
    )
    BEGIN
        SET @StatusCode = 2;
        SET @Message = 'Department cannot be deleted while staff are assigned to it.';
        RETURN;
    END

    UPDATE Profile.ClientDepartments
    SET IsDeleted = 1,
        IsActive = 0,
        UpdatedDate = @Now,
        UpdatedBy = COALESCE(NULLIF(@UpdatedBy, ''), SUSER_SNAME())
    WHERE ClientDepartmentId = @ClientDepartmentId
      AND IsDeleted = 0;

    SET @StatusCode = 0;
    SET @Message = '';
    SET NOCOUNT OFF;
END
GO
