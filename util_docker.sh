#! /bin/bash

args=$@
if [ $# -lt 1 ]; then
  args=c3genomics/genpipes
fi

docker run --privileged -v /tmp:/tmp -it -w $PWD -v $HOME:$HOME -v /etc/group:/etc/group  -v /etc/passwd:/etc/passwd  -v /media/caches/:/cvmfs-cache/ $args
