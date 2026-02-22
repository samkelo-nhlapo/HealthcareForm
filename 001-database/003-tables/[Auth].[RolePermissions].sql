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
GO

ALTER TABLE [Auth].[RolePermissions] ADD DEFAULT (newid()) FOR [RolePermissionId]
GO

ALTER TABLE [Auth].[RolePermissions] WITH CHECK ADD FOREIGN KEY([RoleIdFK])
REFERENCES [Auth].[Roles] ([RoleId])
GO

ALTER TABLE [Auth].[RolePermissions] WITH CHECK ADD FOREIGN KEY([PermissionIdFK])
REFERENCES [Auth].[Permissions] ([PermissionId])
GO

CREATE UNIQUE INDEX UX_RolePermissions_RolePermission ON [Auth].[RolePermissions]([RoleIdFK], [PermissionIdFK])
GO

CREATE INDEX IX_RolePermissions_RoleIdFK ON [Auth].[RolePermissions]([RoleIdFK])
GO

CREATE INDEX IX_RolePermissions_PermissionIdFK ON [Auth].[RolePermissions]([PermissionIdFK])
GO
