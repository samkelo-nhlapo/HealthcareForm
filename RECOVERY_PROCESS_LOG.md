# HealthcareForm Recovery Process Log

Recovery started: 2026-08-27
Purpose: restore the latest recoverable project code and database state after a suspected local revert.

## Phase 1 — Freeze and Checkpoint

Status: Completed
Date: 2026-08-27

- Working branch: `recovery/2026-08-27`
- Rescue ref: `rescue-local-20260827` → `2df4c1e`
- The working tree and index were clean before this recovery log was added.
- Remote `main`: `f279b2f` (2026-07-07); local `main` snapshot: `2df4c1e` (2026-08-23).
- Local `main` was ahead of `origin/main` by three commits.
- No reset/revert entry or dangling commit was found in local Git metadata.
- Database candidates preserved: stopped `healthcare_db` container and `001-database/HealthcareForm.bak`.
- `healthcare_db` has no Docker mounts; it must not be removed before a native backup is verified.
- The local `.bak` matches the `origin/main` blob and is treated as an older fallback, not as the proven latest database state.
- No containers, databases, or project files were reset, removed, or overwritten in Phase 1.

## Phase 2 — Database Snapshot

Status: Completed
Date: 2026-08-27

- Started the stopped `healthcare_db` container only long enough to access SQL Server.
- Created a native `COPY_ONLY` backup with `CHECKSUM` from `HealthcareForm`.
- Backup file: `001-database/recovery-backups/HealthcareForm.recovery-20260827.bak`.
- Backup size: 12,713,984 bytes; SHA-256: `c558409d6bb0a2f3606d3c85ce3358175c9776a3505b86a3930a8cb6961bc873`.
- `RESTORE VERIFYONLY WITH CHECKSUM` passed.
- Restored the backup as `HealthcareFormRecoveryVerify` and `DBCC CHECKDB` passed.

## Phase 3 — Persistent Database

Status: Completed
Date: 2026-08-27

- The pre-existing May-era persistent data set was preserved at `001-database/docker-volumes/mssql-legacy-20260827/`.
- The verified backup was staged into fresh persistent SQL Server mounts.
- A persistent SQL Server instance restored `HealthcareForm` successfully and reported it online.
- The persistent instance now runs as `healthcare-mssql` on host port `1433` with restart policy `unless-stopped`.
- Final online query and `DBCC CHECKDB` passed.
- The original `healthcare_db` container remains stopped as a rollback reference; the temporary verification container was removed.

## Phase 4 — Git Recovery

Status: Completed
Date: 2026-08-27

- Rebuilt `recovery/2026-08-27` on top of `origin/main` as a reviewable fast-forward.
- Preserved recovered application, database, tests, scripts, and documentation source.
- Removed generated/environment artifacts from Git tracking: `aider_env`, Chroma indexes, the legacy backup tree, the literal `path/to` artifact, and the `.deb` package.
- Kept those local artifacts available on disk where applicable and added ignore rules for them.
- Restored the missing `PROCESS_LOG.md` and moved the database summary to `docs/database_summary.md`.
- Kept the intentional removal of the obsolete `Profile.spAssignClientClinicCategory` procedure, which is documented in `docs/unused-stored-procedures-action-map.md`.

## Phase 5 — Remote Synchronization

Status: Completed
Date: 2026-08-27

- Remote `main` is `f279b2f`; the recovery commit is a fast-forward from that point.
- The outgoing commit removes tracked database backup artifacts from the remote while retaining local recovery copies.
- Published `recovery/2026-08-27` for rollback and review.
- Fast-forwarded remote `main` to `f39994f`; no force push was required.

## Recovery Handoff

- Local branch: `recovery/2026-08-27`.
- Remote `main` and the published recovery branch now point to the recovered project commit.
- Persistent `HealthcareForm` is online through `healthcare-mssql` on host port `1433`.
- The stopped `healthcare_db` container and `mssql-legacy-20260827` data set remain available for rollback investigation.
- Database backup and local recovery directories are intentionally ignored by Git.
