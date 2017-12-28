#!/bin/sh
PATH=/usr/local/bin:/usr/local/sbin:~/bin:/usr/bin:/bin:/usr/sbin:/sbin
echo "${0%/*}"
cd "${0%/*}"
git pull
vagrant reload
vagrant provision
