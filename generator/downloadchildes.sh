rm -rf workfiles
./getCorp.sh
./makeCorp.sh
./makeSPA.sh
/bin/ls -lha workfiles/bigspa.csv | awk '{print $6,$7,$8,$5}' > workfiles/timestamp.txt 
#uploadGoogle.sh

