#!/bin/sh
PATH=/usr/local/bin:/usr/local/sbin:~/bin:/usr/bin:/bin:/usr/sbin:/sbin
cp workfiles/*.rds /Users/franklin/macwshiny/storage/
cp workfiles/*.csv /Users/franklin/macwshiny/storage
mv workfiles/actualcsv/*.csv /Users/franklin/macwshiny/storage/actualcsv/
mv workfiles/ngramsdir/*.rds /Users/franklin/macwshiny/storage/ngrams
