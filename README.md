# docker_lizardfs

A Docker image running a easily configurable LizardFS on top of Arch Linux! 

You can use it to create a container for any of the servers (master, shadow, chunk, metalogger and cgi web), and also fully configure any of the servers options using environment variables.

The chunkserver will automatically use anything mounted in /mnt/ as disks. So just add volumes using dockers `--volume "/local_disk_path/:/mnt/disk:rw"`.

The envinroment variable `MFSMASTER` sets the IP for the LizardFS master server, and `MASTER_PORT` the port. Ex: `-e MFSMASTER=192.168.0.12`

To setup the type of server to run, use `-e ACTION=<server type>`. Choose from master, shadow, chunk, meta (metadata backup) and cgi (web ui).

To setup parameters found in the conf files of each server, use `-e MFS_<parameter>=<value>`. For example, for LOCK_MEMORY=0, use `-e MFS_LOCK_MEMORY=0`.

Examples:
```
  master:
  =======
    docker stop master ; docker rm master 
    docker run -d --restart always -h master_r610 --net=host \
      --name=master \
      -v /<secure_persistent_path_to_metadata>:/var/lib/mfs:rw \
      -e MFS_CUSTOM_GOALS_FILENAME=/var/lib/mfs/mfsgoals.cfg \
      -e MFS_TOPOLOGY_FILENAME=/var/lib/mfs/mfstopology.cfg \
      -e MFS_NO_ATIME=1 \
      -e MFS_ENDANGERED_CHUNKS_PRIORITY=0.5 \
      -e MFS_CHUNKS_REBALANCING_BETWEEN_LABELS=1 \
      -e MFS_LOCK_MEMORY=1 \
      -e SSH_PORT=2200 \
      -e ACTION=master hradec/docker_lizardfs

  chunkserver:
  ============
    docker stop chunk1 ; docker rm chunk1
    docker run -d --restart always --net=host \
      --name=chunk1 \
      -v=/zfs_storage_disk1:/mnt/chunk1_disk1:rw 	\
      -v=/zfs_storage_disk2:/mnt/chunk1_disk2:rw 	\
      -e MASTER_HOST=<ip of master container/host> -e MASTER_PORT=9420 \
      -e MFS_CSSERV_LISTEN_PORT=9460 \
      -e MFS_LABEL=chunk \
      -e MFS_LOCK_MEMORY=0 \
      -e MFS_NR_OF_NETWORK_WORKERS=1 \
      -e MFS_NR_OF_HDD_WORKERS_PER_NETWORK_WORKER=10 \
      -e MFS_HDD_ADVISE_NO_CACHE=1 \
      -e MFS_HDD_PUNCH_HOLES=1 \
      -e MFS_PERFORM_FSYNC=1 \
      -e SSH_PORT=2201 \
      -e ACTION=chunk hradec/docker_lizardfs
  
  metalogger: (backup of metadata)
  ================================
    docker stop meta ; docker rm meta
    docker run -d --restart always --net=host \
      --name=meta \
      -v /<secure_persistent_backup_path_to_metadata>:/var/lib/mfs:rw \
      -e MASTER_HOST=<ip of master container/host> -e MASTER_PORT=9420 \
      -e MFS_CUSTOM_GOALS_FILENAME=/var/lib/mfs/mfsgoals.cfg \
      -e MFS_TOPOLOGY_FILENAME=/var/lib/mfs/mfstopology.cfg \
      -e ACTION=meta hradec/docker_lizardfs

  cgi: (webui)
  ================================
    docker stop cgi ; docker rm cgi
    docker run -d --restart always --net=host \
      --name=cgi \
      -e MASTER_HOST=<ip of master container/host> -e MASTER_PORT=9420 \
      -e ACTION=cgi hradec/docker_lizardfs
```
