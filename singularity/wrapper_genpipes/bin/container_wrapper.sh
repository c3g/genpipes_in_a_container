#!/bin/bash

# Do not modify this file modify ${SCRIPTPATH}/etc/wrapper.conf instead!
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
SCRIPTPATH=${SCRIPTPATH%%bin}
SCRIPTPATH=${SCRIPTPATH%%/}
GEN_SHARED_CVMFS=/tmp/cvmfs-cache

source ${SCRIPTPATH}/etc/wrapper.conf

mkdir -p ${GEN_SHARED_CVMFS}


if [ -z ${BIND_LIST+x} ]; then
  singularity run --env-file $HOME/.genpipes_env --cleanenv -S /var/run/cvmfs -B ${GEN_SHARED_CVMFS}:/cvmfs-cache \
    --fusemount \
      "container:cvmfs2 cvmfs-config.computecanada.ca /cvmfs/cvmfs-config.computecanada.ca" \
    --fusemount "container:cvmfs2 soft.mugqic /cvmfs/soft.mugqic"   \
    --fusemount "container:cvmfs2 ref.mugqic /cvmfs/ref.mugqic" \
    ${SCRIPTPATH}/images/genpipes.sif "$@"
else
  singularity run --env-file $HOME/.genpipes_env --cleanenv -S /var/run/cvmfs -B ${GEN_SHARED_CVMFS}:/cvmfs-cache \
    -B "$BIND_LIST" \
    --fusemount \
      "container:cvmfs2 cvmfs-config.computecanada.ca /cvmfs/cvmfs-config.computecanada.ca" \
    --fusemount "container:cvmfs2 soft.mugqic /cvmfs/soft.mugqic"   \
    --fusemount "container:cvmfs2 ref.mugqic /cvmfs/ref.mugqic" \
    ${SCRIPTPATH}/images/genpipes.sif "$@"
fi
