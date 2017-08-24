from base/archlinux:latest

MAINTAINER hradec <hradec@hradec.com>

# install needed packages
RUN  	echo -e '\n\n[archlinuxfr]\nSigLevel = Never\nServer = http://repo.archlinux.fr/$arch\n\n' >> /etc/pacman.conf ; \
    	pacman -Syyuu --noconfirm ; \
	pacman -S yaourt sudo net-tools nfs-utils sudo base-devel rsync  --noconfirm

# add yaourt user and group
RUN groupadd -r yaourt && \
    useradd -r -g yaourt yaourt
RUN mkdir /tmp/yaourt && \
    chown -R yaourt:yaourt /tmp/yaourt ; \
    echo 'yaourt ALL=(ALL) NOPASSWD: ALL' | EDITOR='tee -a' visudo 



USER yaourt
RUN yaourt -S lizardfs --noconfirm

USER root
RUN pacman -S nano openssh --noconfirm ;\
    pacman -Scc --noconfirm

RUN \
	echo "PermitRootLogin yes" >> /etc/ssh/sshd_config ; \
	echo "root:t" | chpasswd ;\
	/usr/bin/ssh-keygen -A ;\
	cp /etc/mfs/mfsexports.cfg.dist /etc/mfs/mfsexports.cfg ;\
	echo "PERSONALITY = master" >> /etc/mfs/mfsmaster.cfg ;\
	echo "WORKING_USER = root" >> /etc/mfs/mfsmaster.cfg ;\
	echo "WORKING_GROUP = root" >> /etc/mfs/mfsmaster.cfg ;\
	echo "EXPORTS_FILENAME = /etc/mfs/mfsexports.cfg" >> /etc/mfs/mfsmaster.cfg ;\
	echo "AUTO_RECOVERY = 1" >> /etc/mfs/mfsmaster.cfg ;\
\
	echo "LABEL = _"  >> /etc/mfs/mfsmaster.cfg ;\
	echo "WORKING_USER = root"  >> /etc/mfs/mfsmaster.cfg ;\
	echo "WORKING_GROUP = root"  >> /etc/mfs/mfsmaster.cfg ;\
	echo "ENABLE_LOAD_FACTOR = 1"  >> /etc/mfs/mfsmaster.cfg ;\
	echo "PERFORM_FSYNC = 0"  >> /etc/mfs/mfsmaster.cfg ;\
\
        echo "LABEL = _ "  >> /etc/mfs/mfschunkserver.cfg ;\
        echo "WORKING_USER = root "  >> /etc/mfs/mfschunkserver.cfg ;\
        echo "WORKING_GROUP = root "  >> /etc/mfs/mfschunkserver.cfg ;\
        echo "ENABLE_LOAD_FACTOR = 1 "  >> /etc/mfs/mfschunkserver.cfg ;\
        echo "PERFORM_FSYNC = 0 "  >> /etc/mfs/mfschunkserver.cfg 



ENV MOUNTS=''

ADD run.sh /

EXPOSE 9422


CMD [ "/run.sh" ]



