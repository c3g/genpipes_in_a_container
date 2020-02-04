#! /bin/bash
 args=$@
if [ $# -lt 1 ]; then
   args=../c3genomics_genpipes-beta.img
fi


singularity run -B /media/caches/:/cvmfs-cache/ $args
