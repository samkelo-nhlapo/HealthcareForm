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

IF OBJECT_ID(N'[Auth].[Users]', N'U') IS NULL
BEGIN
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
END
GO

IF OBJECT_ID(N'[Auth].[Users]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Auth].[Users]')
      AND c.name = N'UserId'
)
BEGIN
ALTER TABLE [Auth].[Users] ADD DEFAULT (newid()) FOR [UserId]
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[Users]') AND name = 'IX_Users_Username')
BEGIN
CREATE INDEX IX_Users_Username ON [Auth].[Users]([Username])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[Users]') AND name = 'IX_Users_Email')
BEGIN
CREATE INDEX IX_Users_Email ON [Auth].[Users]([Email])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[Users]') AND name = 'IX_Users_IsActive')
BEGIN
CREATE INDEX IX_Users_IsActive ON [Auth].[Users]([IsActive])
END
GO
