USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Map permissions to security roles (RBAC configuration)
--	TFS Task:		Configure role-based access control
--================================================================================================

DECLARE @DefaultDate DATETIME = GETDATE(),
		@RoleId_ADMIN INT = (SELECT RoleId FROM Security.Roles WHERE RoleName = 'ADMIN'),
		@RoleId_DOCTOR INT = (SELECT RoleId FROM Security.Roles WHERE RoleName = 'DOCTOR'),
		@RoleId_NURSE INT = (SELECT RoleId FROM Security.Roles WHERE RoleName = 'NURSE'),
		@RoleId_RECEPTIONIST INT = (SELECT RoleId FROM Security.Roles WHERE RoleName = 'RECEPTIONIST'),
		@RoleId_PATIENT INT = (SELECT RoleId FROM Security.Roles WHERE RoleName = 'PATIENT'),
		@RoleId_BILLING INT = (SELECT RoleId FROM Security.Roles WHERE RoleName = 'BILLING'),
		@RoleId_PHARMACIST INT = (SELECT RoleId FROM Security.Roles WHERE RoleName = 'PHARMACIST')

-- ADMIN Role - Full permissions
INSERT INTO Security.RolePermissions (RoleIdFK, PermissionIdFK, CreatedDate, CreatedBy)
SELECT @RoleId_ADMIN, PermissionId, @DefaultDate, 'SYSTEM' FROM Security.Permissions

UNION ALL

-- DOCTOR Role - Clinical permissions
SELECT @RoleId_DOCTOR, PermissionId, @DefaultDate, 'SYSTEM' FROM Security.Permissions 
WHERE PermissionName IN (
	'Patient_Create', 'Patient_Read', 'Patient_Update', 'Patient_ViewAll',
	'MedicalHistory_Create', 'MedicalHistory_Read', 'MedicalHistory_Update', 'MedicalHistory_Delete',
	'Appointment_Create', 'Appointment_Read', 'Appointment_Update', 'Appointment_Cancel', 'Appointment_ViewAll',
	'Medication_Create', 'Medication_Read', 'Medication_Update', 'Medication_Delete', 'Medication_Manage',
	'ConsultationNotes_Create', 'ConsultationNotes_Read', 'ConsultationNotes_Update', 'ConsultationNotes_Delete',
	'Allergy_Create', 'Allergy_Read', 'Allergy_Update', 'Allergy_Delete',
	'LabResults_Create', 'LabResults_Read', 'LabResults_Update',
	'Referral_Create', 'Referral_Read', 'Referral_Update',
	'Insurance_Read', 'Payment_View'
)

UNION ALL

-- NURSE Role - Care and monitoring permissions
SELECT @RoleId_NURSE, PermissionId, @DefaultDate, 'SYSTEM' FROM Security.Permissions 
WHERE PermissionName IN (
	'Patient_Read', 'Patient_Update', 'Patient_ViewAll',
	'MedicalHistory_Create', 'MedicalHistory_Read', 'MedicalHistory_Update',
	'Appointment_Read', 'Appointment_ViewAll',
	'Medication_Read', 'Medication_Update',
	'ConsultationNotes_Create', 'ConsultationNotes_Read', 'ConsultationNotes_Update',
	'Allergy_Create', 'Allergy_Read', 'Allergy_Update', 'Allergy_Delete',
	'LabResults_Create', 'LabResults_Read', 'LabResults_Update',
	'Form_Read', 'Form_Submit', 'Form_Review',
	'Payment_View'
)

UNION ALL

-- RECEPTIONIST Role - Administrative permissions
SELECT @RoleId_RECEPTIONIST, PermissionId, @DefaultDate, 'SYSTEM' FROM Security.Permissions 
WHERE PermissionName IN (
	'Patient_Create', 'Patient_Read', 'Patient_Update', 'Patient_ViewAll',
	'Appointment_Create', 'Appointment_Read', 'Appointment_Update', 'Appointment_Cancel', 'Appointment_ViewAll',
	'Form_Read', 'Form_Submit',
	'Payment_View'
)

UNION ALL

-- PATIENT Role - Self-service permissions
SELECT @RoleId_PATIENT, PermissionId, @DefaultDate, 'SYSTEM' FROM Security.Permissions 
WHERE PermissionName IN (
	'Patient_Read', 'Patient_Update',
	'MedicalHistory_Read',
	'Appointment_Create', 'Appointment_Read', 'Appointment_Cancel',
	'Medication_Read',
	'ConsultationNotes_Read',
	'Allergy_Read',
	'LabResults_Read',
	'Form_Read', 'Form_Submit',
	'Insurance_Read',
	'Payment_View'
)

UNION ALL

-- BILLING Role - Financial management permissions
SELECT @RoleId_BILLING, PermissionId, @DefaultDate, 'SYSTEM' FROM Security.Permissions 
WHERE PermissionName IN (
	'Patient_Read', 'Patient_ViewAll',
	'Appointment_Read', 'Appointment_ViewAll',
	'Invoice_Create', 'Invoice_Read', 'Invoice_Update', 'Invoice_Delete',
	'Payment_Process', 'Payment_View',
	'Insurance_Create', 'Insurance_Read', 'Insurance_Update', 'Insurance_Delete'
)

UNION ALL

-- PHARMACIST Role - Medication management permissions
SELECT @RoleId_PHARMACIST, PermissionId, @DefaultDate, 'SYSTEM' FROM Security.Permissions 
WHERE PermissionName IN (
	'Patient_Read', 'Patient_ViewAll',
	'Medication_Create', 'Medication_Read', 'Medication_Update', 'Medication_Delete', 'Medication_Manage',
	'Prescription_Read',
	'Allergy_Read'
)

GO

PRINT 'Role permissions mapped successfully'
GO
