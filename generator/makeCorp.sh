#!/bin/sh
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin:/Library/Frameworks/R.framework/Resources/bin
cd workfiles
nice -n 19 Rscript ../createCorpora18.R 1 > out 
nice -n 19 Rscript ../createCorpora18.R 2 > out1 
nice -n 19 Rscript ../createCorpora18.R 3 >> out1 
nice -n 19 Rscript ../createCorpora18.R 4 >> out1 
nice -n 19 Rscript ../createCorpora18.R 5 >> out1 
nice -n 19 Rscript ../createCorpora18.R 0 > out1b 
/bin/ls -lhad csvfolderMake | awk '{print $6,$7,$8,$5,$9}' > ../storage/timestamp.txt
