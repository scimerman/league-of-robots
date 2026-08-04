# Repository servers role

## Intro

This role uses `logs_library` development key as a default key for the creation of all the cryptographic communication.

## TLDR

    [me@mac ~]$ ssh admin@spring+repo-primary
    [me@repo-primary ~]$ sudo -u repo bash
    [admin@repo-primary ~]$ $ cd /mnt/repos

    [admin@repo-primary /mnt/repos]$ # Option 1: for one specific repository
    [admin@repo-primary /mnt/repos]$ ./1_sync_repo_to_new_version.sh alma9 baseos &
        - Log file: /mnt/repos/logs/scripts/alma9/baseos/20260804-104418
    ( press enter )
    [admin@repo-primary /mnt/repos]$ tail /mnt/repos/logs/scripts/alm/mnt/repos/logs/scripts/alma9/baseos/20260804-104418
            ...
        (2297/2298): zsh-5.8-9.el9.x86_64.rpm            32 MB/s | 2.9 MB     00:00    
        (2298/2298): linux-firmware-20260411-155.5.el9_  38 MB/s | 631 MB     00:16    
          New version created:   /mnt/repos/1versions/alma9/baseos/20260804-104418
        done
    ( press CTRL+c )
    [admin@repo-primary /mnt/repos]$ # Option 2: all repositories for entire distribution
    [admin@repo-primary /mnt/repos]$ ./1_sync_repo_to_new_version.sh alma9 &

    [admin@repo-primary /mnt/repos]$ # Option 1: for a stack's SPECIFIC repository deploy the specific version
    [admin@repo-primary /mnt/repos]$ ./2_new_repo_distribution.sh -s nb -d alma9 -r ALL -v 20260804-112904
    [admin@repo-primary /mnt/repos]$ # Option 2: for a stack's ALL repositories deploy the specific version
    [admin@repo-primary /mnt/repos]$ ./2_new_repo_distribution.sh -s nb -d alma9 -r ALL -v 20260804-112904
    [admin@repo-primary /mnt/repos]$ 
    [admin@repo-primary /mnt/repos]$ 
    [admin@repo-primary /mnt/repos]$ 
    [admin@repo-primary /mnt/repos]$ 
    [admin@repo-primary /mnt/repos]$ 
    [admin@repo-primary /mnt/repos]$ 
## Dependecies

This role has dependency on _rsyncd_ role that provides rsync module configuration.
Rsyncd role itself has a dependency on the _sshd_ role.


## Repository settings

The Repository Server role mirrors local repositories based on the `yum_repos` variable in `group_vars/all/repos.yml`.

Deployment Logic
 - Filtering: Only repositories with `repo_server_download: True` are processed.
 - Remote server file structure
   - All repositroy configuration files are stored inside top directory /mnt/repos/dnf/repos.d/
   - Master Config: A `[distribution].conf` file is created at the root of the `repos.d` folder to point to the specific distribution directory.
   - All the Repo Files for specific distrubution are stored inside `/mnt/repos/dnf/repos.d/[distribution]/` (e.g. `.../repos.d/alma9/`).


## Configurations scripts

 - the deployment and configuration scripts are added to `/mnt/repos/` folder
   - `1_xxx.sh` script syncronizes (download) the latest packages and creates
     a new version of this syncronization
   - `2_xxx.sh` script exposes this fresh download to the stack that will be
     using this version
   - `3_xxx.sh` script cleans all the versions that are not used by any stack
     deployments

## Server file storage

The total size of the individual repositories varies, but can be easily 100GB or
more. Therefore to save the space of the each version, the packages are downloaded
to the `0cache/[distribution]` directory. And all the future syncronization
update the entire structure every time - remove the packages which are not in
the original repository any more.

Versions are stored by making copy (on write - reflink) into `1version` folder at
the end of each syncronization. This enforces that the actually used disk space
is reduced to bare minimum.

## Debug

### Getting size and other information for all repositories of specific distribtuion

```
    ssh [admin-usernam]@hatch+repo-primary
    sudo -u repo bash
    cd /mnt/repos
    dnf repoinfo --conf /mnt/repos/dnf/repos.d/oracle8.conf
    ...
    Repo-id      : ol8_appstream
    Repo-name    : Oracle Linux 8 Application Stream (x86_64)
    Repo-size    : 312 G
    Available Packages: 10,842
```

## Certificates

Repo servers are currently created in the `patchcord_library`. Therefore the cerfiticates
are stored in the `files/patchcord_library/` folder.

To create and encrypt certificate

```
    openssl req -x509 -newkey rsa:4096 -keyout files/patchcord_library/srm-ca.key -out files/patchcord_library/srm-ca.pem -sha256 -days 3650 -nodes -subj "/C=NL/ST=Groningen/L=Groningen/O=UMCG/OU=GCC/CN="
    ansible-vault encrypt --encrypt-vault-id patchcord_library files/patchcord_library/srm.key
```
