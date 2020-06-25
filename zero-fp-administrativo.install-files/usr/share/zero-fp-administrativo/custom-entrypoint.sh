#!/bin/bash

if which odoo; then
    usermod -u $USER_ID odoo
    groupmod -g $GROUP_ID odoo

    mkdir -p /etc/odoo
    mkdir -p /var/lib/odoo
    mkdir -p /mnt/extra-addons

    chown odoo.odoo /etc/odoo
    chown odoo.odoo /mnt/extra-addons
    chown odoo.odoo /var/lib/odoo

    su odoo -m -s /bin/bash -c "/usr/bin/env PATH=$PATH HOME=$HOME bash /entrypoint.sh odoo"
else
    find / -user postgres -exec chown $USER_ID.$GROUP_ID {};
    usermod -u $USER_ID postgres
    groupmod -g $GROUP_ID postgres
    mkdir -p /var/lib/postgresql/data
    chown postgres.postgres -R /var/lib/postgresql
    HOME=$(getent passwd postgres|cut -d: -f6)
    su postgres -m -s /bin/bash -c "/usr/bin/env PATH=$PATH HOME=$HOME bash /docker-entrypoint.sh postgres"
fi
