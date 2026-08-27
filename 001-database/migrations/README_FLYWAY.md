Flyway migration scaffold

This folder contains an initial Flyway-style migrations scaffold for the HealthcareForm database.

Files created
- `migrations/sql/V1__baseline.sql` - baseline migration created from `000_INLINE_MASTER_DEPLOYMENT.sql`.
- `migrations/sql/V2__create_indexes_and_defaults.sql` - placeholder for index and default constraint DDL.
- `migrations/sql/V3__create_foreign_keys.sql` - placeholder for idempotent foreign-key creation.
- `migrations/sql/V4__seed_lookups.sql` - placeholder for lookup/reference seed data.
- `migrations/sql/V5__seed_auth_and_admin.sql` - placeholder for auth seeds and initial admin user.

Current status
- `V2` to `V5` are fail-fast placeholders and intentionally `THROW` until implemented.
- This prevents silent "successful" Flyway runs that skip required schema/data changes.
- The recovered `HealthcareForm` database is baselined at version `27`; the existing `V1`-`V27` files are historical and will not be replayed.

Recovered database baseline
The one-time recovery baseline was validated against a disposable clone before being applied to
`HealthcareForm`. It creates only `dbo.flyway_schema_history` metadata and does not execute the
historical migrations. Future migrations must use versions `V28` or higher.

```bash
export FLYWAY_PASSWORD="YOUR_REAL_PASSWORD"
docker run --rm --network host \
  -v "$PWD/001-database/migrations/sql:/flyway/sql:ro" \
  flyway/flyway:9.10 \
  -url="jdbc:sqlserver://127.0.0.1:1433;databaseName=HealthcareForm;encrypt=true;trustServerCertificate=true" \
  -user=sa -password="$FLYWAY_PASSWORD" \
  -locations=filesystem:/flyway/sql \
  -baselineVersion=27 \
  -baselineDescription="Recovered HealthcareForm schema" baseline
```

After the baseline exists, use `info`, `validate`, and `migrate` for future changes. Do not enable
`baselineOnMigrate` for production because it can hide an unintended database target.

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
- Start new versioned changes at `V28` and keep migration scripts independent of a hardcoded database context.
- Configure a Flyway `conf/flyway.conf` for your CI/CD pipeline and ensure credentials are provided via secrets.
- Prefer a PVC or baked-in image for migrations in Kubernetes rather than large ConfigMaps.

If you'd like, I can:
- Split `V1__baseline.sql` into smaller migrations automatically (schema vs seeds vs FK) and create a Flyway config.
- Create a minimal Docker image `Dockerfile` that includes Flyway and the `migrations/sql` folder.
