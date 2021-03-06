#!/bin/bash

run(){
    echo $@
    $@
}
createCFG(){
    ACTION=$1
    # create mfsmaster/mfschunkserver/mfsmetalogger setup files, depending on the action 
    # ====================================================================================
    file=/etc/mfs/mfsmaster.cfg
    [ "$ACTION" == "chunk" ] && file=/etc/mfs/mfschunkserver.cfg
    [ "$ACTION" == "meta" ] && file=/etc/mfs/mfsmetalogger.cfg
    if [ ! -e $file ] ; then
        cp $file /tmp/__tmp__
        for e in $(env | grep MFS_) ; do
            e=$(echo $e | sed 's/MFS_//g')
            en=$(echo $e | awk -F'=' '{print $1}')
            ev=$(echo $e | awk -F'=' '{print $2}')
            grep -v $en /tmp/__tmp__ > $file
            echo "$en = $ev" >> $file
            cp $file /tmp/__tmp__
        done
        echo "====================================================================================================="
        echo "$file:"
        cat $file | while read l ; do echo -e "\t$l" ; done
        echo "====================================================================================================="
    fi

    # if no /var/lib/mfs/metadata.mfs, we have to initiate a new one! (new install!)
    # ====================================================================================
    if [ ! -e /var/lib/mfs/metadata.mfs ] ; then
        cp /etc/mfs/metadata.mfs.empty /var/lib/mfs/metadata.mfs
    fi

    # auto use whatever volume set in /mnt/
    # ====================================================================================
    if [ ! -e /etc/mfs/mfshdd.cfg ] ; then 
        remove=""
        if [ "$REMOVE" != "" ] ; then
            remove="*"
        fi
        for mnt in $(ls /mnt/)
        do
            echo Add mount $mnt
            echo "$remove/mnt/$mnt" >> /etc/mfs/mfshdd.cfg
            #  chown mfs:mfs $mnt
            #  chown mfs:mfs $mnt/.lock
        done
    fi
}

echo "====================================================================================================="
echo -e "container IP: $(ifconfig eth0 | grep 'inet ' | awk '{print $2}')\n"

if [ "$SSH_PORT" != "" ] ; then
    /sbin/sshd -p $SSH_PORT &
fi


# set master address
# ====================================================================================
default_port=9419
[ "$ACTION" == "chunk" ] && default_port=9420

if [ "$MASTER_HOST" != "" ] ; then
    export MFSMASTER=$MASTER_HOST
fi
if [ "$MASTER_PORT" != "" ] ; then
    export MFSMASTER_PORT=$MASTER_PORT
fi
if [ "$MFSMASTER" != "" ] ; then
    echo "$MFSMASTER    mfsmaster" >> /etc/hosts
fi
if [ "$MFSMASTER_PORT" == "" ] ; then
    export MFSMASTER_PORT=$default_port
fi



# Create /etc/mfs/mfs* files
# ====================================================================================
createCFG "$ACTION"


# set master address
# ====================================================================================
echo "MASTER_HOST = mfsmaster"      >> /etc/mfs/mfschunkserver.cfg
echo "MASTER_PORT = $MFSMASTER_PORT"    >> /etc/mfs/mfschunkserver.cfg

echo "MASTER_HOST = mfsmaster"      >> /etc/mfs/mfsmaster.cfg
echo "MASTER_PORT = $MFSMASTER_PORT"    >> /etc/mfs/mfsmaster.cfg

echo "MASTER_HOST = mfsmaster"      >> /etc/mfs/mfsmetalogger.cfg
echo "MASTER_PORT = $MFSMASTER_PORT"    >> /etc/mfs/mfsmetalogger.cfg




# ACTION - actions set by ACTION env var!
# ====================================================================================
if [ "$ACTION" == "chunk" ] ; then
    run mfschunkserver -d start

elif [ "$ACTION" == "master" ] ; then
    echo "PERSONALITY = master" >> /etc/mfs/mfsmaster.cfg
    run mfsmaster -d start

elif [ "$ACTION" == "shadow" ] ; then
    echo "PERSONALITY = shadow" >> /etc/mfs/mfsmaster.cfg
    run mfsmaster -d start

elif [ "$ACTION" == "meta" ] ; then
    run mfsmetalogger -d

elif [ "$ACTION" == "cgi" ] ; then
    extra=""
    [ "$PORT" != "" ] && extra=" -P $PORT"
    run /usr/sbin/lizardfs-cgiserver $extra
elif [ "$ACTION" == "mfsmount" ] ; then
    mkdir -p /LIZARDFS
    echo -e "\n/LIZARDFS          *(rw,fsid=0,async,no_root_squash,insecure,no_subtree_check,crossmnt)\n\n" > /etc/exports
    { 
        echo "[supervisord]"
        echo "nodaemon=true"

        echo "[program:mfsmount]"
        echo "command=sh -c 'mfsmount -f -o allow_other,auto_unmount,nonempty /LIZARDFS'"
        echo "autorestart=true"

        echo "[program:rpcbind]"
        echo "command=sh -c 'source /etc/conf.d/rpcbind && /usr/bin/rpcbind $RPCBIND_OPTIONS -w -f'"
        echo "autorestart=true"

        echo "[program:rpcstatd]"
        echo "command=sh -c 'export RPC_STATD_NO_NOTIFY=1 && /usr/sbin/rpc.statd'"
        echo "autorestart=true"

        echo "[program:smnotify]"
        echo "command=/usr/sbin/sm-notify"
        echo "autorestart=true"

        echo "[program:nfsd]"
        echo "command=sh -c '/usr/sbin/exportfs -r && /usr/sbin/rpc.nfsd'"
        echo "autorestart=true"
        echo -e "\n\n"
    } > /etc/supervisord.conf 
    cat /etc/supervisord.conf 
    supervisord -c /etc/supervisord.conf 
else
    echo -e "

    Set MASTER_HOST env var to the IP Address of the LizardFS Master server
    Set MASTER_PORT env var to the Port of the LizardFS Master server
    Set ACTION env var to trigger what type of server this docker should be:

            master server: -e ACTION=master
             chunk server: -e ACTION=chunk  -e MFSMASTER=<ip of lizardfs master server>
            shadow server: -e ACTION=shadow -e MFSMASTER=<ip of lizardfs master server>
        metalogger server: -e ACTION=meta   -e MFSMASTER=<ip of lizardfs master server>
           cgi web server: -e ACTION=cgi
 mfsmount shared over nfs: -e ACTION=mfsmount  

    Any volume mounted to /mnt will automatically be added as an Data Device for a chunk server, using something like: -v "/local_disk_to_use_as_chunk_disk/:/mnt/chunkDisk:rw"

    To store the data of each server locally, just mount a local folder to /var/lib/mfs, using something like: -v "/local_lizard_server_data_path/:/var/lib/mfs:rw"

    When starting a server, any env var prefixed with MFS_ will be used in the server cfg file. ex: -e ACTION=chunk -e MFS_LABEL=0 -> will put LABEL=0 into /etc/mfs/mfschunkserver.cfg

    ex:
        docker run -d \\\\\n\
            --restart=always \\\\\n\
            --net=host \\\\\n\
            -e ACTION=chunk \\\\\n\
            -e MASTER_HOST=192.168.0.12 \\\\\n\
            -v "/ZRAID/lizardfs_chunk1:/mnt/zraid:rw" \\\\\n\
            -v "/ZRAID/lizardfs_data_chunkserver:/var/lib/mfs:rw"  \\\\\n\
            hradec/lizardfs:latest

    The mfsmount action mounts lizarfs inside container and shares it over nfs. The idea is to initiate this container on a client, 
    and locally mount the the nfs share from the container.
    This has 2 advantages over just using mfsmount directly:
        1. makes access of small files and search path traversals much faster after a first run; (REALLY FASTER)
        2. one can use cachefilesd to cache lizardfs files automatically on a local storage! 
    "
    #/bin/bash
    echo "====================================================================================================="
fi


