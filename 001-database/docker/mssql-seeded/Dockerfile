ARG MSSQL_BASE_IMAGE=mcr.microsoft.com/mssql/server:2019-latest
FROM ${MSSQL_BASE_IMAGE}

USER root

ARG BACKUP_FILE
RUN test -n "${BACKUP_FILE}"

COPY docker/mssql-seeded/entrypoint-restore.sh /usr/local/bin/entrypoint-restore.sh
COPY ${BACKUP_FILE} /seed/HealthcareForm.bak

RUN chmod 755 /usr/local/bin/entrypoint-restore.sh \
    && chown mssql:root /usr/local/bin/entrypoint-restore.sh /seed/HealthcareForm.bak \
    && chmod g=u /usr/local/bin/entrypoint-restore.sh /seed/HealthcareForm.bak

USER mssql

ENTRYPOINT ["/usr/local/bin/entrypoint-restore.sh"]
CMD ["/opt/mssql/bin/sqlservr"]
