USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Insert security roles for role-based access control (RBAC)
--	TFS Task:		Initialize security roles
--================================================================================================

DECLARE @DefaultDate DATETIME = GETDATE()

INSERT INTO Security.Roles (RoleName, RoleDescription, IsActive, CreatedDate, CreatedBy)
VALUES	
	('ADMIN', 'System Administrator - Full system access', 1, @DefaultDate, 'SYSTEM'),
	('DOCTOR', 'Medical Doctor - Patient care and clinical decision making', 1, @DefaultDate, 'SYSTEM'),
	('NURSE', 'Registered Nurse - Patient care and monitoring', 1, @DefaultDate, 'SYSTEM'),
	('RECEPTIONIST', 'Receptionist - Appointment scheduling and patient check-in', 1, @DefaultDate, 'SYSTEM'),
	('PATIENT', 'Patient - Access own health records and appointment booking', 1, @DefaultDate, 'SYSTEM'),
	('BILLING', 'Billing Administrator - Invoice and payment management', 1, @DefaultDate, 'SYSTEM'),
	('PHARMACIST', 'Pharmacist - Medication management and dispensing', 1, @DefaultDate, 'SYSTEM')

GO

PRINT 'Security roles inserted successfully'
GO
