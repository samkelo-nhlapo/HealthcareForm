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
GO

ALTER TABLE [Auth].[Permissions] ADD DEFAULT (newid()) FOR [PermissionId]
GO

CREATE INDEX IX_Permissions_Category ON [Auth].[Permissions]([Category])
GO

CREATE INDEX IX_Permissions_Module ON [Auth].[Permissions]([Module])
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
