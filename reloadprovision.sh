#!/bin/sh
PATH=/usr/local/bin:/usr/local/sbin:~/bin:/usr/bin:/bin:/usr/sbin:/sbin
export USER=macw
echo "${0%/*}"
cd "${0%/*}"

#source sock.sh
/usr/bin/git stash
/usr/bin/git pull origin master

if [[ $1 = "skip" ]]; then
  echo "skip reload provision"
else
  vagrant reload
  vagrant provision
fi

