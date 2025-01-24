#!/bin/bash

# Do not modify this file modify ${SCRIPTPATH}/etc/wrapper.conf instead!
SCRIPTPATH="$(cd "$(dirname "$0")" ; pwd -P)"
SCRIPTPATH=${SCRIPTPATH%%bin}
SCRIPTPATH=${SCRIPTPATH%%/}
GENPIPES_SHARED_CVMFS=/tmp/cvmfs-cache
GENPIPES_CONTAINERTYPE=singularity

source "${SCRIPTPATH}"/etc/wrapper.conf

mkdir -p ${GENPIPES_SHARED_CVMFS}

touch "$HOME/.genpipes_env" # needs to exist for the run cmd not to crash

if [ "$GENPIPES_CONTAINERTYPE" = "singularity" ]; then
  # if GENPIPES_DIR is set use it as mount
  if [ -z ${GENPIPES_DIR+x} ]; then
    GENPIPES_MOUNT=
  else
    GENPIPES_MOUNT="-B ${GENPIPES_DIR}:/genpipes"
  fi
  if [ -z ${BIND_LIST+x} ]; then
    singularity run \
      --env GENPIPES_VERSION=${GENPIPES_VERSION} \
      --env-file $HOME/.genpipes_env \
      --cleanenv \
      -S /var/run/cvmfs \
      -B ${GENPIPES_SHARED_CVMFS}:/cvmfs-cache ${GENPIPES_MOUNT} \
      --fusemount "container:cvmfs2 cvmfs-config.computecanada.ca /cvmfs/cvmfs-config.computecanada.ca" \
      --fusemount "container:cvmfs2 soft.mugqic /cvmfs/soft.mugqic"   \
      --fusemount "container:cvmfs2 ref.mugqic /cvmfs/ref.mugqic" \
      ${SCRIPTPATH}/images/genpipes.sif "$@"
  else
    singularity run \
      --env GENPIPES_VERSION=${GENPIPES_VERSION} \
      --env-file $HOME/.genpipes_env \
      --cleanenv \
      -S /var/run/cvmfs \
      -B ${GENPIPES_SHARED_CVMFS}:/cvmfs-cache ${GENPIPES_MOUNT} \
      -B "$BIND_LIST" \
      --fusemount "container:cvmfs2 cvmfs-config.computecanada.ca /cvmfs/cvmfs-config.computecanada.ca" \
      --fusemount "container:cvmfs2 soft.mugqic /cvmfs/soft.mugqic"   \
      --fusemount "container:cvmfs2 ref.mugqic /cvmfs/ref.mugqic" \
      ${SCRIPTPATH}/images/genpipes.sif "$@"
  fi
elif [ "$GENPIPES_CONTAINERTYPE" = "apptainer" ]; then
  if [ -z ${GENPIPES_DIR+x} ]; then
    GENPIPES_MOUNT=
  else
    GENPIPES_MOUNT="-B ${GENPIPES_DIR}:/genpipes"
  fi
  if [ -z ${BIND_LIST+x} ]; then
    apptainer run \
      --env GENPIPES_VERSION=${GENPIPES_VERSION} \
      --env-file $HOME/.genpipes_env \
      --cleanenv \
      -S /var/run/cvmfs \
      -B ${GENPIPES_SHARED_CVMFS}:/cvmfs-cache ${GENPIPES_MOUNT} \
      --fusemount "container:cvmfs2 cvmfs-config.computecanada.ca /cvmfs/cvmfs-config.computecanada.ca" \
      --fusemount "container:cvmfs2 soft.mugqic /cvmfs/soft.mugqic"   \
      --fusemount "container:cvmfs2 ref.mugqic /cvmfs/ref.mugqic" \
      ${SCRIPTPATH}/images/genpipes.sif "$@"
  else
    apptainer run \
      --env GENPIPES_VERSION=${GENPIPES_VERSION} \
      --env-file $HOME/.genpipes_env \
      --cleanenv \
      -S /var/run/cvmfs \
      -B ${GENPIPES_SHARED_CVMFS}:/cvmfs-cache ${GENPIPES_MOUNT} \
      -B "$BIND_LIST" \
      --fusemount "container:cvmfs2 cvmfs-config.computecanada.ca /cvmfs/cvmfs-config.computecanada.ca" \
      --fusemount "container:cvmfs2 soft.mugqic /cvmfs/soft.mugqic"   \
      --fusemount "container:cvmfs2 ref.mugqic /cvmfs/ref.mugqic" \
      ${SCRIPTPATH}/images/genpipes.sif "$@"
  fi
elif [ "$GENPIPES_CONTAINERTYPE" = "docker" ]; then
  if [ -z ${GENPIPES_DIR+x} ]; then
    GENPIPES_MOUNT=
  else
    GENPIPES_MOUNT="--mount type=bind,source=${GENPIPES_DIR},target=/genpipes"
  fi
  if [ -z ${BIND_LIST+x} ]; then
    docker run \
      -it \
      --env GENPIPES_VERSION=${GENPIPES_VERSION} \
      --env-file $HOME/.genpipes_env \
      --rm \
      --device /dev/fuse \
      --cap-add SYS_ADMIN \
      --tmpfs /var/run/cvmfs:rw \
      -w $PWD \
      -v $PWD:$PWD \
      --mount type=bind,source=${GENPIPES_SHARED_CVMFS},target=/cvmfs-cache ${GENPIPES_MOUNT} \
      ghcr.io/c3g/genpipes_in_a_container:latest "$@"
  else
    docker run \
      -it \
      --env GENPIPES_VERSION=${GENPIPES_VERSION} \
      --env-file $HOME/.genpipes_env \
      --rm \
      --device /dev/fuse \
      --cap-add SYS_ADMIN \
      --tmpfs /var/run/cvmfs:rw \
      -w $PWD \
      -v $PWD:$PWD \
      --mount type=bind,source=${BIND_LIST},target=${BIND_LIST} \
      --mount type=bind,source=${GENPIPES_SHARED_CVMFS},target=/cvmfs-cache ${GENPIPES_MOUNT} \
      ghcr.io/c3g/genpipes_in_a_container:latest "$@"
  fi
elif [ "$GENPIPES_CONTAINERTYPE" = "podman" ]; then
  if [ -z ${GENPIPES_DIR+x} ]; then
    GENPIPES_MOUNT=
  else
    GENPIPES_MOUNT="--mount type=bind,source=${GENPIPES_DIR},target=/genpipes,Z"
  fi
  if [ -z ${BIND_LIST+x} ]; then
    podman run \
      -it \
      --env GENPIPES_VERSION=${GENPIPES_VERSION} \
      --env-file $HOME/.genpipes_env \
      --rm \
      --device /dev/fuse \
      --cap-add SYS_ADMIN \
      --tmpfs /var/run/cvmfs:rw \
      -w $PWD \
      -v $PWD:$PWD \
      --mount type=bind,source=${GENPIPES_SHARED_CVMFS},target=/cvmfs-cache,Z ${GENPIPES_MOUNT} \
      ghcr.io/c3g/genpipes_in_a_container:latest "$@"
  else
    podman run \
      -it \
      --env GENPIPES_VERSION=${GENPIPES_VERSION} \
      --env-file $HOME/.genpipes_env \
      --rm \
      --device /dev/fuse \
      --cap-add SYS_ADMIN \
      --tmpfs /var/run/cvmfs:rw \
      -w $PWD \
      -v $PWD:$PWD \
      --mount type=bind,source=${BIND_LIST},target=${BIND_LIST},Z \
      --mount type=bind,source=${GENPIPES_SHARED_CVMFS},target=/cvmfs-cache,Z ${GENPIPES_MOUNT} \
      ghcr.io/c3g/genpipes_in_a_container:latest "$@"
  fi
else
  echo "Unknown GENPIPES_CONTAINERTYPE $GENPIPES_CONTAINERTYPE. Choose between 'singularity', 'apptainer', 'docker' or 'podman'. Exiting."
  exit 1
fi
