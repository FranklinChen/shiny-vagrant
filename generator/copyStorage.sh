#!/bin/sh
PATH=/usr/local/bin:/usr/local/sbin:~/bin:/usr/bin:/bin:/usr/sbin:/sbin
cp workfiles/*.rds storage/
cp workfiles/*.csv storage
mv workfiles/actualcsv/*.csv storage/actualcsv/
mv workfiles/ngramdir/*.rds storage/ngrams/
ls -la storage/*/*UK_Thomas* > storagesum
du -sh storage/* >> storagesum
#cat storagesum | mail -s childesgen chang.franklin@gmail.com 
#rm -rf workfiles

