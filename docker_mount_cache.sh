#! /bin/bash
docker run --privileged -v /tmp:/tmp --network host -it -w $PWD -v $HOME:$HOME --user $UID:$GROUPS -v /etc/passwd:/etc/passwd  -v /media/caches/:/cvmfs-cache/ poquirion/genpipes
