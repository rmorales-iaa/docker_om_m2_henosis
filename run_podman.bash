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
#local directories
LOCAL_DATA_IN=/home/rafa/Downloads/deleteme/test/in/
LOCAL_DATA_OUT=/home/rafa/Downloads/deleteme/test/out/
LOCAL_DATABASE_DATA=/home/rafa/Downloads/deleteme/test/database/

LOCAL_ASTROMETRY_NET_INDEX_DIR=/home/rafa/images/tools/astrometry.net/indexes/gaia_dr_3/

LOCAL_JPL_SPICE=/home/rafa/proyecto/m2/input/spice
LOCAL_M2_DATA_OUT=/home/rafa/Downloads/deleteme/test/out/m2/
LOCAL_OM_DATA_OUT=/home/rafa/Downloads/deleteme/test/out/om/
LOCAL_HENOSIS_DATA_OUT=/home/rafa/Downloads/deleteme/test/out/henosis/
#----------------------------------
#local gui
XSOCK=/tmp/.X11-unix/X0
MY_DISPLAY=$DISPLAY
XAUTHORITY_DIR=/tmp/.X11-unix:/tmp/.X11-unix
XAUTHORITY_VOLUMEN="$HOME/.Xauthority:/root/.Xauthority:rw"
#----------------------------------
#link local directories with directories inside the docker. Format: local_dir:docker_dir

DATA_IN=$LOCAL_DATA_IN/:/home/rafa/data/in
DATA_OUT=$LOCAL_DATA_OUT/:/home/rafa/data/out

DATABASE_DATA=$LOCAL_DATABASE_DATA/:/home/rafa/data/database

ASTROMETRY_NET_INDEX_DIR=$LOCAL_ASTROMETRY_NET_INDEX_DIR/:/usr/local/astrometry/data

JPL_SPICE=$LOCAL_JPL_SPICE:/home/rafa/proyecto/m2/input/spice/

M2_DATA_OUT=$LOCAL_M2_DATA_OUT/:/home/rafa/proyecto/m2/output
OM_DATA_OUT=$LOCAL_OM_DATA_OUT/:/home/rafa/proyecto/om/output
HENOSIS_DATA_OUT=$LOCAL_HENOSIS_DATA_OUT/:/home/rafa/proyecto/henosis/output
#----------------------------------
podman run \
  --privileged \
 --rm \
 --user $USER \
 --net host \
 --hostname=omh_docker \
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
