# Migrations (Flyway) - Quick Starter

This project can adopt Flyway for database migrations. Suggested steps:

1. Install Flyway CLI or use the `flyway/flyway` Docker image.
2. Create a `sql` folder with versioned migrations (V1__create_schema.sql, V2__create_tables.sql, V3__seed_lookups.sql).
3. Store migration scripts in a ConfigMap or a mounted volume for the `init-run-migrations-job`.
4. Use the `k8s/init-run-migrations-job.yaml` job to run Flyway against the running SQL Server instance on first deployment.

Example Flyway command (locally):

```bash
flyway -url=jdbc:sqlserver://localhost:1433;databaseName=HealthcareForm -user=sa -password="$SA_PASSWORD" migrate
```
