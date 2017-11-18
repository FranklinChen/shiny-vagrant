#!/bin/sh

extras=$HOME/shiny-vagrant-extras

for i in csvcorpora ngrams actualcsv
do
	rm -f ./storage/$i
	ln -s $extras/$i/ ./storage/$i
#	rsync -avz --delete $extras/$i/ ./storage/$i
done
