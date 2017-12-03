# Generating files for programs

## Manual 

The program takes about three days to finish

```
$ cd ~/shiny-vagrant/generator
$ nohup /bin/bash downloadchildes.sh &
```
## Automatic

Program is run once a month

```
$ crontab -l   # to list present settings
$ env EDITOR=nano crontab -e    # to edit
```
