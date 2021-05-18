#!/bin/bash


SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
SCRIPTPATH=${SCRIPTPATH%%bin}
SCRIPTPATH=${SCRIPTPATH%%/}

source ${SCRIPTPATH}/etc/wrapper.conf
TMPDIR=${TMPDIR:-/tmp}

export GEN_LOCAL_CVMFS=$(mktemp -d $TMPDIR/cvmfs_XXXXX)

GEN_REF=${GEN_LOCAL_CVMFS}/mnt/ref.mugqic
GEN_SOFT=${GEN_LOCAL_CVMFS}/mnt/soft.mugqic

mkdir -p ${GEN_SOFT}
mkdir -p ${GEN_REF}

chmod 777 ${GEN_SOFT} ${GEN_REF}

cleaup () {
#  echo unmounting ${GEN_LOCAL_CVMFS}/mnt

  try=0
  while  true ; do
    fusermount -u ${GEN_REF} 2>/dev/null
    ret=$?
    if [[ ${ret} -eq 0 || ${try} -ge  ${UMOUNT_RETRY} ]]; then
      break
    fi
    try=$(($try+1))
    sleep 1
  done

  while  true ; do
    fusermount -u ${GEN_SOFT} 2>/dev/null
    ret=$?
    if [[ ${ret} -eq 0 || ${try} -ge  ${UMOUNT_RETRY} ]]; then
      break
    fi
    try=$(($try+1))
    sleep 1
  done

  rm -r ${GEN_LOCAL_CVMFS}  2>/dev/null
}

#trap cleaup EXIT

export CVMFS_KEYS_DIR=${SCRIPTPATH}/etc/keys/gen
export CVMFS_ALIEN_CACHE=${GEN_SHARED_CVMFS}/alien_cache/soft.mugqic
mkdir -p $CVMFS_ALIEN_CACHE
chmod 777 $CVMFS_ALIEN_CACHE
chmod 777 ${GEN_SHARED_CVMFS}/alien_cache
cvmfs2 -o config=${SCRIPTPATH}/etc/genconfig.conf -o libfuse=3   soft.mugqic \
${GEN_SOFT}  

export CVMFS_ALIEN_CACHE=${GEN_SHARED_CVMFS}/alien_cache/ref.mugqic
mkdir -p $CVMFS_ALIEN_CACHE
chmod 777 $CVMFS_ALIEN_CACHE
cvmfs2 -o config=${SCRIPTPATH}/etc/genconfig.conf  -o libfuse=3   ref.mugqic \
${GEN_REF} 


#if [ -z ${BIND_LIST+x} ]; then
#  singularity run --cleanenv -B ${GEN_LOCAL_CVMFS}/mnt:/cvmfs  \
#  ${SCRIPTPATH}/images/genpipes.sif \
#  "$@"
#else
#  singularity run --cleanenv -B ${GEN_LOCAL_CVMFS}/mnt:/cvmfs  -B "$BIND_LIST" \
#  ${SCRIPTPATH}/images/genpipes.sif \
#  "$@"

#fi
