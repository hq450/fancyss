#!/bin/bash

cd "$(dirname "$0")"
pwd
if [ -n "$1" ]; then
    msg="Synchronizing"
else
    read  -p 'Commit message > ' msg
    if [ -z "$msg" ]; then
        msg="Auto synchronizing"
        echo "Committing as '$msg'"
    fi
fi
git pull
git add *
git add -A
git commit -m "$msg"
git push -u