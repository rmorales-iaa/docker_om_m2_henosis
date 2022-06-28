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
#link local directories with directories inside the docker. Format: local_dir:docker_dir

DATA_IN=/media/data/docker/omh/data/in/:/home/rafa/data/in
DATA_OUT=/media/data/docker/omh/data/out/:/home/rafa/data/out

DATABASE_DATA=/media/data/docker/omh/database/:/home/rafa/data/database

ASTROMETRY_NET_INDEX_DIR=/media/data/images/tools/astrometry.net/indexes/gaia_dr_3/:/usr/local/astrometry/data

JPL_SPICE=/home/rafa/proyecto/m2/input/spice/:/home/rafa/proyecto/m2/input/spice/

M2_DATA_OUT=/media/data/docker/omh/data/out/m2:/home/rafa/proyecto/m2/output
OM_DATA_OUT=/media/data/docker/omh/data/out/om:/home/rafa/proyecto/om/output
HENOSIS_DATA_OUT=/media/data/docker/omh/data/out/henosis:/home/rafa/proyecto/henosis/output

#----------------------------------
sudo docker run \
--privileged \
 --rm \
 --user $USER \
 --net host \
 -e DISPLAY=$MY_DISPLAY \
 --volume=$XAUTHORITY_VOLUMEN \
 -v $XAUTHORITY_DIR \
 -v $DATA_IN \
 -v $DATA_OUT \
 -v $DATABASE_DATA \
 -v $ASTROMETRY_NET_INDEX_DIR \
 -v $JPL_SPICE \
 -v $M2_DATA_OUT \
 -v $OM_DATA_OUT \
 -v $HENOSIS_DATA_OUT \
 -it $DOCKER_IMAGE \
 $USER_COMMAND
#----------------------------------
