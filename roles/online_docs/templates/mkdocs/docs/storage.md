#jinja2: trim_blocks:True
# Keep - What is stored where on {{ slurm_cluster_name | capitalize }}

## Introduction

We work with multiple storage systems ranging from large, parallel, shared storage available on multiple servers to small local storage available on a single server. 
Some of these storage systems are optimized for _high performance_ (HP), others for _high availability_ (HA) and yet others for slow, but cheap long term archiving of data. 
The exec summary:
```
#
# Centrally installed software and reference data:
#
/apps/software/:          Applications centrally deployed with EasyBuild
/apps/modules/:           Lmod module files for the centrally deployed applications
/apps/sources/:           Source code for the centrally deployed applications
/apps/data/:              Centrally deployed reference data sets like the human genome
#
# Users:
#
/home/${user}/:           Your small home dir for personal settings/configs only
#
# Groups:
#
{% if lfs_mounts | selectattr('lfs', 'search', 'arc[0-9]+$') | list | length %}
/groups/${group}/arc*/:   ARChive; Your group's slow dirs for raw data and final results
{% endif %}
{% if lfs_mounts | selectattr('lfs', 'search', 'prm[0-9]+$') | list | length %}
/groups/${group}/prm*/:   PeRManent; Your group's fast dirs for raw data and final results
{% endif %}
{% if lfs_mounts | selectattr('lfs', 'search', 'rsc[0-9]+$') | list | length %}
/groups/${group}/rsc*/:   Read-only Storage Cache; Your group's fast dirs for (reference) data sets
{% endif %}
{% if lfs_mounts | selectattr('lfs', 'search', 'tmp[0-9]+$') | list | length %}
/groups/${group}/tmp*/:   TeMPorary; Your group's fastest dirs for temporary data
{% endif %}
```

Please consult the info below and make sure you know what to store where!

#### Top 4 of blunders, that will result in disaster rather sooner than later
1. Use many jobs to create massive IO load on your home dir making everybody's home dir very slow or worse...
1. Use a sub optimal data structure or experimental design resulting in many thousands of files in a directory either by using small files instead of a relatively small number of large files or by never creating sub dirs.
   As (our) large parallel file system are optimized for large files, creating many many small files will result in high load on the meta-data servers killing performance or worse...
1. Never cleanup and run out of space crashing both your own jobs as well as those of all other users from the same group.
1. Never finish an experiment and postpone the task of moving the _final_ results from the HP _tmp_ file systems to the HA _prm_ file systems forever.
   As the **HP tmp filesystems have no backups and old files are deleted automatically**, you will loose your results automagically.
   A four year PhD project is not a single experiment! Split your work in batches / experiments that can be completed in a reasonable amount of time: weeks rather than months.
   Completed means the results were QC-ed and documented, the data that needs to be kept for the long term was migrated to _prm_ storage and the rest was deleted from _tmp_ to make room for new batches / experiments.

## Software

See the [Software](../software/) section for both centrally installed software as well as for options to install software in a custom environment.

## Centrally deployed reference data

We deploy reference data sets like for example the human genome in a central place, which is available on all servers:
```
/apps/data/...
```
Please use them from that location as opposed to downloading yet another copy elsewhere. 
If your pet reference data set is missing [contact the helpdesk via email](../contact/) to have it added.

## Your personal home dir @ /home/${user}

This is were you have limited space to store your personal settings/preferences/configs like terminal colors, terminal font sizes, etc.
Your home is available on all servers of a cluster, but different clusters have separate homes.
A typical home dir contains << 100 Mb of data:

 * ~/.bashrc file with custom settings, aliases, commands for bash.
 * ~/.ssh folder with keys and settings required for SSH access.
 * Various other (hidden) files / folders that contain settings.

Important:

 * Your home is designed to be a **private folder**; do not try to change permissions to share data located in your home with other users.
 * Your home is on _HA_ and hence not on _HP_ storage. Therefore you should try to minimize the IO load on your home to make sure everyone can enjoy a fast responsive home.
 * Do not abuse your home dir, so:
    * Don't waste resources by installing in your private home dir yet another copy of the same software package that is already available centrally from the module system.
    * Don't run anything that causes massive random IO on your home dir.  
      E.g. don't store job scripts submitted to cluster nodes in homes.
    * Don't store experimental data in your home.  
      Your home is for personal preferences; not for experiments. 
      Use a group dir for the latter (see below).

## Group dirs @ /groups/${group}/...

Every user is a member of at least one main group. A main group has access to large shared storage systems.
The following types of shared storage are available on {{ slurm_cluster_name | capitalize }}:

{% if lfs_mounts | selectattr('lfs', 'search', 'arc[0-9]+$') | list | length %}
* ```/groups/${group}/arc*/```: ARChive storage  
  Large capacity, but relatively slow. Data is protected with backups.
  Designed for archived raw data and final results, that need to be preserved, but are no longer used on a regular basis.
  If this data is needed again for new analysis, a copy must be retrieved from _arc_ and staged on _tmp_
  {% if lfs_mounts | selectattr('lfs', 'search', 'rsc[0-9]+$') | list | length %}or _rsc_{% endif %}.
{% endif %}
{% if lfs_mounts | selectattr('lfs', 'search', 'prm[0-9]+$') | list | length %}
* ```/groups/${group}/prm*/```: PeRManent storage  
  Large capacity and relatively fast. Data is protected with backups.
  Designed for raw data and final results, which are (still) used on a regular basis.
  If this data is needed again for new analysis, a copy must be retrieved from _prm_ and staged on _tmp_
  {% if lfs_mounts | selectattr('lfs', 'search', 'rsc[0-9]+$') | list | length %}or _rsc_{% endif %}.
{% endif %}
{% if lfs_mounts | selectattr('lfs', 'search', 'rsc[0-9]+$') | list | length %}
* ```/groups/${group}/rsc*/```: Read-only Storage Cache  
  Intermediate capacity, relatively fast and cheaper than _prm_ and _tmp_.
  Data is not protected with backups, but write access is limited to the group's data managers on the UI.
  These file systems are mounted read-only on compute nodes. This makes them ideal for reference data a.k.a. released versions of data sets,
  which should not be modified (accidentally) by jobs on the compute nodes.
{% endif %}
{% if lfs_mounts | selectattr('lfs', 'search', 'tmp[0-9]+$') | list | length %}
* ```/groups/${group}/tmp*/```: TeMPorary storage  
  Intermediate capacity and fastest. Data is not protected with backups.
  Designed for temporary storage of intermediate files and new results produced by jobs running on the compute nodes of the cluster.
{% endif %}

Note that your group(s) may have access to only a subset of shared storage types and not all types are available on all clusters.
The minimal requirements for a main group are as follows:

 * Group leaders / PIs can request new main groups. When the main group is created they will be registered as the group owners.
 * Group owners are responsible for
    * Processing (accepting or rejecting) requests for group membership.
    * Securing funding and paying the bills.
    * Appointing data managers for their group.
 * Data managers are responsible for the group's data on ```prm```, ```rsc``` (if available) and ```arc``` (if available) storage systems and
    * Ensure the group makes arrangements what to store how and where. E.g file naming conventions, file formats to use, etc.
    * Enforce the group's policy on what to store how and where by reviewing data sets produced by other group members on ```tmp``` file systems before migrating/copying them to ```prm``` or ```arc``` (if available).
    * Can put released versions of data sets on ```rsc``` storage, so it can be used as reference data by alle members of the group.
    * Have read-write access to all file systems including ```prm```, ```rsc``` (if available) and ```arc``` (if available).
 * Other _regular_ group members:
    * Have read-only access to ```prm```, ```rsc``` (if available) and ```arc``` (if available) file systems to check-out existing data sets.
    * Have read-write access to ```tmp``` file systems to produce new results.
    * Can request a data manager to review and migrate a newly produced data set to ```prm``` or ```arc``` (if available) file systems.
 * A group has at least one owner and one data manager, but to prevent delays in processing membership request and data set reviews a group has preferably more than one owner and more than one data manager.
 * Optionally sub groups may be used to create more fine grained permissions to access data.
    * A sub group inherits group owners, data managers and quota limits from the main group.
    * All members of the sub group must be members of the main group.
    * The members of the sub group are a subset of the members of the main group.

## Quota

We use a quota system, which limits how much storage space you can consume. 
If you exceed your limits you can not write any new data before you delete something else to free up space. 
Home directories have _user_ quota, which means that if you run out of space, you are the only one affected. 
All other file systems use _group_ or _file set_ quota, which means that if you run out of space everybody from your group (or file set) is also out of space on that file system, but other groups are not affected. 
There are two limits and a timer period that determines how these interact:

 * **quota (soft)**: exceed your quota and you can still write data until you've reached the (hard) limit or until the timer that kicks in expires whichever comes first.
 * **limit (hard)**: exceed your (hard) limit and you are instantly prohibited from writing any data. You will need to delete something else to free up space before you can write new data.
 * **timers**: after exceeding your quota the timer kicks in and if you do not reduce your data volume to less than your quota, the soft quota will temporarily become your hard limit when the timer expires.
   You will need to reduce your data volume to less than your quota to reset the timer as well as the (hard) limit.

The combination of quota, larger limits and timers prevents users from permanently exceeding their quota while allowing them to temporarily consume more space to handle peak loads. 
Note that if you write a lot of data and fast it is possible to exceed both your quota as well as the larger limit in a time frame that is much shorter than the quota reporting interval. 
In that case you may run out of disk space before you received your first warning.

Different types of file systems come with their own quota tools, which produce different reports. 
Therefore we use a custom wrapper to unify the output for various file systems:
```
module load cluster-utils
quota
```
The report will show 11 columns:
```
   1 Quota type = one of:
      (U) = user quota
      (P) = (private) group quota: group with only one user and used exclusively for home dirs.
      (G) = (regular) group quota: group with multiple users.
      (F) = file set quota: different technology used on the {{ slurm_cluster_name | capitalize }} cluster to also manage quota for a group with multiple users.
   2 Path/Filesystem = (part of) a storage system controlled by the quota settings listed.
   3 used   = total amount of disk space ("blocks") your data consumes.
   4 quota  = soft limit for space.
   5 limit  = hard limit for space.
   6 grace  = days left before the timer for space quota expires.
   7 used   = total number of files and folders ("inodes") your data consists of.
   8 quota  = the soft limit for the number of files and folders .
   9 limit  = the hard limit for the number of files and folders.
  10 grace  = days left before the timer for the number of files and folders quota expires.
  11 status = whether you exceeded any of the quota/limits or not.
```

## List of storage devices / mount points used on {{ slurm_cluster_name | capitalize }}
| Path | Function | (Soft) Quota | (Hard) Limit | Backup | Cleanup | Mounted on UIs | Mounted on DAIs | Mounted on compute nodes |
|:---- |:-------- | ----------:| ----------:|:------:|:-------:|:--------------:|:---------------:|:------------------------:|
{% for mount in lfs_mounts | selectattr('lfs', 'match', '^home$') | list %}
| ```/{{ mount.lfs }}``` | Home dirs from shared file system for personal settings/preferences. | 1 GB | 2 GB | No | No | Yes | Yes | Yes |
{% endfor %}
{% for mount in lfs_mounts | selectattr('lfs', 'search', 'prm[0-9]+$') | list %}
| ```/groups/${group}/{{ mount.lfs }}``` | High Availability shared storage system for permanent data. | Several TBs; varies per group |  quota + ~10%| Yes | No | Yes | No | No |
{% endfor %}
{% for mount in lfs_mounts | selectattr('lfs', 'search', 'arc[0-9]+$') | list %}
| ```/groups/${group}/{{ mount.lfs }}``` | High Availability shared storage system for archived data. | Several TBs; varies per group |  quota + ~10%| Yes | No | Yes | No | No |
{% endfor %}
{% for mount in lfs_mounts | selectattr('lfs', 'search', 'tmp[0-9]+$') | list %}
| ```/groups/${group}/{{ mount.lfs }}``` | High Performance shared storage system for temporary data. | Several TBs; varies per group | quota + ~10% | No | Yes, when older than 45 days | Yes | No | Yes |
{% endfor %}
{% for mount in lfs_mounts | selectattr('lfs', 'search', 'rsc[0-9]+$') | list %}
| ```/groups/${group}/{{ mount.lfs }}``` | High Performance shared storage system for cached (reference) data. | Several TBs; varies per group | quota + ~10% | No | No | Yes | No | read-only |
{% endfor %}

## The life cycle of experimental data

 1. Generate _"raw data"_ in a lab and upload that to a folder in ```/groups/${group}/prm*/rawdata/...``` on HA storage.
 1. Select a (sub)set of your _"raw data"_ you want to analyze on the cluster and stage this data by copying it from ```/groups/${group}/prm*/rawdata/...``` to ```/groups/${group}/tmp*/...``` on HP storage.  
    Make sure your in-silico experiment processes a chunk of data that can easily be analysed in << 45 days.
 1. Generate jobs, which will read and write to and from folders in ```/groups/${group}/tmp*/...``` on HP storage systems.
 1. Submit your jobs on the Slurm workload manager with the ```sbatch``` command.
 1. Once all jobs have finished successfully, assess the results and if they pass QC, store your final results by copying them to a folder in ```/groups/${group}/prm*/projects/...``` on HA storage.
 1. Cleanup by deleting data from ```/groups/${group}/tmp*/...``` to free up space for your next experiment.
 1. Document and publish your experiment/data.

