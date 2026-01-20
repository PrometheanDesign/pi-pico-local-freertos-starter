#! /bin/bash

# Start an existing container for a Docker image for Pico build environment
set -e

if [[ -z "$1" ]] ; then
  echo "Usage: $0 [container_name]"
  exit 1;
fi

docker start -i $1
