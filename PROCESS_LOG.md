# Process Log

## 2026-03-17
- Re-scanned API stored-procedure usage and refreshed `TABLE_USAGE_MATRIX.md` (45 used, 0 unused).
- Added lookup stored procedures and endpoints for allergies and medications.
- Added patient clinical history procedures and endpoints for allergies, medications, vaccinations, consultation notes, and referrals.
- Updated stored-procedure deployment script to include the new clinical/lookup procedures.
- Extended integration tests to cover the new lookups and patient clinical endpoints.
- Updated Phase 12 plan to mark the clinical history slice integrated and set the next slice to dynamic forms.
- Added form field value and attachment procedures plus API endpoints for dynamic forms.
- Updated stored-procedure deployment script to include the dynamic forms procedures.
- Updated Phase 12 plan and tracker to mark the dynamic forms slice complete and set the next slice to admin diagnostics (`Auth.DB_Errors`).
- Updated table usage matrix to reflect dynamic forms coverage (remaining gap was `Auth.DB_Errors`).
- Added admin DB error stored procedure, contracts, and endpoint; updated tests and tracking to close Phase 12.

## 2026-03-16
- Initiated phased improvement plan in `PHASED_IMPLEMENTATION_PLAN.md`.
- Started Phase 1 (legacy migration package archival).
- Moved legacy migration documents into `002-code/HealthcareForm/legacy-migration/`.
- Added legacy migration README and updated `PROJECT_PHASE_TRACKER.md`.
- Completed Phase 2 documentation alignment (counts, schema names, and source-of-truth references).
- Completed Phase 3 stored-procedure integration tests (API harness, test auth, DB-guarded checks).
- Integration tests use `HF_TEST_DB_CONNECTION` or `ConnectionStrings__HealthcareEntity` to enable DB-backed runs.
- Ran `dotnet test` with `HF_TEST_DB_CONNECTION`; all tests passed (11 total).
- Started Phase 10 (operational readiness & maintenance planning).
- Added `DEVELOPING.md` and documented DB-backed test expectations.
- Updated `.gitignore` to keep `.vscode/settings.json` tracked.
- Produced `TABLE_USAGE_MATRIX.md` mapping API endpoints to stored procedures and table references, highlighting 14 tables not referenced by API procs.
- Added Phase 12 planning for unused schema activation and slice selection.
- Implemented Phase 12 client/clinic admin slice with new API endpoints, contracts, and integration tests; updated table usage matrix and tracker.
