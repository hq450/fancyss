#!/bin/sh

MODULE=koolss
VERSION=`cat koolss/ss/version`
TITLE=科学上网插件
DESCRIPTION="轻松科学上网~"
HOME_URL=Module_koolss.asp
CHANGELOG="支持2.30"

# Check and include base
DIR="$( cd "$( dirname "$BASH_SOURCE[0]" )" && pwd )"

# now include build_base.sh
. $DIR/../softcenter/build_base.sh

# change to module directory
cd $DIR

# do something here
do_build_result

sh backup.sh $MODULE



