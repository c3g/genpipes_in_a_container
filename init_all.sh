#!/bin/bash
# This script loads the mugqic stack in on the host via the
# cctools's parrot's cvmfs options
# For more details on cvmfs and the parrot connector got to:
# http://cvmfs.readthedocs.io/en/stable/cpt-configure.html#parrot-connector-to-cernvm-fs
# It also loads the lmod software to load mugqic modules 

export PARROT_ALLOW_SWITCHING_CVMFS_REPOSITORIES=yes
CVMFS_CONFIG_CC=cvmfs-config.computecanada.ca:url=cvmfs-s1-east.computecanada.ca:8000/cvmfs/cvmfs-config.computecanada.ca,pubkey=/etc/cvmfs/keys/cvmfs-config.computecanada.ca.pub
export PARROT_CVMFS_REPO="${CVMFS_CONFIG_CC}"
#export HTTP_PROXY='http://gr-1r15-n01:3130;DIRECT' 
export HTTP_PROXY='DIRECT' 

LOCAL_CONFIG_PATH=/etc/parrot
export PARROT_CVMFS_ALIEN_CACHE=/cvmfs-cache/parrot
export MUGQIC_INSTALL_HOME=/cvmfs/soft.mugqic/CentOS6

usage (){
  echo -e "\nUsage: $0 [-c <PATH>] [-a <PATH>] [-p <PATH> ] [ -d <PATH> ] [-V <X.X.X> ] [ <cmd> ] " 1>&2;
  echo -e "\nOPTION"
  echo -e "\t-a  Set the path of the cache use to store cvmfs data"
  echo -e "\t      default: ${PARROT_CVMFS_ALIEN_CACHE}"
  echo -e "\t-c  Set the path for local cvmfs repo config"
  echo -e "\t      default: ${LOCAL_CONFIG_PATH}"
  echo -e "\t-p  Set the path for the mugqic software stack"
  echo -e "\t      default: ${MUGQIC_INSTALL_HOME}"
  echo -e "\t-d  Set a path to a genpipes repo that can supersedes"
  echo -e "\t      the soft.mugqic repo's version (developer's mode)"
  echo -e "\t-V    Genpipes version (if other then module default)"
  echo -e "\t-e  Execute specific command and exit"
  echo
}


while getopts ":a:d:c:p:" opt; do
  case $opt in
    a)
      echo "Setting parrot alien cache to $OPTARG"
      PARROT_CVMFS_ALIEN_CACHE=${OPTARG}
      ;;
    c)
      echo "Using local cvmfs config path $OPTARG"
      LOCAL_CONFIG_PATH=${OPTARG}
      ;;
    p)
      MUGQIC_INSTALL_HOME=${OPTARG}
      ;;
    V)
      PIPELINE_VERSION=/${OPTARG}
      ;;
    d)
      export GENPIPES_DEV_DIR=/${OPTARG}
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
shift $((OPTIND-1))
# move the execline to a script
if [ $# -gt 0 ] ; then
 echo $#
  function finish {
    rm ${genpipe_script}
  }
  genpipe_script=$(mktemp /tmp/genpipe_script.XXXXXX)
  trap finish EXIT
  chmod 755 ${genpipe_script}
  echo $@ > ${genpipe_script}
fi
  
# copy the compute.canada config locally, this will let the other repo be mounted.
/opt/cctools/bin/parrot_run cp -r /cvmfs/cvmfs-config.computecanada.ca /tmp/. 2>/dev/null

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

# The <default-repositories> option is important when cvmfs repo are 
# already present in the cvmfs directory. Parrot will not try to remount
# the fs in that case.
export PARROT_CVMFS_REPO="<default-repositories> \
	${CVMFS_CONFIG_CC} \
	soft.mugqic:url=$soft_url,pubkey=$KEY_PATH/soft.mugqic.pub,try_local_filesystem \
	ref.mugqic:url=$ref_url,pubkey=$KEY_PATH/ref.mugqic.pub,try_local_filesystem"


# load cvmfs 
if [  ${genpipe_script}  ]; then
  /opt/cctools/bin/parrot_run  bash --rcfile /usr/local/etc/genpiperc -ic ${genpipe_script}
else 
  /opt/cctools/bin/parrot_run  bash --rcfile /usr/local/etc/genpiperc 
fi

