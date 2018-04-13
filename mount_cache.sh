#! /bin/bash
docker run --privileged -v /tmp:/tmp  -it -w $PWD -v $HOME:$HOME --user $UID:$GROUPS -v /etc/passwd:/etc/passwd  -v /media/caches/cvmfs/shared:/cvmfs-cache/cache/cvmfs2/shared truite
