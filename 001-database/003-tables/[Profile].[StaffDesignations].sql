USE HealthcareForm
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
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
BEGIN
    ALTER TABLE [Profile].[StaffDesignations]
    ADD CONSTRAINT [DF_StaffDesignations_StaffDesignationId] DEFAULT (newid()) FOR [StaffDesignationId];
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_StaffDesignations_Category')
BEGIN
    ALTER TABLE [Profile].[StaffDesignations] WITH CHECK
    ADD CONSTRAINT CK_StaffDesignations_Category CHECK ([Category] IN ('Clinical', 'Administrative', 'Support', 'Management', 'Allied'));
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[StaffDesignations]') AND name = N'IX_StaffDesignations_IsActive')
BEGIN
    CREATE INDEX IX_StaffDesignations_IsActive ON [Profile].[StaffDesignations]([IsActive]);
END
GO
