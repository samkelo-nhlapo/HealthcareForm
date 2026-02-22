Flyway migration scaffold

This folder contains an initial Flyway-style migrations scaffold for the HealthcareForm database.

Files created
- `migrations/sql/V1__baseline.sql` - baseline migration created from `000_INLINE_MASTER_DEPLOYMENT.sql`.
- `migrations/sql/V2__create_indexes_and_defaults.sql` - placeholder for index and default constraint DDL.
- `migrations/sql/V3__create_foreign_keys.sql` - placeholder for idempotent foreign-key creation.
- `migrations/sql/V4__seed_lookups.sql` - placeholder for lookup/reference seed data.
- `migrations/sql/V5__seed_auth_and_admin.sql` - placeholder for auth seeds and initial admin user.

Usage - Local (Flyway CLI)
1. Install Flyway CLI: https://flywaydb.org/documentation/usage/commandline
2. Run migrations against local SQL Server (example):

```bash
flyway -url="jdbc:sqlserver://localhost:1433;databaseName=HealthcareForm" \
  -user=sa -password='YourStrong!Passw0rd' \
  -locations=filesystem:./migrations/sql migrate
```

Kubernetes notes (CI/CD)
- For the `init-run-migrations-job.yaml` in `k8s/` we suggested using a ConfigMap or embedding migrations into the container image.
- Create a ConfigMap from these files (only recommended for small migration sets):

```bash
kubectl create configmap db-migrations-configmap \
  --from-file=./migrations/sql -n <namespace>
```

- Better approach for larger migrations: build a Docker image that copies `migrations/sql` into the image and run Flyway from that image (avoid ConfigMap size limits).

Next steps (recommended)
- Review `V1__baseline.sql` and split it into logical, incremental migrations (schema, indexes, FKs, seeds).
- Remove `V1__baseline.sql` after the migration history is established and migrations are split, to prevent running large duplicate DDL.
- Configure a Flyway `conf/flyway.conf` for your CI/CD pipeline and ensure credentials are provided via secrets.
- Prefer a PVC or baked-in image for migrations in Kubernetes rather than large ConfigMaps.

If you'd like, I can:
- Split `V1__baseline.sql` into smaller migrations automatically (schema vs seeds vs FK) and create a Flyway config.
- Create a minimal Docker image `Dockerfile` that includes Flyway and the `migrations/sql` folder.
