#!/bin/sh
PATH=/usr/local/bin:/usr/local/sbin:~/bin:/usr/bin:/bin:/usr/sbin:/sbin
mkdir workfiles
cd workfiles
if [ ! -d "data-xml" ]; then
  wget -c -e robots=off -r -l inf --no-remove-listing -nH --no-parent -R 'index.html*'  http://childes.talkbank.org/data-xml/
  find data-xml -name "*.zip" | while read filename; do unzip -o -d "`dirname "$filename"`" "$filename"; done;
  find data-xml -name "*.zip" | xargs rm 
  /bin/ls -lhad data-xml | awk '{print $6,$7,$8,$5,$9}' > ../storage/timestamp.txt
fi
