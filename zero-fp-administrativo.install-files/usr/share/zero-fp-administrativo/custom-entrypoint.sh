#!/bin/bash
set -e
# --- fail fast if .env wasn't loaded ---
: "${USER_ID:?USER_ID is not set - check your .env}"
: "${GROUP_ID:?GROUP_ID is not set - check your .env}"

if which odoo >/dev/null 2>&1; then
    # ---------- Odoo container ----------
    if [ "$(id -u odoo)" != "$USER_ID" ]; then
        usermod -o -u "$USER_ID" odoo
    fi
    if [ "$(getent group odoo | cut -d: -f3)" != "$GROUP_ID" ]; then
        groupmod -o -g "$GROUP_ID" odoo
    fi

    mkdir -p /etc/odoo /var/lib/odoo /mnt/extra-addons

    chown -R "$USER_ID:$GROUP_ID" /etc/odoo /mnt/extra-addons
    chown -R "$USER_ID:$GROUP_ID" /var/lib/odoo

    exec su odoo -m -s /bin/bash -c "/usr/bin/env PATH=$PATH HOME=$HOME bash /entrypoint.sh odoo"
else
    # ---------- Postgres container ----------
    mkdir -p /var/lib/postgresql/data /var/run/postgresql

    # Fix ownership of files created by a previous (different) uid
    find /var/lib/postgresql -xdev \( ! -uid "$(id -u postgres)" \) -exec chown "$USER_ID:$GROUP_ID" {} +

    # Set ownership for /var/run/postgresql
    #chown -R "$USER_ID:$GROUP_ID" /var/run/postgresql
    chown -R "999:999" /var/run/postgresql
    chmod 755 /var/run/postgresql

    # Do NOT modify the postgres user's UID/GID
    # usermod -u "$USER_ID" postgres
    # groupmod -g "$GROUP_ID" postgres

    chown -R 999:999 /var/lib/postgresql  # Ensure PostgreSQL can write to its data directory

    HOME=/var/lib/postgresql  # Set a valid home directory
    exec su postgres -m -s /bin/bash -c "/usr/bin/env PATH=$PATH HOME=$HOME bash /usr/local/bin/docker-entrypoint.sh postgres"
fi

