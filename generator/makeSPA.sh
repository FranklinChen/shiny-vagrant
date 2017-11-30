cd workfiles
mkdir actualcsv
nice -n 19 Rscript ../convertRDS2CSV.R > out2
rm -f bigspa.csv 
nice -n 19 python3 ../createbigspa.py > out3
 

