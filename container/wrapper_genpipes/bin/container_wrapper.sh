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
elif [ "$GEN_CONTAINERTYPE" = "apptainer" ]; then
  if [ -z ${BIND_LIST+x} ]; then
    apptainer run \
      --env-file $HOME/.genpipes_env \
      --cleanenv \
      -S /var/run/cvmfs \
      -B ${GEN_SHARED_CVMFS}:/cvmfs-cache \
      --fusemount "container:cvmfs2 cvmfs-config.computecanada.ca /cvmfs/cvmfs-config.computecanada.ca" \
      --fusemount "container:cvmfs2 soft.mugqic /cvmfs/soft.mugqic"   \
      --fusemount "container:cvmfs2 ref.mugqic /cvmfs/ref.mugqic" \
      ${SCRIPTPATH}/images/genpipes.sif "$@"
  else
    apptainer run \
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
      ghcr.io/c3g/genpipes_in_a_container:latest "$@"
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
      ghcr.io/c3g/genpipes_in_a_container:latest "$@"
  fi
elif [ "$GEN_CONTAINERTYPE" = "podman" ]; then
  if [ -z ${BIND_LIST+x} ]; then
    podman run \
      -it \
      --env-file $HOME/.genpipes_env \
      --rm \
      --device /dev/fuse \
      --cap-add SYS_ADMIN \
      --tmpfs /var/run/cvmfs:rw \
      -w $PWD \
      -v $PWD:$PWD \
      --mount type=bind,source=${BIND_LIST},target=${BIND_LIST},Z \
      --mount type=bind,source=${GEN_SHARED_CVMFS},target=/cvmfs-cache,Z \
      ghcr.io/c3g/genpipes_in_a_container:latest "$@"
  else
    podman run \
      -it \
      --env-file $HOME/.genpipes_env \
      --rm \
      --device /dev/fuse \
      --cap-add SYS_ADMIN \
      --tmpfs /var/run/cvmfs:rw \
      -w $PWD \
      -v $PWD:$PWD \
      --mount type=bind,source=${GEN_SHARED_CVMFS},target=/cvmfs-cache,Z \
      ghcr.io/c3g/genpipes_in_a_container:latest "$@"
  fi
else
  echo "Unknown GEN_CONTAINERTYPE $GEN_CONTAINERTYPE. Choose between 'singularity', 'apptainer', 'docker' or 'podman'. Exiting."
  exit 1
fi
