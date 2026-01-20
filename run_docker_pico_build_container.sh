#! /bin/bash

# Run a container for a Docker image for Pico build environment
# with a bind to a directory in the user's home directory on the host

set -e

if [[ -z "$1" ]] ; then
  echo "Usage: $0 [container_name]"
  exit 1;
fi

IMGNAME=$1_img
HOSTD=${HOME}/$1
docker run -it --mount type=bind,source=${HOSTD},target=/mnt/host --name $1 ${IMGNAME}
