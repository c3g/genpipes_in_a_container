#! /bin/bash

args=$@
if [ $# -lt 1 ]; then
  args=c3genomics/genpipes:alpha
fi


docker run --rm   --device /dev/fuse --cap-add SYS_ADMIN  -v /tmp:/tmp -it -w $PWD -v $HOME:$HOME  -v $HOME/cvmfs_caches/:/cvmfs-cache/ $args
