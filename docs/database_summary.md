# Database Summary

## Main Tables

1. **Auth.DB_Errors**
   - Description: Stores error logs for the authentication module.
   - Relationships: None

2. **Auth.AuditLog**
   - Description: Logs all audit events for the system.
   - Relationships: None

3. **Auth.Permissions**
   - Description: Defines the permissions available in the system.
   - Relationships: None

4. **Auth.RolePermissions**
   - Description: Maps roles to permissions.
   - Relationships: Auth.Roles, Auth.Permissions

5. **Auth.Roles**
   - Description: Defines the roles in the system.
   - Relationships: Auth.RolePermissions

6. **Auth.UserActivityAudit**
   - Description: Logs user activity for auditing purposes.
   - Relationships: None

7. **Auth.UserRoles**
   - Description: Maps users to roles.
   - Relationships: Auth.Users, Auth.Roles

8. **Auth.Users**
   - Description: Stores user information.
   - Relationships: Auth.UserRoles

9. **Contacts.Emails**
   - Description: Stores email addresses for contacts.
   - Relationships: Contacts.FormSubmissions

10. **Contacts.EmergencyContacts**
    - Description: Stores emergency contact information.
    - Relationships: None

11. **Contacts.FormAttachments**
    - Description: Stores attachments for forms.
    - Relationships: Contacts.FormSubmissions

12. **Contacts.FormFieldValues**
    - Description: Stores values for form fields.
    - Relationships: Contacts.FormSubmissions

13. **Contacts.FormSubmissions**
    - Description: Stores form submissions.
    - Relationships: Contacts.FormAttachments, Contacts.FormFieldValues

14. **Contacts.FormTemplates**
    - Description: Stores form templates.
    - Relationships: None

15. **Contacts.PatientEmails**
    - Description: Stores patient email addresses.
    - Relationships: Contacts.PatientPhones

16. **Contacts.PatientPhones**
    - Description: Stores patient phone numbers.
    - Relationships: Contacts.PatientEmails

17. **Contacts.Phones**
    - Description: Stores phone numbers.
    - Relationships: None

18. **Exceptions.Errors**
    - Description: Stores error information.
    - Relationships: None

19. **Location.Address**
    - Description: Stores address information.
    - Relationships: None

20. **Location.Cities**
    - Description: Stores city information.
    - Relationships: Location.Provinces

21. **Location.Countries**
    - Description: Stores country information.
    - Relationships: None

22. **Location.Provinces**
    - Description: Stores province information.
    - Relationships: Location.Countries

23. **Lookup.Allergies**
    - Description: Stores allergy information.
    - Relationships: None

24. **Lookup.Medications**
    - Description: Stores medication information.
    - Relationships: None

25. **Profile.Allergies**
    - Description: Stores patient allergies.
    - Relationships: Profile.Patient

26. **Profile.Appointments**
    - Description: Stores appointment information.
    - Relationships: Profile.Patient

27. **Profile.BillingCodes**
    - Description: Stores billing codes.
    - Relationships: None

28. **Profile.ClientClinicCategories**
    - Description: Stores client clinic categories.
    - Relationships: None

29. **Profile.ClientDepartments**
    - Description: Stores client departments.
    - Relationships: None

30. **Profile.ClientStaff**
    - Description: Stores client staff information.
    - Relationships: Profile.ClientDepartments

31. **Profile.Clients**
    - Description: Stores client information.
    - Relationships: Profile.ClientClinicCategories, Profile.ClientDepartments, Profile.ClientStaff

32. **Profile.ConsultationNotes**
    - Description: Stores consultation notes.
    - Relationships: Profile.Patient

33. **Profile.Gender**
    - Description: Stores gender information.
    - Relationships: None

34. **Profile.HealthcareProviders**
    - Description: Stores healthcare provider information.
    - Relationships: None

35. **Profile.InsuranceProviders**
    - Description: Stores insurance provider information.
    - Relationships: None

36. **Profile.Invoices**
    - Description: Stores invoice information.
    - Relationships: None

37. **Profile.LabResults**
    - Description: Stores lab results.
    - Relationships: None

38. **Profile.MaritalStatus**
    - Description: Stores marital status information.
    - Relationships: None

39. **Profile.MedicalHistory**
    - Description: Stores medical history.
    - Relationships: Profile.Patient

40. **Profile.Medications**
    - Description: Stores patient medications.
    - Relationships: Profile.Patient

41. **Profile.PatientInsurance**
    - Description: Stores patient insurance information.
    - Relationships: Profile.Patient

42. **Profile.Patient**
    - Description: Stores patient information.
    - Relationships: Profile.Allergies, Profile.Appointments, Profile.BillingCodes, Profile.MedicalHistory, Profile.Medications, Profile.PatientInsurance

43. **Profile.Referrals**
    - Description: Stores referral information.
    - Relationships: Profile.Patient

44. **Profile.StaffDesignations**
    - Description: Stores staff designations.
    - Relationships: None

45. **Profile.Vaccinations**
    - Description: Stores vaccination information.
    - Relationships: Profile.Patient

## Stored Procedures

- **Location.spGetCities**
- **Location.spGetProvinces**
- **Profile.spDeletePatient**
- **Profile.spGetGender**
- **UAT.Profile.PatientCRUD**
- **WIP**
- **Auth.spGetAdminAccessControlSnapshot**
- **Auth.spGetAdminAuditEventSourceRows**
- **Auth.spGetAdminDataGovernanceSourceRows**
- **Auth.spGetAdminDbErrorsSourceRows**
- **Auth.spGetUserActiveRoles**
- **Auth.spGetUserByPrincipal**
- **Auth.spRegisterFailedLoginAttempt**
- **Auth.spRegisterSuccessfulLogin**
- **Contacts.spGetFormAttachments**
- **Contacts.spGetFormFieldValues**
- **Exceptions.spErrorHandling**
- **Location.spGetCountries**
- **Lookup.spGetAllergies**
- **Lookup.spGetMedications**
- **Profile.spAddClientDepartment**
- **Profile.spAddClientStaff**
- **Profile.spAddClient**
- **Profile.spAddPatient**
- **Profile.spAssignClientClinicCategory**
- **Profile.spDeleteClientDepartment**
- **Profile.spDeleteClientStaff**
- **Profile.spDeleteClient**
- **Profile.spGetClientClinicCategories**
- **Profile.spGetClientStaff**
- **Profile.spGetClient**
- **Profile.spGetMaritalStatus**
- **Profile.spGetPatientAllergies**
- **Profile.spGetPatientConsultationNotes**
- **Profile.spGetPatientMedications**
- **Profile.spGetPatientReferrals**
- **Profile.spGetPatientVaccinations**
- **Profile.spGetPatientWorklistSourceRows**
- **Profile.spGetPatient**
- **Profile.spGetRevenueClaimsSourceRows**
- **Profile.spGetSchedulingAppointments**
- **Profile.spGetSchedulingProviders**
- **Profile.spGetTaskQueueSourceRows**
- **Profile.spListClientDepartments**
- **Profile.spListClientStaff**
- **Profile.spListClients**
- **Profile.spListPatients**
- **Profile.spRestorePatient**
- **Profile.spUpdateClientDepartment**
- **Profile.spUpdateClientStaff**
- **Profile.spUpdateClient**
- **Profile.spUpdatePatient**

## Triggers and Functions

- **Contacts.tr_EnforceSinglePrimaryPatientEmail**
- **Contacts.tr_EnforceSinglePrimaryPatientPhone**
- **Contacts.tr_NormalizeAndValidateEmail**
- **Contacts.tr_NormalizeAndValidatePhoneNumber**
- **Profile.tr_ADeletePatient**
- **Profile.tr_AUpdatePatient**
- **Profile.tr_AfterInsertPatient**
- **Profile.tr_BlockPatientIDNumberUpdate**
- **Profile.tr_ValidateAppointmentStatusTransition**
