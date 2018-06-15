#!/bin/sh
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin
echo "${0%/*}"
cd "${0%/*}"
rm -rf workfiles
/bin/bash getCorp.sh
/bin/bash makeCorp.sh
/bin/bash makeSPA.sh
/bin/bash copyStorage.sh
/bin/ls -lha workfiles | awk '{print $6,$7,$8,$5,$9}' | mail -s childesgen chang.franklin@gmail.com 
rm -rf workfiles
