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

trap cleaup EXIT

export CVMFS_KEYS_DIR=${SCRIPTPATH}/etc/keys/gen
export CVMFS_ALIEN_CACHE=${GEN_SHARED_CVMFS}/alien_cache/soft.mugqic
mkdir -p $CVMFS_ALIEN_CACHE
chmod 755 ${GEN_SHARED_CVMFS}/alien_cache
${SCRIPTPATH}/lib64/ld-linux-x86-64.so.2  --library-path ${SCRIPTPATH}/lib64  \
${SCRIPTPATH}/bin/cvmfs2 -o config=${SCRIPTPATH}/etc/genconfig.conf soft.mugqic \
${GEN_SOFT}  >/dev/null

export CVMFS_ALIEN_CACHE=${GEN_SHARED_CVMFS}/alien_cache/ref.mugqic
mkdir -p $CVMFS_ALIEN_CACHE
${SCRIPTPATH}/lib64/ld-linux-x86-64.so.2  --library-path ${SCRIPTPATH}/lib64  \
${SCRIPTPATH}/bin/cvmfs2 -o config=${SCRIPTPATH}/etc/genconfig.conf ref.mugqic \
${GEN_REF} > /dev/null


if [ -z ${BIND_LIST+x} ]; then
  singularity run --cleanenv -B ${GEN_LOCAL_CVMFS}/mnt:/cvmfs  \
  ${SCRIPTPATH}/images/genpipes.sif \
  "$@"
else
  singularity run --cleanenv -B ${GEN_LOCAL_CVMFS}/mnt:/cvmfs  -B "$BIND_LIST" \
  ${SCRIPTPATH}/images/genpipes.sif \
  "$@"

fi


