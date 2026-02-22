USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	User roles for role-based access control (RBAC)
--	TFS Task:		Healthcare form - role management
--================================================================================================

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Auth].[Roles](
	[RoleId] [uniqueidentifier] NOT NULL,
	[RoleName] [varchar](100) NOT NULL UNIQUE,
	[Description] [varchar](MAX) NULL,
	[IsActive] [bit] NOT NULL DEFAULT 1,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[RoleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [Auth].[Roles] ADD DEFAULT (newid()) FOR [RoleId]
GO

CREATE INDEX IX_Roles_RoleName ON [Auth].[Roles]([RoleName])
GO

--================================================================================================
-- Standard Roles (Insert after table creation)
--================================================================================================
/*
ADMIN - Full system access
DOCTOR - View and manage patient records, write consultation notes
NURSE - View patient records, update vitals
RECEPTIONIST - Schedule appointments, manage patient contact info
PATIENT - View own medical records (read-only)
BILLING - Manage invoices and insurance claims
PHARMACIST - View medications and allergies
*/
