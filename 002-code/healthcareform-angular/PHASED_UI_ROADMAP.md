# Healthcare UI Phased Plan

## Phase 1: Foundation Shell (implemented)
- Create protected clinical shell with persistent side navigation and top context bar.
- Establish role-aware primary routes for operations:
  - `/dashboard`
  - `/patients/worklist`
  - `/patients/workbench`
  - `/scheduling`
  - `/messages`
  - `/admin`
- Keep current patient CRUD workbench functional inside the new shell.

## Phase 2: Patient Flow (implemented)
- Build patient search and cohort filtering (status, clinic, risk, date range).
- Add patient chart hub page with sticky safety context (allergies, flags, consent).
- Split registration/update flows into progressive sections with save state indicators.

## Phase 3: Clinical Workflow (implemented)
- Create encounter documentation workspace.
- Add orders/results page with abnormal result emphasis.
- Add medication reconciliation page with interaction warning presentation.

## Phase 4: Operations and Revenue (implemented)
- Extend scheduling into provider/resource calendar management.
- Build billing and claims workspace (coding status, denials, payment progress).
- Add team task queue and SLA indicators.

## Phase 5: Admin and Compliance (implemented)
- Add role/permission UI aligned to backend authorization.
- Add audit log page with filterable security events.
- Add data governance views (configuration, templates, lookups).

## Phase 6: Hardening (implemented)
- Accessibility pass (WCAG 2.2 AA basics).
- Concurrency/conflict handling UX.
- Performance and loading-state polish.
- Route guard/permission guard coverage and integration tests.

## Phase 7: Live Data Integration (in progress)
- Replace hardcoded patient worklist grid with `/api/patients/worklist` live data.
- Add load-state and retry/error UX for patient worklist.
- Keep existing client-side filters for fast cohort slicing once data is loaded.
- Replace scheduling board placeholders with `/api/operations/scheduling` live snapshot data.
- Replace operations task queue placeholders with `/api/operations/task-queue` live snapshot data.
- Replace billing and claims placeholders with `/api/revenue/claims` live snapshot data.
