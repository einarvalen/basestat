#!/bin/bash
docker run -itv `pwd`/:/media/basestat -w /media/basestat centos6-dmd
EXITED=$(docker ps -q -f status=exited)
DANGLING=$(docker images -q -f "dangling=true")
if [ -n "$EXITED" ]; then
    docker rm $EXITED
fi
if [ -n "$DANGLING" ]; then
    docker rmi $DANGLING
fi


