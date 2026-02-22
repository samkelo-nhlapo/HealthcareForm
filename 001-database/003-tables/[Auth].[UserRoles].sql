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
GO

ALTER TABLE [Auth].[UserRoles] ADD DEFAULT (newid()) FOR [UserRoleId]
GO

ALTER TABLE [Auth].[UserRoles] WITH CHECK ADD FOREIGN KEY([UserIdFK])
REFERENCES [Auth].[Users] ([UserId])
GO

ALTER TABLE [Auth].[UserRoles] WITH CHECK ADD FOREIGN KEY([RoleIdFK])
REFERENCES [Auth].[Roles] ([RoleId])
GO

CREATE UNIQUE INDEX UX_UserRoles_UserRole ON [Auth].[UserRoles]([UserIdFK], [RoleIdFK])
GO

CREATE INDEX IX_UserRoles_UserIdFK ON [Auth].[UserRoles]([UserIdFK])
GO

CREATE INDEX IX_UserRoles_RoleIdFK ON [Auth].[UserRoles]([RoleIdFK])
GO
