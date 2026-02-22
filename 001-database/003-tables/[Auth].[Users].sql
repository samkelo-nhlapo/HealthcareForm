USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	System users for authentication and access management
--	TFS Task:		Healthcare form - user management
--================================================================================================

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Auth].[Users](
	[UserId] [uniqueidentifier] NOT NULL,
	[Username] [varchar](100) NOT NULL UNIQUE,
	[Email] [varchar](250) NOT NULL UNIQUE,
	[PasswordHash] [varchar](MAX) NOT NULL,
	[FirstName] [varchar](250) NOT NULL,
	[LastName] [varchar](250) NOT NULL,
	[IsActive] [bit] NOT NULL DEFAULT 1,
	[AccountLockedUntil] [datetime] NULL, -- For failed login attempts
	[FailedLoginAttempts] [int] NOT NULL DEFAULT 0,
	[LastLoginDate] [datetime] NULL,
	[LastPasswordChangeDate] [datetime] NULL,
	[MustChangePasswordOnLogin] [bit] NOT NULL DEFAULT 0,
	[IsSuperAdmin] [bit] NOT NULL DEFAULT 0,
	[PhoneNumber] [varchar](15) NULL,
	[Department] [varchar](100) NULL,
	[ProfileImagePath] [varchar](500) NULL,
	[Notes] [varchar](MAX) NULL,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [Auth].[Users] ADD DEFAULT (newid()) FOR [UserId]
GO

CREATE INDEX IX_Users_Username ON [Auth].[Users]([Username])
GO

CREATE INDEX IX_Users_Email ON [Auth].[Users]([Email])
GO

CREATE INDEX IX_Users_IsActive ON [Auth].[Users]([IsActive])
GO
