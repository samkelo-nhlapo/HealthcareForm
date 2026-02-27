USE HealthcareForm
GO

/****** Object:  Table [Profile].[Patient]    Script Date: 13-May-22 02:12:25 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[Profile].[Patient]', N'U') IS NULL
BEGIN
CREATE TABLE [Profile].[Patient](
	[PatientId] [uniqueidentifier] NOT NULL,
	[FirstName] [varchar](250) NOT NULL,
	[LastName] [varchar](250) NOT NULL,
	[ID_Number] [varchar](250) NOT NULL UNIQUE,
	[DateOfBirth] [datetime] NOT NULL,
	[GenderIDFK] [int] NOT NULL,
	[MedicationList] [varchar](MAX) NULL,
	[AddressIDFK] [uniqueidentifier] NULL,
	[MaritalStatusIDFK] [int] NOT NULL,
	[EmergencyIDFK] [uniqueidentifier] NULL,
	[IsDeleted] [BIT] NOT NULL DEFAULT 0,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[PatientId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

IF OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Profile].[Patient]')
      AND c.name = N'PatientId'
)
BEGIN
ALTER TABLE [Profile].[Patient] ADD  DEFAULT (newid()) FOR [PatientId]
END
GO

IF OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Location].[Address]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[Patient]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Patient]'), N'AddressIDFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Location].[Address]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Location].[Address]'), N'AddressId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[Patient]  WITH CHECK ADD FOREIGN KEY([AddressIDFK])
REFERENCES [Location].[Address] ([AddressId])
END
GO

IF OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Contacts].[EmergencyContacts]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[Patient]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Patient]'), N'EmergencyIDFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Contacts].[EmergencyContacts]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Contacts].[EmergencyContacts]'), N'EmergencyId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[Patient]  WITH CHECK ADD FOREIGN KEY([EmergencyIDFK])
REFERENCES [Contacts].[EmergencyContacts] ([EmergencyId])
END
GO

IF OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[Gender]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[Patient]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Patient]'), N'GenderIDFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[Gender]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Gender]'), N'GenderId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[Patient]  WITH CHECK ADD FOREIGN KEY([GenderIDFK])
REFERENCES [Profile].[Gender] ([GenderId])
END
GO

IF OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[MaritalStatus]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[Patient]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Patient]'), N'MaritalStatusIDFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[MaritalStatus]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[MaritalStatus]'), N'MaritalStatusId', 'ColumnId')
)
BEGIN
ALTER TABLE [Profile].[Patient]  WITH CHECK ADD FOREIGN KEY([MaritalStatusIDFK])
REFERENCES [Profile].[MaritalStatus] ([MaritalStatusId])
END
GO

-- Create indexes for frequent searches
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Patient]') AND name = 'IX_Patient_IDNumber')
BEGIN
CREATE INDEX IX_Patient_IDNumber ON [Profile].[Patient]([ID_Number])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Patient]') AND name = 'IX_Patient_LastName')
BEGIN
CREATE INDEX IX_Patient_LastName ON [Profile].[Patient]([LastName])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Profile].[Patient]') AND name = 'IX_Patient_IsDeleted')
BEGIN
CREATE INDEX IX_Patient_IsDeleted ON [Profile].[Patient]([IsDeleted])
END
GO


