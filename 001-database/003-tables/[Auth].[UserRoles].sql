USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Junction table mapping users to roles
--	TFS Task:		Healthcare form - user role assignments
--================================================================================================

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[Auth].[UserRoles]', N'U') IS NULL
BEGIN
CREATE TABLE [Auth].[UserRoles](
	[UserRoleId] [uniqueidentifier] NOT NULL,
	[UserIdFK] [uniqueidentifier] NOT NULL,
	[RoleIdFK] [uniqueidentifier] NOT NULL,
	[AssignedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[AssignedBy] [varchar](250) NULL,
	[ExpiryDate] [datetime] NULL, -- For temporary role assignments
	[IsActive] [bit] NOT NULL DEFAULT 1,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[UserRoleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

IF OBJECT_ID(N'[Auth].[UserRoles]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Auth].[UserRoles]')
      AND c.name = N'UserRoleId'
)
BEGIN
ALTER TABLE [Auth].[UserRoles] ADD DEFAULT (newid()) FOR [UserRoleId]
END
GO

IF OBJECT_ID(N'[Auth].[UserRoles]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Auth].[Users]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Auth].[UserRoles]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Auth].[UserRoles]'), N'UserIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Auth].[Users]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Auth].[Users]'), N'UserId', 'ColumnId')
)
BEGIN
ALTER TABLE [Auth].[UserRoles] WITH CHECK ADD FOREIGN KEY([UserIdFK])
REFERENCES [Auth].[Users] ([UserId])
END
GO

IF OBJECT_ID(N'[Auth].[UserRoles]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Auth].[Roles]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Auth].[UserRoles]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Auth].[UserRoles]'), N'RoleIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Auth].[Roles]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Auth].[Roles]'), N'RoleId', 'ColumnId')
)
BEGIN
ALTER TABLE [Auth].[UserRoles] WITH CHECK ADD FOREIGN KEY([RoleIdFK])
REFERENCES [Auth].[Roles] ([RoleId])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[UserRoles]') AND name = 'UX_UserRoles_UserRole')
BEGIN
CREATE UNIQUE INDEX UX_UserRoles_UserRole ON [Auth].[UserRoles]([UserIdFK], [RoleIdFK])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[UserRoles]') AND name = 'IX_UserRoles_UserIdFK')
BEGIN
CREATE INDEX IX_UserRoles_UserIdFK ON [Auth].[UserRoles]([UserIdFK])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[UserRoles]') AND name = 'IX_UserRoles_RoleIdFK')
BEGIN
CREATE INDEX IX_UserRoles_RoleIdFK ON [Auth].[UserRoles]([RoleIdFK])
END
GO
