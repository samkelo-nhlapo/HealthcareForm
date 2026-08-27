## Unused Stored Procedures Action Map

This map records how the original "unused procedure" list was resolved so the repo has one current view of what is live, what is intentionally retained, and what has now been removed.

### Current status

- `Exceptions.spErrorHandling`
  Not unused in practice. It is internal SQL infrastructure and is called from stored procedure `TRY/CATCH` paths.

- `Profile.spRestorePatient`
  Wired through the API and Angular patient workbench and patient directory restore flows.

- `Profile.spListPatients`
  Wired through the patient directory and archived-record search flow.

- `Profile.spGetClient`
  Wired through the admin client detail workflow.

- `Profile.spAddClient`
  Wired through the admin client create workflow.

- `Profile.spUpdateClient`
  Wired through the admin client edit workflow.

- `Profile.spDeleteClient`
  Wired through the backend delete endpoint and the admin client detail workflow.

- `Profile.spAddClientDepartment`
  Wired through backend command endpoints and the admin client detail department editor.

- `Profile.spUpdateClientDepartment`
  Wired through backend command endpoints and the admin client detail department editor.

- `Profile.spDeleteClientDepartment`
  Wired through backend command endpoints and the admin client detail department editor.

- `Profile.spAddClientStaff`
  Wired through backend command endpoints and the admin client detail staff editor.

- `Profile.spGetClientStaff`
  Wired through the backend staff-detail endpoint and used to hydrate the admin client detail staff editor.

- `Profile.spUpdateClientStaff`
  Wired through backend command endpoints and the admin client detail staff editor.

- `Profile.spDeleteClientStaff`
  Wired through backend command endpoints and the admin client detail staff editor.

- `Profile.spAssignClientClinicCategory`
  Removed from deployment. Category assignment is already handled by `Profile.spAddClient` and `Profile.spUpdateClient` through the client create and edit workflows, and no current API, UI, or import path depends on a separate category-only command.

- `Profile.spUpsertFacilityClient`
  Intentionally retained and used by `scripts/import_hospital_network_to_db.py` for hospital-network imports.

- `Auth.spGetAdminDbErrorsSourceRows`
  Wired through the admin DB-errors diagnostics workflow.

- `Contacts.spGetFormFieldValues`
  Wired through the forms read service.

- `Contacts.spGetFormAttachments`
  Wired through the forms attachment read service.

### Phase 1

- Wire `Profile.spRestorePatient` through:
  - backend service
  - patient API controller
  - Angular patient workbench and patient directory restore flow

Status: implemented.

### Phase 2

- Wire `Profile.spListPatients` through:
  - backend patient-directory API
  - Angular patient directory route and page
  - deleted-record search and restore workflow

Status: implemented.

### Phase 3

- Wire `Profile.spGetClient` through:
  - backend client-detail API
  - Angular client directory route and page
  - Angular client detail page using patient, department, and staff reads

Status: implemented.

### Phase 4

- Wire `Profile.spAddClient` through:
  - backend create endpoint with transactional address creation
  - Angular client-create route and form
  - client-directory entry point into the create flow

Status: implemented.

### Phase 5

- Wire `Profile.spUpdateClient` through:
  - backend update endpoint with transactional address maintenance
  - Angular client-edit route and form
  - client-detail and directory links into the edit flow

Status: implemented.

### Phase 6

- Finish the remaining client-management surface end to end:
  - client delete
  - client department create, update, and delete
  - client staff create, detail, update, and delete
  - Angular admin workflows on the client detail page to drive those commands

Status: implemented.

### Phase 7

- Resolve the last classification-only item:
  - remove `Profile.spAssignClientClinicCategory` as redundant now that category assignment already flows through client create and update

Status: implemented.

### Verification notes

1. `Profile.spAssignClientClinicCategory` was removed from the modular stored-procedure deployment script, the standalone procedure file, and the inline deployment bundle.
2. `Profile.spUpsertFacilityClient` remains part of deployment because the current hospital import script executes it directly.
3. `Auth.spGetAdminDbErrorsSourceRows`, `Contacts.spGetFormFieldValues`, and `Contacts.spGetFormAttachments` are still live through backend services and are not unused.
4. Scratch and legacy SQL files such as `WIP.sql` and `UAT.Profile.PatientCRUD.sql` remain outside the supported modular deployment path.

### Exit criteria

- No procedure is labeled unused unless it is intentionally retained as legacy or internal SQL infrastructure.
- Every remaining client-management procedure is either:
  - reachable from the API and frontend, or
  - explicitly documented as intentionally retained, redundant, or removed.
