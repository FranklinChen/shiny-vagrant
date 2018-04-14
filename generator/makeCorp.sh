#!/bin/sh
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin
cd workfiles
nohup nice -n 19 Rscript ../createCorpora18.R 1 > out 
nohup nice -n 19 Rscript ../createCorpora18.R 1 >> out 
nohup nice -n 19 Rscript ../createCorpora18.R 2 > out1 
nohup nice -n 19 Rscript ../createCorpora18.R 2 >> out1
nohup nice -n 19 Rscript ../createCorpora18.R 0 >> out1 
#nohup nice -n 19 Rscript ../createCorpora18.R 2 > out1 
#nohup nice -n 19 Rscript ../createCorpora18.R 3 >> out1 
#nohup nice -n 19 Rscript ../createCorpora18.R 4 >> out1 
#nohup nice -n 19 Rscript ../createCorpora18.R 5 >> out1 
#nohup nice -n 19 Rscript ../createCorpora18.R 6 >> out1 
#nohup nice -n 19 Rscript ../createCorpora18.R 7 >> out1 
#nohup nice -n 19 Rscript ../createCorpora18.R 8 >> out1 
/bin/ls -lhad csvfolderMake | awk '{print $6,$7,$8,$5,$9}' > ../storage/timestamp.txt
