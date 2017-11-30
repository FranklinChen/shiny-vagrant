cd /home/chang/big/rscripts/corpus/childes/workfiles
echo updating storage
cp *.rds ../storage/
cp *.csv ../storage/
cp csvfolderMake/*.rds ../storage/csvcorpora/
cp ngramdir/*.rds ../storage/ngrams/
echo updating google
gsutil -m cp -r ../storage/* gs://childesmedia/
/bin/ls -lha * | awk '{print $6,$7,$8,$5,$9}' | mail -s makecorp -r chang.franklin@gmail.com chang.franklin@gmail.com
