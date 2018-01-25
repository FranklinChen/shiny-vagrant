#!/bin/sh
PATH=/usr/local/bin:/usr/local/sbin:~/bin:/usr/bin:/bin:/usr/sbin:/sbin
export USER=macw
echo "${0%/*}"
cd "${0%/*}"

keychain /Users/macw/.ssh/id_rsa
source /Users/macw/.keychain/GANDALF.TALKBANK.ORG-sh
/usr/bin/git stash
/usr/bin/git pull origin master

if [[ $1 = "skip" ]]; then
  echo "skip reload provision"
else
  vagrant reload
  vagrant provision
fi

