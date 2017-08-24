#!/bin/bash

echo "container IP: $(ifconfig eth0 | grep 'inet ' | awk '{print $2}')" 

if [ "$SSH_PORT" != "" ] ; then 
	/sbin/sshd -p $SSH_PORT &
fi

if [ ! -f /var/lib/mfs/metadata.mfs ] ; then 
	cp /var/lib/mfs/metadata.mfs.empty /var/lib/mfs/metadata.mfs
fi


# auto use whatever volume set in /mnt/
# ====================================================================================
for mnt in $(ls /mnt/)
do
  echo Add mount $mnt
  echo /mnt/$mnt >> /etc/mfs/mfshdd.cfg
#  chown mfs:mfs $mnt
#  chown mfs:mfs $mnt/.lock
done

# ACTION - actions set by ACTION env var!
# ====================================================================================
if [ "$ACTION" == "" ] ; then 
	echo "\
	
	Set ACTION env var to trigger what type of server this docker should be:

		-e ACTION=chunk -e MFSMASTER=<ip of lizardfs master server>   -> chunkserver
		-e ACTION=master -> master server
		-e ACTION=shadow -e MFSMASTER=<ip of lizardfs master server>   -> shadow server
		-e ACTION=metalogger -e MFSMASTER=<ip of lizardfs master server>   -> metalogger server
		-e ACTION=cgi -> cgi web server

	ex:
		docker -e ACTION=chunk -e MFSMASTER=192.168.0.12  --net=host -v "/ZRAID/lizardfs_chunk1:/mnt/zraid:rw" --restart=always -d hradec/lizardfs:latest

	"
	#/bin/bash 
fi


if [ "$ACTION" == "chunk" ] ; then 
	echo "MASTER_HOST = $MFSMASTER" >> /etc/mfs/mfschunkserver.cfg
	mfschunkserver -d start
fi
if [ "$ACTION" == "master" ] ; then 
	mfsmaster -d start
fi
if [ "$ACTION" == "shadow" ] ; then 
	echo "MASTER_HOST = $MFSMASTER" >> /etc/mfs/mfschunkserver.cfg
	mfsmaster -d start
fi
if [ "$ACTION" == "meta" ] ; then 
	echo "MASTER_HOST = $MFSMASTER" >> /etc/mfs/mfschunkserver.cfg
	mfsmaster -d start
fi

