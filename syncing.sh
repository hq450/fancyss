#!/bin/bash

cd "$(dirname "$0")"
echo
pwd
if [ -n "$1" ]; then
	msg=$1
else
	read  -p 'Commit message > ' msg
	if [ -z "$msg" ]; then
		msg="Auto synchronizing"		
	fi
fi
echo "Committing as '$msg'"
git pull
git add *
git add -A
git commit -m "$msg"
git push -u

