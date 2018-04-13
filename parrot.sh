#!/bin/bash
# This script loads the mugqic stack in on the host via the
# cctools's parrot's cvmfs options
# For more details on cvmfs and the parrot connector got to:
# http://cvmfs.readthedocs.io/en/stable/cpt-configure.html#parrot-connector-to-cernvm-fs
export PARROT_ALLOW_SWITCHING_CVMFS_REPOSITORIES=yes
CVMFS_CONFIG_CC=cvmfs-config.computecanada.ca:url=cvmfs-s1-east.computecanada.ca:8000/cvmfs/cvmfs-config.computecanada.ca,pubkey=/etc/cvmfs/keys/cvmfs-config.computecanada.ca.pub
export PARROT_CVMFS_REPO="${CVMFS_CONFIG_CC}"
export HTTP_PROXY='http://gr-1r15-n01:3130;DIRECT' 


usage (){
  echo -e "\nUsage: $0 [-c <PATH>] " 1>&2;
  echo -e "\nOPTION"
  echo -e "\t-a  Set the path of the cache use to store cvmfs data"
  echo -e "\t-c  Set the path for local cvmfs repo config"
  echo
}


while getopts ":a:c:" opt; do
  case $opt in
    a)
      echo "Setting parrot alien cache to $OPTARG"
      PARROT_CVMFS_ALIEN_CACHE=${OPTARG}
      ;;
    c)
      echo "Using local cvmfs config path $OPTARG"
      LOCAL_CONFIG_PATH=${OPTARG}
      ;;
    h)
      usage
      exit 0
      ;;
    \?)
      usage
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      usage
      exit 1
      ;;
  esac
done


# copy the compute.canada config locally, this will let the other repo be mounted.
/opt/cctools-6.2.8-x86_64-redhat7/bin/parrot_run cp -r /cvmfs/cvmfs-config.computecanada.ca /tmp/. 2>/dev/null

CONFIG_PATH=/tmp/cvmfs-config.computecanada.ca/etc/cvmfs/config.d
KEY_PATH=/tmp/cvmfs-config.computecanada.ca/etc/cvmfs/keys/mugqic

cvmfs_to_parrot() {
  repo_name=$1 
  # Get the CC config 
  source ${CONFIG_PATH}/${repo_name}.conf
  # Load the local config
  source ${LOCAL_CONFIG_PATH}/${repo_name}.conf 2> /dev/null
  local ref_url=${CVMFS_SERVER_URL=}
  local ref_url=${CVMFS_SERVER_URL//@fqrn@/$repo_name}
  local ref_url=${CVMFS_SERVER_URL//@fqrn@/$repo_name}
  
  local ref_key=${CVMFS_KEYS_DIR:-$KEY_PATH}
  local ref_key=$(echo "${ref_key}" | sed 's|^/cvmfs|/tmp|')

  echo $ref_url $ref_key

}

# Reading the statum connection, 
# could be loccally overwritten to optimise connections
read ref_url ref_key < <(cvmfs_to_parrot  ref.mugqic)
read soft_url soft_key < <(cvmfs_to_parrot  soft.mugqic)


export PARROT_CVMFS_REPO="<default-repositories> \
	${CVMFS_CONFIG_CC} \
	soft.mugqic:url=$soft_url,pubkey=$KEY_PATH/soft.mugqic.pub \
	ref.mugqic:url=$ref_url,pubkey=$KEY_PATH/ref.mugqic.pub"

/opt/cctools-6.2.8-x86_64-redhat7/bin/parrot_run bash

