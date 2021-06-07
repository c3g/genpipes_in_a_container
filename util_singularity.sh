#! /bin/bash
 args=$@
if [ $# -lt 1 ]; then
   args=../genpipes_alpha.sif
fi


singularity run  -S /var/run/cvmfs -B ~/cvmfs_cache:/cvmfs-cache --fusemount "container:cvmfs2 cvmfs-config.computecanada.ca /cvmfs/cvmfs-config.computecanada.ca"    --fusemount "container:cvmfs2 soft.mugqic /cvmfs/soft.mugqic"   --fusemount "container:cvmfs2 ref.mugqic /cvmfs/ref.mugqic" ${args}
