#!/bin/sh
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin:/Applications/VMware Fusion.app/Contents/Public
cd workfiles
nohup nice -n 19 Rscript ../createCorpora18.R 0 > out 
