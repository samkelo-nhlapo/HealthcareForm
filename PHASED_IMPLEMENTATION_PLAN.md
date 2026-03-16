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
