#!/bin/sh

extras=$HOME/shiny-vagrant-extras

for i in csvcorpora ngrams
do
	rsync -avz --delete $extras/$i/ ./storage/$i
done
