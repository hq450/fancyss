
	#!/bin/bash

	cd c:/tangj15/code
	pwd

	if [ -n "$1" ]; then
		msg=$1
	else
		read  -p 'Commit message > ' msg
		if [ -z "$msg" ]; then
			msg="Auto synchronizing"
			echo "Committing as '$msg'"
		fi
	fi

	find . -maxdepth 2 -iname "syncing.sh" -exec chmod +x {} \; -exec {} '$msg'  \;

