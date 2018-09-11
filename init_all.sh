#!/bin/bash
# This script loads the mugqic stack in on the host via the
# cctools's parrot's cvmfs options
# For more details on cvmfs and the parrot connector got to:
# http://cvmfs.readthedocs.io/en/stable/cpt-configure.html#parrot-connector-to-cernvm-fs
# It also loads the lmod software to load mugqic modules 

export MUGQIC_INSTALL_HOME=/cvmfs/soft.mugqic/CentOS6

usage (){
  echo -e "\nUsage: $0 [-c <PATH>] [-a <PATH>] [-p <PATH> ] [ -d <PATH> ] [-V <X.X.X> ] [ <cmd> ] " 1>&2;
  echo -e "\nOPTION"
#  echo -e "\t-a  Set the path of the cache use to store cvmfs data"
#  echo -e "\t      default: ${PARROT_CVMFS_ALIEN_CACHE}"
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
#      echo "Setting parrot alien cache to $OPTARG"
#      PARROT_CVMFS_ALIEN_CACHE=${OPTARG}
       echo a not support in the current version
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
  


# load cvmfs 
cvmfs2 cvmfs-config.computecanada.ca   /cvmfs/cvmfs-config.computecanada.ca
cvmfs2 soft.mugqic    /cvmfs/soft.mugqic
cvmfs2 ref.mugqic   /cvmfs/ref.mugqic

# load genpipes
if [  ${genpipe_script}  ]; then
   bash --rcfile /usr/local/etc/genpiperc -ic ${genpipe_script}
else 
   bash --rcfile /usr/local/etc/genpiperc 
fi

