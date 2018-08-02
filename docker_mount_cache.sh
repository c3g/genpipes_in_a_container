#! /bin/bash

args=$@
if [ $# -lt 1 ]; then
  args=cccg/genpipes
fi

docker run --privileged -v /tmp:/tmp --network host -it -w $PWD -v $HOME:$HOME --user $UID:$GROUPS -v /etc/group:/etc/group  -v /etc/passwd:/etc/passwd  -v /media/caches/:/cvmfs-cache/ $args
