#!/bin/sh
PATH=/usr/local/bin:/usr/local/sbin:~/bin:/usr/bin:/bin:/usr/sbin:/sbin

echo "${0%/*}"
cd "${0%/*}"
git pull
if [ $1 = "skip" ]; then
  echo "skip reload provision"
else
  vagrant reload
  vagrant provision
fi
