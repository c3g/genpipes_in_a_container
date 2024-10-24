#!/bin/bash

# Do not modify this file modify ${SCRIPTPATH}/etc/wrapper.conf instead!
SCRIPTPATH="$(cd "$(dirname "$0")" ; pwd -P)"
SCRIPTPATH=${SCRIPTPATH%%bin}
SCRIPTPATH=${SCRIPTPATH%%/}
GEN_SHARED_CVMFS=/tmp/cvmfs-cache
GEN_CONTAINERTYPE=singularity

source "${SCRIPTPATH}"/etc/wrapper.conf

mkdir -p ${GEN_SHARED_CVMFS}

touch "$HOME/.genpipes_env" # needs to exist for the run cmd not to crash

# If GEN_CONTAINERTYPE equals singularity
if [ "$GEN_CONTAINERTYPE" = "singularity" ]; then
  if [ -z ${BIND_LIST+x} ]; then
    singularity run \
      --env-file $HOME/.genpipes_env \
      --cleanenv \
      -S /var/run/cvmfs \
      -B ${GEN_SHARED_CVMFS}:/cvmfs-cache \
      --fusemount "container:cvmfs2 cvmfs-config.computecanada.ca /cvmfs/cvmfs-config.computecanada.ca" \
      --fusemount "container:cvmfs2 soft.mugqic /cvmfs/soft.mugqic"   \
      --fusemount "container:cvmfs2 ref.mugqic /cvmfs/ref.mugqic" \
      ${SCRIPTPATH}/images/genpipes.sif "$@"
  else
    singularity run \
      --env-file $HOME/.genpipes_env \
      --cleanenv \
      -S /var/run/cvmfs \
      -B ${GEN_SHARED_CVMFS}:/cvmfs-cache \
      -B "$BIND_LIST" \
      --fusemount "container:cvmfs2 cvmfs-config.computecanada.ca /cvmfs/cvmfs-config.computecanada.ca" \
      --fusemount "container:cvmfs2 soft.mugqic /cvmfs/soft.mugqic"   \
      --fusemount "container:cvmfs2 ref.mugqic /cvmfs/ref.mugqic" \
      ${SCRIPTPATH}/images/genpipes.sif "$@"
  fi
elif [ "$GEN_CONTAINERTYPE" = "docker" ]; then
  if [ -z ${BIND_LIST+x} ]; then
    docker run \
      -it \
      --env-file $HOME/.genpipes_env \
      --rm \
      --device /dev/fuse \
      --cap-add SYS_ADMIN \
      --tmpfs /var/run/cvmfs:rw \
      -w $PWD \
      -v $PWD:$PWD \
      --mount type=bind,source=${BIND_LIST},target=${BIND_LIST} \
      --mount type=bind,source=${GEN_SHARED_CVMFS},target=/cvmfs-cache \
      c3genomics/genpipes:latest "$@"
  else
    docker run \
      -it \
      --env-file $HOME/.genpipes_env \
      --rm \
      --device /dev/fuse \
      --cap-add SYS_ADMIN \
      --tmpfs /var/run/cvmfs:rw \
      -w $PWD \
      -v $PWD:$PWD \
      --mount type=bind,source=${GEN_SHARED_CVMFS},target=/cvmfs-cache \
      c3genomics/genpipes:latest "$@"
  fi
else
  echo "Unknown GEN_CONTAINERTYPE $GEN_CONTAINERTYPE. Choose between 'singularity' or 'docker'. Exiting."
  exit 1
fi
