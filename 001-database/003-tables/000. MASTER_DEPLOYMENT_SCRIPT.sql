-- ================================================================================================
-- HealthcareForm - Master Table Deployment (Modular)
-- Note: run in SQLCMD mode (or `sqlcmd`) from repository root.
-- This script executes the table scripts in dependency order.
-- ================================================================================================
USE HealthcareForm
GO

PRINT '================================================================================================';
PRINT 'HealthcareForm - Table Deployment (Modular)';
PRINT 'Started: ' + CONVERT(VARCHAR(25), GETDATE(), 121);
PRINT '================================================================================================';
GO

:r 003-tables/[Auth].[AuditLog].sql
:r 003-tables/[Auth].[Roles].sql
:r 003-tables/[Auth].[Permissions].sql
:r 003-tables/[Auth].[Users].sql
:r 003-tables/[Auth].[RolePermissions].sql
:r 003-tables/[Auth].[UserRoles].sql
:r 003-tables/[Auth].[UserActivityAudit].sql
:r 003-tables/Auth.DB_Errors.sql

:r 003-tables/[Exceptions].[Errors].sql

:r 003-tables/[Location].[Countries].sql
:r 003-tables/[Location].[Provinces].sql
:r 003-tables/[Location].[Cities].sql
:r 003-tables/[Location].[Address].sql

:r 003-tables/[Profile].[Gender].sql
:r 003-tables/[Profile].[MaritalStatus].sql

:r 003-tables/[Contacts].[Emails].sql
:r 003-tables/[Contacts].[Phones].sql
:r 003-tables/[Contacts].[EmergencyContacts].sql
:r 003-tables/[Contacts].[FormTemplates].sql

:r 003-tables/[Profile].[HealthcareProviders].sql
:r 003-tables/[Profile].[InsuranceProviders].sql
:r 003-tables/[Profile].[BillingCodes].sql
:r 003-tables/[Profile].[Patient].sql

:r 003-tables/[Contacts].[PatientEmails].sql
:r 003-tables/[Contacts].[PatientPhones].sql

:r 003-tables/[Profile].[Allergies].sql
:r 003-tables/[Profile].[MedicalHistory].sql
:r 003-tables/[Profile].[Medications].sql
:r 003-tables/[Profile].[Appointments].sql
:r 003-tables/[Profile].[ConsultationNotes].sql
:r 003-tables/[Profile].[Invoices].sql
:r 003-tables/[Profile].[LabResults].sql
:r 003-tables/[Profile].[PatientInsurance].sql
:r 003-tables/[Profile].[Referrals].sql
:r 003-tables/[Profile].[Vaccinations].sql

:r 003-tables/[Contacts].[FormSubmissions].sql
:r 003-tables/[Contacts].[FormFieldValues].sql
:r 003-tables/[Contacts].[FormAttachments].sql

:r 003-tables/[Profile].[ClientClinicCategories].sql
:r 003-tables/[Profile].[Clients].sql
:r 003-tables/[Profile].[StaffDesignations].sql
:r 003-tables/[Profile].[ClientDepartments].sql
:r 003-tables/[Profile].[ClientStaff].sql

:r 003-tables/[Lookup].[Allergies].sql
:r 003-tables/[Lookup].[Medications].sql

PRINT '================================================================================================';
PRINT 'Table deployment complete: ' + CONVERT(VARCHAR(25), GETDATE(), 121);
PRINT '================================================================================================';
GO
