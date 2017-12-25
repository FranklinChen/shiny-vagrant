#!/bin/sh
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin:/Applications/VMware Fusion.app/Contents/Public
cd /Users/franklin/shiny-vagrant/generator/
rm -rf workfiles
/bin/bash getCorp.sh
/bin/ls -lhad workfiles/data-xml | awk '{print $6,$7,$8,$5,$9}' > /Users/franklin/macwshiny/storage/timestamp.txt
/bin/bash makeCorp.sh
/bin/ls -lhad workfiles/csvfolderMake | awk '{print $6,$7,$8,$5,$9}' > /Users/franklin/macwshiny/storage/timestamp.txt
/bin/bash makeSPA.sh
/bin/ls -lha workfiles/bigspa.csv | awk '{print $6,$7,$8,$5}' > /Users/franklin/macwshiny/storage/timestamp.txt
/bin/bash copyStorage.sh
/bin/ls -lha workfiles | awk '{print $6,$7,$8,$5,$9}' | mail -s childesgen chang.franklin@gmail.com 
