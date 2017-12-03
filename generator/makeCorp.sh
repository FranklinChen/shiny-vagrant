#!/bin/sh
PATH=/usr/local/bin:/usr/local/sbin:~/bin:/usr/bin:/bin:/usr/sbin:/sbin
cd workfiles
nohup nice -n 19 Rscript ../createCorpora18.R 0 > out 
