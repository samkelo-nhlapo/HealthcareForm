# Table Usage Matrix

Date: 2026-03-17

Scope: Maps API endpoints to stored procedures and the tables referenced by those procedures. Derived from:
- `002-code/HealthcareForm/Services/` stored procedure calls.
- `001-database/006-stored-procedures/` SQL table references.
- `001-database/003-tables/` table inventory.

Notes:
- This is a static scan of stored procedure SQL; dynamic SQL or runtime-resolved table names are not captured.
- Tables referenced by stored procedures that are not called by API endpoints are not counted as "API utilized" here.
- `sys.*` references are excluded.

Summary:
- Total tables defined: 45
- Tables referenced by API stored procedures: 45
- Tables not referenced by API stored procedures: 0

## API Endpoints to Stored Procedures

| API endpoint | Stored procedures |
| --- | --- |
| `POST /api/auth/login` | `Auth.spGetUserByPrincipal`, `Auth.spGetUserActiveRoles`, `Auth.spRegisterFailedLoginAttempt`, `Auth.spRegisterSuccessfulLogin` |
| `GET /api/auth/me` | None (token-only) |
| `GET /api/patients/worklist` | `Profile.spGetPatientWorklistSourceRows` |
| `POST /api/patients` | `Profile.spAddPatient` |
| `GET /api/patients/{idNumber}` | `Profile.spGetPatient` |
| `PUT /api/patients/{idNumber}` | `Profile.spUpdatePatient` |
| `DELETE /api/patients/{idNumber}` | `Profile.spDeletePatient` |
| `GET /api/lookups/genders` | `Profile.spGetGender` |
| `GET /api/lookups/marital-statuses` | `Profile.spGetMaritalStatus` |
| `GET /api/lookups/countries` | `Location.spGetCountries` |
| `GET /api/lookups/provinces` | `Location.spGetProvinces` |
| `GET /api/lookups/cities` | `Location.spGetCities` |
| `GET /api/lookups/allergies` | `Lookup.spGetAllergies` |
| `GET /api/lookups/medications` | `Lookup.spGetMedications` |
| `GET /api/clients/clinic-categories` | `Profile.spGetClientClinicCategories` |
| `GET /api/clients` | `Profile.spListClients` |
| `GET /api/clients/departments` | `Profile.spListClientDepartments` |
| `GET /api/clients/staff` | `Profile.spListClientStaff` |
| `GET /api/operations/scheduling` | `Profile.spGetSchedulingProviders`, `Profile.spGetSchedulingAppointments` |
| `GET /api/operations/task-queue` | `Profile.spGetTaskQueueSourceRows` |
| `GET /api/revenue/claims` | `Profile.spGetRevenueClaimsSourceRows` |
| `GET /api/admin/access-control` | `Auth.spGetAdminAccessControlSnapshot` |
| `GET /api/admin/audit-log` | `Auth.spGetAdminAuditEventSourceRows` |
| `GET /api/admin/data-governance` | `Auth.spGetAdminDataGovernanceSourceRows` |
| `GET /api/admin/db-errors` | `Auth.spGetAdminDbErrorsSourceRows` |
| `GET /api/patients/{idNumber}/allergies` | `Profile.spGetPatientAllergies` |
| `GET /api/patients/{idNumber}/medications` | `Profile.spGetPatientMedications` |
| `GET /api/patients/{idNumber}/vaccinations` | `Profile.spGetPatientVaccinations` |
| `GET /api/patients/{idNumber}/consultation-notes` | `Profile.spGetPatientConsultationNotes` |
| `GET /api/patients/{idNumber}/referrals` | `Profile.spGetPatientReferrals` |
| `GET /api/forms/submissions/{submissionId}/fields` | `Contacts.spGetFormFieldValues` |
| `GET /api/forms/submissions/{submissionId}/attachments` | `Contacts.spGetFormAttachments` |

## Stored Procedures to Tables Referenced

| Stored procedure | Tables referenced |
| --- | --- |
| `Auth.spGetAdminAccessControlSnapshot` | `Auth.Permissions`, `Auth.RolePermissions`, `Auth.Roles`, `Auth.UserRoles`, `Auth.Users` |
| `Auth.spGetAdminAuditEventSourceRows` | `Auth.AuditLog`, `Auth.Roles`, `Auth.UserActivityAudit`, `Auth.UserRoles`, `Auth.Users` |
| `Auth.spGetAdminDataGovernanceSourceRows` | `Contacts.FormSubmissions`, `Contacts.FormTemplates`, `Location.Cities`, `Location.Provinces`, `Profile.Gender`, `Profile.MaritalStatus` |
| `Auth.spGetAdminDbErrorsSourceRows` | `Auth.DB_Errors` |
| `Auth.spGetUserActiveRoles` | `Auth.Roles`, `Auth.UserRoles` |
| `Auth.spGetUserByPrincipal` | `Auth.Users` |
| `Auth.spRegisterFailedLoginAttempt` | `Auth.Users` |
| `Auth.spRegisterSuccessfulLogin` | `Auth.Users` |
| `Contacts.spGetFormAttachments` | `Contacts.FormAttachments` |
| `Contacts.spGetFormFieldValues` | `Contacts.FormFieldValues` |
| `Lookup.spGetAllergies` | `Lookup.Allergies` |
| `Lookup.spGetMedications` | `Lookup.Medications` |
| `Location.spGetCities` | `Location.Cities` |
| `Location.spGetCountries` | `Location.Countries` |
| `Location.spGetProvinces` | `Location.Provinces` |
| `Profile.spAddPatient` | `Contacts.Emails`, `Contacts.EmergencyContacts`, `Contacts.PatientEmails`, `Contacts.PatientPhones`, `Contacts.Phones`, `Exceptions.Errors`, `Location.Address`, `Location.Cities`, `Location.Provinces`, `Profile.Clients`, `Profile.Patient` |
| `Profile.spDeletePatient` | `Exceptions.Errors`, `Profile.Patient` |
| `Profile.spGetGender` | `Profile.Gender` |
| `Profile.spGetMaritalStatus` | `Profile.MaritalStatus` |
| `Profile.spGetPatient` | `Contacts.Emails`, `Contacts.EmergencyContacts`, `Contacts.PatientEmails`, `Contacts.PatientPhones`, `Contacts.Phones`, `Exceptions.Errors`, `Location.Address`, `Location.Cities`, `Location.Countries`, `Location.Provinces`, `Profile.Patient` |
| `Profile.spGetPatientAllergies` | `Profile.Allergies`, `Profile.Patient` |
| `Profile.spGetPatientConsultationNotes` | `Profile.ConsultationNotes`, `Profile.HealthcareProviders`, `Profile.Patient` |
| `Profile.spGetPatientMedications` | `Profile.Medications`, `Profile.Patient` |
| `Profile.spGetPatientReferrals` | `Profile.HealthcareProviders`, `Profile.Patient`, `Profile.Referrals` |
| `Profile.spGetPatientVaccinations` | `Profile.Patient`, `Profile.Vaccinations` |
| `Profile.spGetPatientWorklistSourceRows` | `Profile.Appointments`, `Profile.HealthcareProviders`, `Profile.MedicalHistory`, `Profile.Patient` |
| `Profile.spGetRevenueClaimsSourceRows` | `Profile.BillingCodes`, `Profile.InsuranceProviders`, `Profile.Invoices`, `Profile.Patient`, `Profile.PatientInsurance` |
| `Profile.spGetSchedulingAppointments` | `Profile.Appointments`, `Profile.HealthcareProviders` |
| `Profile.spGetSchedulingProviders` | `Profile.HealthcareProviders` |
| `Profile.spGetTaskQueueSourceRows` | `Profile.Appointments`, `Profile.BillingCodes`, `Profile.HealthcareProviders`, `Profile.Invoices`, `Profile.LabResults`, `Profile.Patient` |
| `Profile.spGetClientClinicCategories` | `Profile.ClientClinicCategories` |
| `Profile.spListClients` | `Exceptions.Errors`, `Location.Address`, `Profile.ClientClinicCategories`, `Profile.Clients` |
| `Profile.spListClientDepartments` | `Exceptions.Errors`, `Profile.ClientDepartments`, `Profile.Clients` |
| `Profile.spListClientStaff` | `Profile.ClientStaff`, `Profile.Clients`, `Auth.Roles`, `Auth.Users`, `Profile.StaffDesignations`, `Profile.ClientDepartments` |
| `Profile.spUpdatePatient` | `Contacts.Emails`, `Contacts.EmergencyContacts`, `Contacts.PatientEmails`, `Contacts.PatientPhones`, `Contacts.Phones`, `Exceptions.Errors`, `Location.Address`, `Location.Cities`, `Location.Provinces`, `Profile.Clients`, `Profile.Patient` |

## Tables Not Referenced by API Stored Procedures

- None.
