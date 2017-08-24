# docker_lizardfs

A Docker image running a easily configurable LizardFS on top of Arch Linux! 

You can use it to create a container for any of the servers (master, shadow, chunk, metalogger and cgi web), and also fully configure any of the servers options using environment variables.

The chunkserver will automatically use anything mounted in /mnt/ as disks. So just add volumes using dockers --volume "/local_disk_path/:/mnt/disk:rw"!

The envinroment variable MFSMASTER sets the IP for the LizardFS master server. Ex: -e MFSMASTER=192.168.0.12

run

  docker run -ti hradec/lizardfs:latest


for an up-to-date help!
