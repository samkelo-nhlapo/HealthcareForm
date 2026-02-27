USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Junction table mapping roles to permissions
--	TFS Task:		Healthcare form - role permissions
--================================================================================================

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[Auth].[RolePermissions]', N'U') IS NULL
BEGIN
CREATE TABLE [Auth].[RolePermissions](
	[RolePermissionId] [uniqueidentifier] NOT NULL,
	[RoleIdFK] [uniqueidentifier] NOT NULL,
	[PermissionIdFK] [uniqueidentifier] NOT NULL,
	[GrantedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[GrantedBy] [varchar](250) NULL,
	[IsActive] [bit] NOT NULL DEFAULT 1,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[RolePermissionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

IF OBJECT_ID(N'[Auth].[RolePermissions]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Auth].[RolePermissions]')
      AND c.name = N'RolePermissionId'
)
BEGIN
ALTER TABLE [Auth].[RolePermissions] ADD DEFAULT (newid()) FOR [RolePermissionId]
END
GO

IF OBJECT_ID(N'[Auth].[RolePermissions]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Auth].[Roles]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Auth].[RolePermissions]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Auth].[RolePermissions]'), N'RoleIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Auth].[Roles]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Auth].[Roles]'), N'RoleId', 'ColumnId')
)
BEGIN
ALTER TABLE [Auth].[RolePermissions] WITH CHECK ADD FOREIGN KEY([RoleIdFK])
REFERENCES [Auth].[Roles] ([RoleId])
END
GO

IF OBJECT_ID(N'[Auth].[RolePermissions]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Auth].[Permissions]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Auth].[RolePermissions]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Auth].[RolePermissions]'), N'PermissionIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Auth].[Permissions]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Auth].[Permissions]'), N'PermissionId', 'ColumnId')
)
BEGIN
ALTER TABLE [Auth].[RolePermissions] WITH CHECK ADD FOREIGN KEY([PermissionIdFK])
REFERENCES [Auth].[Permissions] ([PermissionId])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[RolePermissions]') AND name = 'UX_RolePermissions_RolePermission')
BEGIN
CREATE UNIQUE INDEX UX_RolePermissions_RolePermission ON [Auth].[RolePermissions]([RoleIdFK], [PermissionIdFK])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[RolePermissions]') AND name = 'IX_RolePermissions_RoleIdFK')
BEGIN
CREATE INDEX IX_RolePermissions_RoleIdFK ON [Auth].[RolePermissions]([RoleIdFK])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[RolePermissions]') AND name = 'IX_RolePermissions_PermissionIdFK')
BEGIN
CREATE INDEX IX_RolePermissions_PermissionIdFK ON [Auth].[RolePermissions]([PermissionIdFK])
END
GO
