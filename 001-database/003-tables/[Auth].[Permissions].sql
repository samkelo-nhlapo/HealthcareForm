USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Permissions that can be granted to roles for fine-grained access control
--	TFS Task:		Healthcare form - permission management
--================================================================================================

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[Auth].[Permissions]', N'U') IS NULL
BEGIN
CREATE TABLE [Auth].[Permissions](
	[PermissionId] [uniqueidentifier] NOT NULL,
	[PermissionName] [varchar](250) NOT NULL UNIQUE,
	[Description] [varchar](MAX) NULL,
	[Category] [varchar](100) NOT NULL, -- Patient, Appointment, Medication, Lab, Billing, Admin
	[Module] [varchar](100) NOT NULL, -- PatientManagement, FormSubmission, etc.
	[ActionType] [varchar](50) NOT NULL, -- Create, Read, Update, Delete, Approve, Print
	[IsActive] [bit] NOT NULL DEFAULT 1,
	[CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[CreatedBy] [varchar](250) NULL,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
	[UpdatedBy] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[PermissionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

IF OBJECT_ID(N'[Auth].[Permissions]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints AS dc
    INNER JOIN sys.columns AS c
        ON c.object_id = dc.parent_object_id
       AND c.column_id = dc.parent_column_id
    WHERE dc.parent_object_id = OBJECT_ID(N'[Auth].[Permissions]')
      AND c.name = N'PermissionId'
)
BEGIN
ALTER TABLE [Auth].[Permissions] ADD DEFAULT (newid()) FOR [PermissionId]
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[Permissions]') AND name = 'IX_Permissions_Category')
BEGIN
CREATE INDEX IX_Permissions_Category ON [Auth].[Permissions]([Category])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Auth].[Permissions]') AND name = 'IX_Permissions_Module')
BEGIN
CREATE INDEX IX_Permissions_Module ON [Auth].[Permissions]([Module])
END
GO

--================================================================================================
-- Example Permissions (Insert after table creation)
--================================================================================================
/*
Patient_Create - Create new patient record
Patient_Read - View patient records
Patient_Update - Update patient information
Patient_Delete - Delete patient records
Medication_Read - View medications
Medication_Create - Add medications
Appointment_Schedule - Schedule appointments
Appointment_Cancel - Cancel appointments
Invoice_Create - Generate invoices
Invoice_Approve - Approve invoices for payment
*/
