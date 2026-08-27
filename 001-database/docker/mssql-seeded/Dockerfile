ARG MSSQL_BASE_IMAGE=mcr.microsoft.com/mssql/server:2022-latest
FROM ${MSSQL_BASE_IMAGE}

USER root

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Download the MEGAcmd .deb package directly and install it.
# (apt-get install ./filename.deb automatically handles all required background dependencies)
RUN curl -fsSL -o megacmd.deb "https://mega.nz/linux/repo/xUbuntu_22.04/amd64/megacmd-xUbuntu_22.04_amd64.deb" \
    && apt-get update \
    && apt-get install -y ./megacmd.deb \
    && rm megacmd.deb \
    && rm -rf /var/lib/apt/lists/*

# Create the isolated seed folder
RUN mkdir -p /seed

# Copy the entrypoint script
COPY entrypoint-restore.sh /usr/local/bin/entrypoint-restore.sh

# Set clean permissions recursively for arbitrary UID environments
RUN chmod 755 /usr/local/bin/entrypoint-restore.sh \
    && chown -R mssql:root /seed /usr/local/bin/entrypoint-restore.sh \
    && chmod -R g=u /seed /usr/local/bin/entrypoint-restore.sh

USER mssql

ENTRYPOINT ["/usr/local/bin/entrypoint-restore.sh"]
CMD ["/opt/mssql/bin/sqlservr"]