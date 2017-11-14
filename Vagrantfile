# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "ubuntu/artful64"

  # Using 'vagrant plugin install vagrant-disksize'
  config.disksize.size = '50GB'

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.provision "shell", inline: <<-SHELL
    resize2fs /dev/sda1
    apt-get update
    apt-get install -y apache2 r-base r-cran-rcpp r-cran-httpuv r-cran-htmltools r-cran-sourcetools r-cran-digest r-cran-stringr r-cran-dplyr r-cran-ggplot2 r-cran-rcurl r-cran-xml2 libpoppler-cpp-dev poppler-utils pandoc libcurl4-openssl-dev libxml2-dev libssl-dev emacs gdebi-core
    SHINY=shiny-server-1.5.3.838-amd64.deb
    wget -N https://download3.rstudio.org/ubuntu-12.04/x86_64/$SHINY
    gdebi --non-interactive $SHINY

    R -e "install.packages('shiny', repos='https://cran.rstudio.com/')"
    #R -e "install.packages('RCurl',repos='https://cran.ma.imperial.ac.uk/')" 
    R -e "install.packages('rmarkdown', repos='http://cran.rstudio.com/')"
    R -e "install.packages('DT',repos='https://cran.rstudio.com/')"
    #R -e "install.packages('xml2',repos='https://cran.ma.imperial.ac.uk/')" 
    #R -e "install.packages('dplyr',repos='https://cran.ma.imperial.ac.uk/')" 
    R -e "install.packages('devtools',repos='https://cran.ma.imperial.ac.uk/')" 
    R -e "devtools::install_github('rstudio/DT@feature/editor')"
    R -e "install.packages('shinycssloaders',repos='https://cran.ma.imperial.ac.uk/')"
  SHELL
end
