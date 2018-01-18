#!/bin/sh
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin
cd workfiles
#nohup Rscript ../convertRDS2CSV.R > out2
rm -f bigspa.csv 
nohup python3 ../createbigspa.py > out3
echo "done make spa" >> out3
/bin/ls -lha bigspa.csv | awk '{print $6,$7,$8,$5}' > ../storage/timestamp.txt
