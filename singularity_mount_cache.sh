#! /bin/bash
 args=$@
if [ $# -lt 1 ]; then
   args=/home/poq/container_cvmfs/cccg_genpipes-0.5.img
fi


singularity run -B /media/caches/:/cvmfs-cache/ $args
