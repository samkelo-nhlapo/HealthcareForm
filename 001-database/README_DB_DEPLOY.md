# Database Deployment (HealthcareForm)

This document outlines secure deployment, run order, and Kubernetes/Docker guidance for the HealthcareForm database.

## Quick Run-order (recommended)
1. Create database + schemas (guarded checks)
2. Create tables (DDL files)
3. Create indexes (run `008-index-templates.sql`)
4. Create FK constraints (run `007-fk-templates.sql`)
5. Seed lookup/reference data (run `005-table-inserts/000. MASTER_DEPLOYMENT_SCRIPT.sql` or `000_INLINE_MASTER_DEPLOYMENT.sql`)
6. Create admin and app users (use secrets; do not hardcode passwords)
7. Enable backups & audits

## Security Notes
- Do NOT store plaintext passwords in repository. Use Kubernetes Secrets or cloud secret stores.
- Rotate the admin password immediately after bootstrap.
- Run seeds and migrations as a migration user (not `sa`).

## Running with `sqlcmd`
```bash
sqlcmd -S <server> -U <sa_user> -P "<sa_password>" -i "001-database/000_INLINE_MASTER_DEPLOYMENT.sql"
```

## Kubernetes example (StatefulSet suggestion)
- Use `StatefulSet` with a PVC for `/var/opt/mssql`.
- Use a `Secret` for `SA_PASSWORD`.
- Use an init `Job` with Flyway or `sqlcmd` to run migrations.

See `k8s/` examples in this folder for sample manifests.

## Backups
- Schedule `BACKUP DATABASE` to a mounted volume and upload to cloud storage (S3/Azure Blob).
- Keep at least 30 days of backups off-cluster.

## Monitoring
- Export metrics (Prometheus exporter) and alert on long-running queries, failed backups, and deadlocks.

## Further recommendations
- Use Flyway/Liquibase for migrations.
- Enable TDE for encryption-at-rest and Always Encrypted for PII where necessary.
- Use managed DB services in production where possible.
