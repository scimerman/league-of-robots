# Surf archiving

## Expects

Runs as root user to create connection and services, then normal users can use it.
Expects on the each system that either

- a ssh key-pair is already created and stored at

    /root/.ssh/id_ed25519_ar{.pub} 0600

- or it will create a key, and stop the playbook, as user needs to add public key
  to remote `.ssh/authorized_keys`.

This service will run only on user interface machine.

The groups that have access to the archive, are specified in the 

    `group_vars/[stack]_cluster/vars.yml`

and the corresponding variable named `archive_groups`.
