#!/bin/bash

# Do not modify this file modify ${SCRIPTPATH}/etc/wrapper.conf instead!
SCRIPTPATH="$(cd "$(dirname "$0")" ; pwd -P)"
SCRIPTPATH=${SCRIPTPATH%%bin}
SCRIPTPATH=${SCRIPTPATH%%/}
GENPIPES_SHARED_CVMFS=/tmp/cvmfs-cache
GENPIPES_CONTAINERTYPE=singularity
# Docker/Podman image, pinned to the matching release tag in released wrapper bundles
GIAC_IMAGE=ghcr.io/c3g/genpipes_in_a_container:latest

source "${SCRIPTPATH}"/etc/wrapper.conf

# Backward compatibility with wrapper.conf files using the former GEN_SHARED_CVMFS name
if [ -n "${GEN_SHARED_CVMFS:-}" ] && [ "${GENPIPES_SHARED_CVMFS}" = "/tmp/cvmfs-cache" ]; then
  GENPIPES_SHARED_CVMFS=${GEN_SHARED_CVMFS}
fi

mkdir -p ${GENPIPES_SHARED_CVMFS}
# With docker/podman, CVMFS uses the cache as the container cvmfs user, which must be able to enter it.
# Only add read/traverse rights (e.g. 700 -> 755), never remove any, so a shared group cache keeps its group write.
chmod go+rx "${GENPIPES_SHARED_CVMFS}" 2>/dev/null

touch "$HOME/.genpipes_env" # needs to exist for the run cmd not to crash

# Only pass GENPIPES_VERSION when set, an empty value would prevent the latest version detection
if [ -z "${GENPIPES_VERSION}" ]; then
  GENPIPES_ENV=
else
  GENPIPES_ENV="--env GENPIPES_VERSION=${GENPIPES_VERSION}"
fi

if [ "$GENPIPES_CONTAINERTYPE" = "singularity" ]; then
  # if GENPIPES_DIR is set use it as mount
  if [ -z "${GENPIPES_DIR}" ]; then
    GENPIPES_MOUNT=
  else
    GENPIPES_MOUNT="-B ${GENPIPES_DIR}:/genpipes"
  fi
  if [ -z "${BIND_LIST}" ]; then
    singularity run \
      ${GENPIPES_ENV} \
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
      ${GENPIPES_ENV} \
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
  if [ -z "${GENPIPES_DIR}" ]; then
    GENPIPES_MOUNT=
  else
    GENPIPES_MOUNT="-B ${GENPIPES_DIR}:/genpipes"
  fi
  if [ -z "${BIND_LIST}" ]; then
    apptainer run \
      ${GENPIPES_ENV} \
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
      ${GENPIPES_ENV} \
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
  if [ -z "${GENPIPES_DIR}" ]; then
    GENPIPES_MOUNT=
  else
    GENPIPES_MOUNT="--mount type=bind,source=${GENPIPES_DIR},target=/genpipes"
  fi
  BIND_MOUNTS=
  for BIND_PATH in ${BIND_LIST//,/ }; do
    # $PWD is already mounted, a duplicate mount point makes docker/podman fail
    [ "${BIND_PATH%/}" = "${PWD}" ] && continue
    BIND_MOUNTS="${BIND_MOUNTS} --mount type=bind,source=${BIND_PATH},target=${BIND_PATH}"
  done
  if [ -z "${BIND_LIST}" ]; then
    docker run \
      -it \
      --security-opt apparmor=unconfined \
      ${GENPIPES_ENV} \
      --env-file $HOME/.genpipes_env \
      --rm \
      --device /dev/fuse \
      --cap-add SYS_ADMIN \
      --tmpfs /var/run/cvmfs:rw \
      -w $PWD \
      -v $PWD:$PWD \
      --mount type=bind,source=${GENPIPES_SHARED_CVMFS},target=/cvmfs-cache ${GENPIPES_MOUNT} \
      ${GIAC_IMAGE} "$@"
  else
    docker run \
      -it \
      --security-opt apparmor=unconfined \
      ${GENPIPES_ENV} \
      --env-file $HOME/.genpipes_env \
      --rm \
      --device /dev/fuse \
      --cap-add SYS_ADMIN \
      --tmpfs /var/run/cvmfs:rw \
      -w $PWD \
      -v $PWD:$PWD \
      ${BIND_MOUNTS} \
      --mount type=bind,source=${GENPIPES_SHARED_CVMFS},target=/cvmfs-cache ${GENPIPES_MOUNT} \
      ${GIAC_IMAGE} "$@"
  fi
elif [ "$GENPIPES_CONTAINERTYPE" = "podman" ]; then
  if [ -z "${GENPIPES_DIR}" ]; then
    GENPIPES_MOUNT=
  else
    GENPIPES_MOUNT="--mount type=bind,source=${GENPIPES_DIR},target=/genpipes,Z"
  fi
  BIND_MOUNTS=
  for BIND_PATH in ${BIND_LIST//,/ }; do
    # $PWD is already mounted, a duplicate mount point makes docker/podman fail
    [ "${BIND_PATH%/}" = "${PWD}" ] && continue
    BIND_MOUNTS="${BIND_MOUNTS} --mount type=bind,source=${BIND_PATH},target=${BIND_PATH},Z"
  done
  if [ -z "${BIND_LIST}" ]; then
    podman run \
      -it \
      ${GENPIPES_ENV} \
      --env-file $HOME/.genpipes_env \
      --rm \
      --device /dev/fuse \
      --cap-add SYS_ADMIN \
      --tmpfs /var/run/cvmfs:rw \
      -w $PWD \
      -v $PWD:$PWD \
      --mount type=bind,source=${GENPIPES_SHARED_CVMFS},target=/cvmfs-cache,Z ${GENPIPES_MOUNT} \
      ${GIAC_IMAGE} "$@"
  else
    podman run \
      -it \
      ${GENPIPES_ENV} \
      --env-file $HOME/.genpipes_env \
      --rm \
      --device /dev/fuse \
      --cap-add SYS_ADMIN \
      --tmpfs /var/run/cvmfs:rw \
      -w $PWD \
      -v $PWD:$PWD \
      ${BIND_MOUNTS} \
      --mount type=bind,source=${GENPIPES_SHARED_CVMFS},target=/cvmfs-cache,Z ${GENPIPES_MOUNT} \
      ${GIAC_IMAGE} "$@"
  fi
else
  echo "Unknown GENPIPES_CONTAINERTYPE $GENPIPES_CONTAINERTYPE. Choose between 'singularity', 'apptainer', 'docker' or 'podman'. Exiting."
  exit 1
fi
