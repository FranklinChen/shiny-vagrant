#!/bin/sh
PATH=/usr/local/bin:/usr/local/sbin:~/bin:/usr/bin:/bin:/usr/sbin:/sbin
mv workfiles/*.rds ../storage/
mv workfiles/*.csv ../storage/
mv workfiles/*.txt ../storage/
mv workfiles/actualcsv/*.csv ../storage/actualcsv/
mv workfiles/ngramsdir/*.rds ../storage/ngrams
