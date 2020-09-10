# Generating files for programs

## Manual 

The program takes about three days to finish

```
$ cd ~/shiny-vagrant/generator
$ nohup /bin/bash downloadchildes.sh &
```
## Automatic

To run it, you need to edit your crontab and put the above command in there.

```
$ crontab -l   # to list present settings
$ env EDITOR=nano crontab -e    # to edit
```

Put this command in your crontab to update monthly on the first day of the month at 2:03 am. 
```
$ 3 2 1 * * /bin/bash downloadchildes.sh
```
