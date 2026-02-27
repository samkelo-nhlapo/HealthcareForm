USE HealthcareForm
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
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
BEGIN
    ALTER TABLE [Profile].[ClientDepartments]
    ADD CONSTRAINT [DF_ClientDepartments_ClientDepartmentId] DEFAULT (newid()) FOR [ClientDepartmentId];
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ClientDepartments_DepartmentType')
BEGIN
    ALTER TABLE [Profile].[ClientDepartments] WITH CHECK
    ADD CONSTRAINT CK_ClientDepartments_DepartmentType CHECK ([DepartmentType] IN ('Clinical', 'Administrative', 'Support', 'Management', 'Allied'));
END
GO

IF OBJECT_ID(N'[Profile].[Clients]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE parent_object_id = OBJECT_ID(N'[Profile].[ClientDepartments]')
      AND name = N'FK_ClientDepartments_Client'
)
BEGIN
    ALTER TABLE [Profile].[ClientDepartments] WITH CHECK
    ADD CONSTRAINT [FK_ClientDepartments_Client] FOREIGN KEY([ClientIdFK]) REFERENCES [Profile].[Clients]([ClientId]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientDepartments]') AND name = N'UX_ClientDepartments_Client_DepartmentName')
BEGIN
    CREATE UNIQUE INDEX UX_ClientDepartments_Client_DepartmentName
    ON [Profile].[ClientDepartments]([ClientIdFK], [DepartmentName])
    WHERE [IsDeleted] = 0;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientDepartments]') AND name = N'IX_ClientDepartments_ClientIdFK')
BEGIN
    CREATE INDEX IX_ClientDepartments_ClientIdFK ON [Profile].[ClientDepartments]([ClientIdFK]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[ClientDepartments]') AND name = N'IX_ClientDepartments_IsActive')
BEGIN
    CREATE INDEX IX_ClientDepartments_IsActive ON [Profile].[ClientDepartments]([IsActive]);
END
GO
