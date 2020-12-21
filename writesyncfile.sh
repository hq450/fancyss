#!/bin/bash


cd c:/tangj15/code
pwd
for path in c:/tangj15/code/*
do
	if test -d $path
    then
	echo ""
	echo "${path}/sync all.sh"
	cat <<'EOF'>"$path/sync all.sh"
#!/bin/bash

cd c:/tangj15/code
pwd

if [ -n "$1" ]; then
	msg=$1
else
	read  -p 'Commit message > ' msg
	if [ -z "$msg" ]; then
		msg="Batch synchronizing"
		echo "Committing as '$msg'"
	fi
fi

find . -maxdepth 2 -iname "syncing.sh" -exec chmod +x {} \; -exec {} "$msg"  \;

EOF


	echo "${path}/sync all.sh"

	cat <<'EOF' >"${path}/syncing.sh"
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

EOF
 
    fi
	
	cp "$0" "$path"
done
 
 
