# Phased Implementation Plan (Post-Completion Improvements)

Date: 2026-03-16

Goal: Execute the post-completion improvements in clear, auditable phases while keeping the project release-ready.

Tracking artifacts:
- `PROJECT_PHASE_TRACKER.md` for phase status and checkpoints.
- `PROCESS_LOG.md` for a running activity log.

## Phase 1: Legacy Migration Package Archival (Completed)
Purpose: Reduce confusion by isolating legacy .NET Framework to .NET 6 migration materials.

Planned steps:
- Move migration package docs into `002-code/HealthcareForm/legacy-migration/`.
- Add a short `README.md` in the legacy folder that explains the scope and why it is archived.
- Update `PROJECT_PHASE_TRACKER.md` and `PROCESS_LOG.md` with completion notes.

Exit criteria:
- Legacy migration docs no longer appear in the main backend root directory.
- A clear notice exists in the legacy folder explaining purpose and usage.
- Phase status is updated in `PROJECT_PHASE_TRACKER.md`.

## Phase 2: Documentation Alignment (Completed)
Purpose: Ensure counts, schema lists, and deployment notes match the actual SQL scripts.

Planned steps:
- Treat `001-database/002-schema/001_schema_script.sql` and the master deployment scripts as source of truth.
- Update high-visibility docs that mention schema/table/procedure counts or schema names.
- Add a short “source of truth” note to the main docs to prevent future drift.

Candidate files to update:
- `INDEX.md`
- `COMPLETE_HEALTHCARE_SCHEMA_GUIDE.md`
- `PROJECT_COMPLETION_SUMMARY.md`
- `ENTITY_RELATIONSHIP_DIAGRAM.md`
- `DELIVERY_SUMMARY.txt`

Exit criteria:
- Schema count and schema names match the SQL scripts.
- Stored procedure references match `001-database/006-stored-procedures/`.
- Docs include a source-of-truth reminder.

## Phase 3: Stored-Procedure API Integration Tests (Completed)
Purpose: Provide minimal end-to-end coverage for each stored-procedure-backed endpoint.

Planned steps:
- Add integration tests in `002-code/HealthcareForm.Tests/` using the existing xUnit setup.
- Gate tests on a configured connection string to avoid failing in non-DB environments.
- Cover at least one happy-path call per stored-procedure-backed endpoint.
 - Use `HF_TEST_DB_CONNECTION` (or `ConnectionStrings__HealthcareEntity`) to enable DB-backed runs.

Candidate endpoints:
- `GET /api/patients/worklist`
- `GET /api/lookups/*` (genders, marital statuses, countries, provinces, cities)
- `GET /api/operations/scheduling`
- `GET /api/operations/task-queue`
- `GET /api/revenue/claims`
- `GET /api/admin/access-control`
- `GET /api/admin/audit-log`
- `GET /api/admin/data-governance`

Exit criteria:
- Tests execute successfully when a DB connection string is provided.
- Tests are skipped cleanly when the DB is not configured.
- Stored procedure validation and test expectations are documented.

## Phase 4: Operational Readiness & Maintenance (Completed)
Purpose: Establish ongoing maintenance conventions and operational clarity.

Planned steps:
- Decide whether to keep or drop tracked editor settings (`.vscode/settings.json`).
- Add a short `CONTRIBUTING.md` or `DEVELOPING.md` with local workflows and test matrix.
- Document how/when DB-backed integration tests should run in CI.

Exit criteria:
- Repo has a clear contributor/developer guide.
- CI/test guidance includes the DB-backed tests.
- Local editor/config artifacts are either documented or untracked.

## Phase 5: Schema Utilization Matrix (Completed)
Purpose: Document which tables and schemas are exercised by the API and highlight gaps.

Planned steps:
- Scan API services for stored procedure usage.
- Map stored procedures to their referenced tables.
- Capture tables not referenced by API procedures in a single matrix document.

Exit criteria:
- `TABLE_USAGE_MATRIX.md` captures endpoint to procedure to table mappings.
- Tables not referenced by API procedures are listed for future integration.
- `PROJECT_PHASE_TRACKER.md` and `PROCESS_LOG.md` reflect completion.

## Phase 12: Unused Schema Activation (Completed)
Purpose: Integrate high-value but currently unused tables into the API and surface them to the product.

Planned steps:
- Confirm scope of unused tables and assign each to a feature slice.
- Implement stored procedures and API endpoints for the selected slice.
- Add integration tests for the new endpoints.
- Update `TABLE_USAGE_MATRIX.md` to reflect new coverage.

Candidate slices:
- Clinical history: `Profile.Allergies`, `Profile.Medications`, `Profile.Vaccinations`, `Profile.ConsultationNotes`, `Profile.Referrals`, `Lookup.Allergies`, `Lookup.Medications`.
- Client/clinic admin: `Profile.ClientClinicCategories`, `Profile.ClientDepartments`, `Profile.ClientStaff`, `Profile.StaffDesignations`.
- Dynamic forms: `Contacts.FormAttachments`, `Contacts.FormFieldValues`.

Current slice status:
- Client/clinic admin slice integrated with read-only API endpoints for clinic categories, clients, departments, and staff.
- Clinical history + reference lookups slice integrated with read-only API endpoints for patient allergies, medications, vaccinations, consultation notes, referrals, and lookup lists.
- Dynamic forms slice integrated with read-only API endpoints for form field values and attachments.
- Admin diagnostics slice integrated with read-only API endpoint for database error reporting.

Next slice recommendation (2026-03-17):
- None. All currently unused tables are now integrated.

Minimal checklist for the next slice:
- Start a new phase if additional expansion work is required.

Exit criteria:
- At least one slice is fully integrated (procedure + API + tests).
- `TABLE_USAGE_MATRIX.md` updated with new coverage.
- `PROJECT_PHASE_TRACKER.md` and `PROCESS_LOG.md` updated with progress.
