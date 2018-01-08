#!/bin/sh
PATH=/usr/local/bin:/usr/local/sbin:~/bin:/usr/bin:/bin:/usr/sbin:/sbin
cp workfiles/*.rds storage/
cp workfiles/*.csv storage
mv workfiles/actualcsv/*.csv storage/actualcsv/
mv workfiles/ngramdir/*.rds storage/ngrams/
