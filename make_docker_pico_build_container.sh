#! /bin/bash

# Create docker image for Pico build environment, and run a container for it
# with a bind to a directory in the user's home directory on the host

set -e

if [[ -z "$1" ]] ; then
  echo "Usage: $0 [container_name]"
  exit 1;
fi
IMGNAME=$1_img
HOSTD=${HOME}/$1
docker build -t ${IMGNAME} .
mkdir -p ${HOSTD}
docker run -it --mount type=bind,source=${HOSTD},target=/mnt/host --name $1 ${IMGNAME}
