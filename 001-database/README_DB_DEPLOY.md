# Database Deployment (HealthcareForm)

This document outlines secure deployment, run order, and Kubernetes/Docker guidance for the HealthcareForm database.

## Quick Run-order (recommended)
1. Create database + schemas (guarded checks)
2. Create tables (DDL files)
3. Create indexes (run `008-index-templates.sql`)
4. Create FK constraints (run `007-fk-templates.sql`)
5. Deploy stored procedures (run scripts in `006-stored-procedures/`)
6. Deploy functions/triggers (run `007-triggers-functions/000. MASTER_DEPLOYMENT_SCRIPT.sql`)
7. Seed lookup/reference data (run `005-table-inserts/000. MASTER_DEPLOYMENT_SCRIPT.sql` or `000_INLINE_MASTER_DEPLOYMENT.sql`)
8. Create admin and app users (use secrets; do not hardcode passwords)
9. Enable backups & audits

## Security Notes
- Do NOT store plaintext passwords in repository. Use Kubernetes Secrets or cloud secret stores.
- Provide admin password hash at execution time (for scripts that support `$(ADMIN_PASSWORD_HASH)` via `sqlcmd -v`).
- Rotate the admin password immediately after bootstrap.
- Run seeds and migrations as a migration user (not `sa`).

## Running with `sqlcmd`
```bash
sqlcmd -S <server> -U <sa_user> -P "<sa_password>" -i "001-database/000_INLINE_MASTER_DEPLOYMENT.sql"
```

## Running Modular Full Deploy (Recommended Non-Inline Path)
```bash
sqlcmd -S <server> -U <user> -P "<password>" \
  -v ADMIN_PASSWORD_HASH="<bcrypt hash>" \
  -i "001-database/000_MODULAR_MASTER_DEPLOYMENT.sql"
```

This runs schema, tables, stored procedures, triggers/functions, and seed data in order via modular scripts.

## Production/Main DB Sync (Existing Database)
For production sync on an existing database, use Flyway for migrations first, then run the production-safe sync script:

```bash
flyway -url="jdbc:sqlserver://<server>:1433;databaseName=HealthcareForm" \
  -user=<user> -password="<password>" migrate
```

```bash
sqlcmd -S <server> -U <user> -P "<password>" \
  -i "001-database/000_PRODUCTION_SYNC.sql"
```

`000_PRODUCTION_SYNC.sql` intentionally excludes:
- `CREATE DATABASE` / `ALTER DATABASE` option changes
- direct `migrations/sql/*.sql` execution
- sample provider/insurer seeds and admin bootstrap seed

## Kubernetes example (StatefulSet suggestion)
- Use `StatefulSet` with a PVC for `/var/opt/mssql`.
- Use a `Secret` for `SA_PASSWORD`.
- Use an init `Job` with Flyway or `sqlcmd` to run migrations.

See `k8s/` examples in this folder for sample manifests.

## Docker Backup + Persistent Volumes
1. Create a backup (inside running SQL Server container):
```bash
export MSSQL_SA_PASSWORD="<sa-password>"
MSSQL_CONTAINER_NAME=healthcare-mssql ./scripts/docker/backup_healthcareform_copy_only.sh HealthcareForm
```

2. Start SQL Server with persistent bind mounts:
```bash
export MSSQL_SA_PASSWORD="<sa-password>"
# Optional override (default is ./docker-volumes/mssql):
# export MSSQL_VOLUME_ROOT="./docker-volumes/mssql"
docker compose -f docker-compose.mssql.persistent.yml up -d
```

For existing non-persistent containers, use the migration helper:
```bash
export MSSQL_SA_PASSWORD="<sa-password>"
# Optional override (default is ./docker-volumes/mssql):
# export MSSQL_VOLUME_ROOT="./docker-volumes/mssql"
./scripts/docker/switch_to_persistent_mssql.sh <current_container_name>
```

This uses local persistent paths:
- `./docker-volumes/mssql/data`
- `./docker-volumes/mssql/log`
- `./docker-volumes/mssql/backup`

## Docker Seeded Image (Backup Inside Image)
Docker images cannot store runtime volumes directly, but you can bake a `.bak` into a custom image and auto-restore on first boot.

1. Build seeded image (uses latest `.bak` in `./docker-volumes/mssql/backup` by default):
```bash
export MSSQL_SEEDED_IMAGE_TAG="healthcare-form/mssql-seeded:latest"
./scripts/docker/build_seeded_mssql_image.sh
```

Optional:
```bash
# Build from a specific backup file inside this repo:
./scripts/docker/build_seeded_mssql_image.sh ./docker-volumes/mssql/backup/HealthcareForm_YYYYMMDD_HHMMSS.bak

# If you must reuse your old custom base image:
export MSSQL_BASE_IMAGE="samkelo1nhlapo/healthcare_form:latest"
```

2. Run the seeded image with persistent volumes:
```bash
export MSSQL_SA_PASSWORD="<sa-password>"
docker compose -f docker-compose.mssql.seeded.yml up -d
```

The container entrypoint restores `HealthcareForm` from `/seed/HealthcareForm.bak` only when the DB does not already exist.

## Backups
- Schedule `BACKUP DATABASE` to a mounted volume and upload to cloud storage (S3/Azure Blob).
- Keep at least 30 days of backups off-cluster.

## Monitoring
- Export metrics (Prometheus exporter) and alert on long-running queries, failed backups, and deadlocks.

## Further recommendations
- Use Flyway/Liquibase for migrations.
- Enable TDE for encryption-at-rest and Always Encrypted for PII where necessary.
- Use managed DB services in production where possible.
