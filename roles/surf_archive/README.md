# Surf archiving

## Expects

Runs as root user to create connection and services, then normal users can use
moiunt point over this ssh connection. The /group/umcg-XXX/archive can be then
used at any point and is auto-mounted on demand when accessed.

Role expects that there is already a ssh key-pair created and stored at

    /root/.ssh/id_ed25519_archive{.pub} 0600

- or it will create it and role will crash when testing the connection, since
  administrator must copy content of `/root/.ssh/id_ed25519_archive.pub` into
  archive server's `.ssh/authorized_keys` file. And rerun the role.

This service will run only on user interface machine.

The groups that have access to the archive, are specified in the 

    `group_vars/[stack]_cluster/vars.yml`

and the corresponding variable named `archive_groups`.
