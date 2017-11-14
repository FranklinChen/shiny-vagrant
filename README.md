# Shiny on Vagrant for childes

## Installation

I resized the main partition way up to 50 GB in order not to run out of space. It is possible
we don't need anywhere near this amount of space, in which case we can change the setting in the
`Vagrantfile`.

Only 2.6 GB is used after installation of Ubuntu and R packages.

```
$ vagrant plugin install vagrant-disksize
$ vagrant up
```
