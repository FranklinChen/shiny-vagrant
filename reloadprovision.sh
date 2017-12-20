#!/bin/sh
PATH=/usr/local/bin:/usr/local/sbin:~/bin:/usr/bin:/bin:/usr/sbin:/sbin
cd /Users/macw/shiny-vagrant/
chmod -R g+rw *
git pull
vagrant reload
vagrant provision
