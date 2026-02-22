USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Insert system permissions for role-based access control (RBAC)
--	TFS Task:		Initialize system permissions
--================================================================================================

DECLARE @DefaultDate DATETIME = GETDATE()

INSERT INTO Security.Permissions (PermissionName, PermissionDescription, IsActive, CreatedDate, CreatedBy)
VALUES	
	-- Patient Management Permissions
	('Patient_Create', 'Create new patient record', 1, @DefaultDate, 'SYSTEM'),
	('Patient_Read', 'View patient information', 1, @DefaultDate, 'SYSTEM'),
	('Patient_Update', 'Modify patient information', 1, @DefaultDate, 'SYSTEM'),
	('Patient_Delete', 'Delete patient record', 1, @DefaultDate, 'SYSTEM'),
	('Patient_ViewAll', 'View all patients in system', 1, @DefaultDate, 'SYSTEM'),
	
	-- Medical History Permissions
	('MedicalHistory_Create', 'Add medical history entry', 1, @DefaultDate, 'SYSTEM'),
	('MedicalHistory_Read', 'View medical history', 1, @DefaultDate, 'SYSTEM'),
	('MedicalHistory_Update', 'Modify medical history', 1, @DefaultDate, 'SYSTEM'),
	('MedicalHistory_Delete', 'Delete medical history entry', 1, @DefaultDate, 'SYSTEM'),
	
	-- Appointment Permissions
	('Appointment_Create', 'Create appointment', 1, @DefaultDate, 'SYSTEM'),
	('Appointment_Read', 'View appointments', 1, @DefaultDate, 'SYSTEM'),
	('Appointment_Update', 'Modify appointment', 1, @DefaultDate, 'SYSTEM'),
	('Appointment_Cancel', 'Cancel appointment', 1, @DefaultDate, 'SYSTEM'),
	('Appointment_ViewAll', 'View all appointments', 1, @DefaultDate, 'SYSTEM'),
	
	-- Medication Permissions
	('Medication_Create', 'Add medication record', 1, @DefaultDate, 'SYSTEM'),
	('Medication_Read', 'View medication history', 1, @DefaultDate, 'SYSTEM'),
	('Medication_Update', 'Modify medication record', 1, @DefaultDate, 'SYSTEM'),
	('Medication_Delete', 'Remove medication record', 1, @DefaultDate, 'SYSTEM'),
	('Medication_Manage', 'Manage all medications in system', 1, @DefaultDate, 'SYSTEM'),
	
	-- Consultation Notes Permissions
	('ConsultationNotes_Create', 'Create consultation notes', 1, @DefaultDate, 'SYSTEM'),
	('ConsultationNotes_Read', 'View consultation notes', 1, @DefaultDate, 'SYSTEM'),
	('ConsultationNotes_Update', 'Modify consultation notes', 1, @DefaultDate, 'SYSTEM'),
	('ConsultationNotes_Delete', 'Delete consultation notes', 1, @DefaultDate, 'SYSTEM'),
	
	-- Form Permissions
	('Form_Create', 'Create form template', 1, @DefaultDate, 'SYSTEM'),
	('Form_Read', 'View forms', 1, @DefaultDate, 'SYSTEM'),
	('Form_Update', 'Modify form template', 1, @DefaultDate, 'SYSTEM'),
	('Form_Delete', 'Delete form', 1, @DefaultDate, 'SYSTEM'),
	('Form_Submit', 'Submit form', 1, @DefaultDate, 'SYSTEM'),
	('Form_Review', 'Review submitted forms', 1, @DefaultDate, 'SYSTEM'),
	
	-- Invoice and Billing Permissions
	('Invoice_Create', 'Create invoice', 1, @DefaultDate, 'SYSTEM'),
	('Invoice_Read', 'View invoices', 1, @DefaultDate, 'SYSTEM'),
	('Invoice_Update', 'Modify invoice', 1, @DefaultDate, 'SYSTEM'),
	('Invoice_Delete', 'Delete invoice', 1, @DefaultDate, 'SYSTEM'),
	('Payment_Process', 'Process payment', 1, @DefaultDate, 'SYSTEM'),
	('Payment_View', 'View payment history', 1, @DefaultDate, 'SYSTEM'),
	
	-- Insurance Permissions
	('Insurance_Create', 'Create insurance record', 1, @DefaultDate, 'SYSTEM'),
	('Insurance_Read', 'View insurance information', 1, @DefaultDate, 'SYSTEM'),
	('Insurance_Update', 'Modify insurance record', 1, @DefaultDate, 'SYSTEM'),
	('Insurance_Delete', 'Delete insurance record', 1, @DefaultDate, 'SYSTEM'),
	
	-- Allergy Permissions
	('Allergy_Create', 'Add allergy record', 1, @DefaultDate, 'SYSTEM'),
	('Allergy_Read', 'View allergy information', 1, @DefaultDate, 'SYSTEM'),
	('Allergy_Update', 'Modify allergy record', 1, @DefaultDate, 'SYSTEM'),
	('Allergy_Delete', 'Delete allergy record', 1, @DefaultDate, 'SYSTEM'),
	
	-- Lab Results Permissions
	('LabResults_Create', 'Create lab results', 1, @DefaultDate, 'SYSTEM'),
	('LabResults_Read', 'View lab results', 1, @DefaultDate, 'SYSTEM'),
	('LabResults_Update', 'Modify lab results', 1, @DefaultDate, 'SYSTEM'),
	('LabResults_Delete', 'Delete lab results', 1, @DefaultDate, 'SYSTEM'),
	
	-- System Administration Permissions
	('SystemAdmin_User', 'Manage users and roles', 1, @DefaultDate, 'SYSTEM'),
	('SystemAdmin_Audit', 'View audit logs', 1, @DefaultDate, 'SYSTEM'),
	('SystemAdmin_Reports', 'Generate system reports', 1, @DefaultDate, 'SYSTEM'),
	('SystemAdmin_Settings', 'Modify system settings', 1, @DefaultDate, 'SYSTEM'),
	('SystemAdmin_Database', 'Database administration', 1, @DefaultDate, 'SYSTEM'),
	
	-- Referral Permissions
	('Referral_Create', 'Create referral', 1, @DefaultDate, 'SYSTEM'),
	('Referral_Read', 'View referrals', 1, @DefaultDate, 'SYSTEM'),
	('Referral_Update', 'Update referral status', 1, @DefaultDate, 'SYSTEM'),
	('Referral_Delete', 'Delete referral', 1, @DefaultDate, 'SYSTEM')

GO

PRINT 'Security permissions inserted successfully'
GO
