-- ================================================================================================
-- HealthcareForm - Master Stored Procedure Deployment (Modular)
-- Note: run in SQLCMD mode (or `sqlcmd`) from repository root.
-- Excludes scratch/UAT scripts.
-- ================================================================================================
USE HealthcareForm
GO

PRINT '================================================================================================';
PRINT 'HealthcareForm - Stored Procedure Deployment (Modular)';
PRINT 'Started: ' + CONVERT(VARCHAR(25), GETDATE(), 121);
PRINT '================================================================================================';
GO

:r 006-stored-procedures/[Exceptions].[spErrorHandling].sql

:r 006-stored-procedures/[Location].[spGetCountries].sql
:r 006-stored-procedures/Location.spGetProvinces.sql
:r 006-stored-procedures/Location.spGetCities.sql

:r 006-stored-procedures/Profile.spGetGender.sql
:r 006-stored-procedures/[Profile].[spGetMaritalStatus].sql

:r 006-stored-procedures/[Profile].[spAddPatient].sql
:r 006-stored-procedures/[Profile].[spGetPatient].sql
:r 006-stored-procedures/[Profile].[spUpdatePatient].sql
:r 006-stored-procedures/Profile.spDeletePatient.sql
:r 006-stored-procedures/[Profile].[spRestorePatient].sql
:r 006-stored-procedures/[Profile].[spListPatients].sql

:r 006-stored-procedures/[Profile].[spGetClientClinicCategories].sql
:r 006-stored-procedures/[Profile].[spAddClient].sql
:r 006-stored-procedures/[Profile].[spGetClient].sql
:r 006-stored-procedures/[Profile].[spListClients].sql
:r 006-stored-procedures/[Profile].[spUpdateClient].sql
:r 006-stored-procedures/[Profile].[spDeleteClient].sql
:r 006-stored-procedures/[Profile].[spAssignClientClinicCategory].sql

:r 006-stored-procedures/[Profile].[spAddClientDepartment].sql
:r 006-stored-procedures/[Profile].[spListClientDepartments].sql
:r 006-stored-procedures/[Profile].[spUpdateClientDepartment].sql
:r 006-stored-procedures/[Profile].[spDeleteClientDepartment].sql

:r 006-stored-procedures/[Profile].[spAddClientStaff].sql
:r 006-stored-procedures/[Profile].[spGetClientStaff].sql
:r 006-stored-procedures/[Profile].[spListClientStaff].sql
:r 006-stored-procedures/[Profile].[spUpdateClientStaff].sql
:r 006-stored-procedures/[Profile].[spDeleteClientStaff].sql

PRINT '================================================================================================';
PRINT 'Stored procedure deployment complete: ' + CONVERT(VARCHAR(25), GETDATE(), 121);
PRINT '================================================================================================';
GO
