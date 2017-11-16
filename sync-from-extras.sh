#!/bin/sh

extras=$HOME/shiny-vagrant-extras

for i in csvcorpora ngrams actualcsv
do
	rsync -avz --delete $extras/$i/ ./storage/$i
done
