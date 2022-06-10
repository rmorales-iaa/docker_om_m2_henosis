#!/bin/bash
#----------------------------------
#set -x #uncomment for debuggin thsi script
#----------------------------------
#user command
USER_COMMAND=$1
#----------------------------------
DOCKER_IMAGE="local_repo/fedora:omh"
USER=rafa
#----------------------------------
XSOCK=/tmp/.X11-unix/X0
MY_DISPLAY=$DISPLAY
XAUTHORITY_DIR=/tmp/.X11-unix:/tmp/.X11-unix
XAUTHORITY_VOLUMEN="$HOME/.Xauthority:/root/.Xauthority:rw"
#----------------------------------
#link local directorioes with directories inside the docker. Format: local_dir:docker_dir
ASTROMETRY_NET_INDEX_DIR=/media/data/docker/omh/data/in/indexes_gaia_edr3/:/usr/local/astrometry/data
DATABASE_DATA=/media/data/docker/omh/database/:/home/rafa/data/database
DATA_IN=/media/data/docker/omh/data/in/:/home/rafa/data/in
DATA_OUT=/media/data/docker/omh/data/out/:/home/rafa/data/out
#----------------------------------
sudo docker run \
--privileged \
 --rm \
 --user $USER \
 --net host \
 -e DISPLAY=$MY_DISPLAY \
 --volume=$XAUTHORITY_VOLUMEN \
 -v $XAUTHORITY_DIR \
 -v $ASTROMETRY_NET_INDEX_DIR \
 -v $DATABASE_DATA \
 -v $DATA_IN \
 -v $DATA_OUT \
 -it $DOCKER_IMAGE \
 $USER_COMMAND
#----------------------------------
