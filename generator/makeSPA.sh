#!/bin/sh
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin:/Applications/VMware Fusion.app/Contents/Public
cd workfiles
mkdir actualcsv
nohup Rscript ../convertRDS2CSV.R > out2
rm -f bigspa.csv 
nohup python3 ../createbigspa.py > out3
