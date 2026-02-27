USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Audit trail for user login/logout and sensitive activities
--	TFS Task:		Healthcare form - user activity audit
--================================================================================================

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[Auth].[UserActivityAudit]', N'U') IS NULL
BEGIN
CREATE TABLE [Auth].[UserActivityAudit](
	[UserActivityId] [uniqueidentifier] NOT NULL,
	[UserIdFK] [uniqueidentifier] NOT NULL,
	[ActivityType] [varchar](100) NOT NULL, -- Login, Logout, DataAccess, DataModification, Approval
	[Description] [varchar](MAX) NULL,
	[TableName] [varchar](250) NULL, -- For data modification audits
	[RecordId] [uniqueidentifier] NULL, -- ID of modified/accessed record
	[OldValue] [varchar](MAX) NULL, -- Previous value
	[NewValue] [varchar](MAX) NULL, -- New value
	[IPAddress] [varchar](50) NOT NULL,
	[UserAgent] [varchar](500) NULL, -- Browser/device information
	[Status] [varchar](50) NOT NULL DEFAULT 'Success', -- Success, Failed, Warning
	[ErrorMessage] [varchar](MAX) NULL,
	[ActivityDateTime] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[UserActivityId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

IF OBJECT_ID(N'[Auth].[UserActivityAudit]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Auth].[UserActivityAudit]')
      AND c.name = N'UserActivityId'
)
BEGIN
ALTER TABLE [Auth].[UserActivityAudit] ADD DEFAULT (newid()) FOR [UserActivityId]
END
GO

IF OBJECT_ID(N'[Auth].[UserActivityAudit]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Auth].[Users]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Auth].[UserActivityAudit]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Auth].[UserActivityAudit]'), N'UserIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Auth].[Users]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Auth].[Users]'), N'UserId', 'ColumnId')
)
BEGIN
ALTER TABLE [Auth].[UserActivityAudit] WITH CHECK ADD FOREIGN KEY([UserIdFK])
REFERENCES [Auth].[Users] ([UserId])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[UserActivityAudit]') AND name = 'IX_UserActivityAudit_UserIdFK')
BEGIN
CREATE INDEX IX_UserActivityAudit_UserIdFK ON [Auth].[UserActivityAudit]([UserIdFK])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[UserActivityAudit]') AND name = 'IX_UserActivityAudit_ActivityType')
BEGIN
CREATE INDEX IX_UserActivityAudit_ActivityType ON [Auth].[UserActivityAudit]([ActivityType])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[UserActivityAudit]') AND name = 'IX_UserActivityAudit_ActivityDateTime')
BEGIN
CREATE INDEX IX_UserActivityAudit_ActivityDateTime ON [Auth].[UserActivityAudit]([ActivityDateTime])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[UserActivityAudit]') AND name = 'IX_UserActivityAudit_TableName')
BEGIN
CREATE INDEX IX_UserActivityAudit_TableName ON [Auth].[UserActivityAudit]([TableName])
END
GO
