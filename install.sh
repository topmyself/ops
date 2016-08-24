#!/bin/bash

install_nagios(){

    #install package
    tar xvf nagios-4.1.1.tar.gz
    cd nagios-4.1.1
    ./configure --with-nagios-group=nagios --with-command-group=nagcmd
    make all
    make install
    make install-commandmode
    make install-init
    make install-config
    /usr/bin/install -c -m 644 sample-config/httpd.conf /etc/apache2/sites-available/nagios.conf
    rm -r nagios-4.1.1
}

install_nagios_plugin(){
    tar xvf nagios-plugins-2.1.1.tar.gz
    pushd nagios-plugins-2.1.1
    /configure --with-nagios-user=nagios --with-nagios-group=nagios --with-openssl
    make
    make install
    popd
    rm -r nagios-plugins-2.1.1
}

install_nrpe(){
   tar xvf nrpe-2.15.tar.gz 
   pushd nrpe-2.15
   ./configure --enable-command-args --with-nagios-user=nagios --with-nagios-group=nagios --with-ssl=/usr/bin/openssl --with-ssl-lib=/usr/lib/x86_64-linux-gnu
   make all
   make install
   make install-xinetd
   make install-daemon-config
   popd 
   rm -r nrpe-2.15
   /usr/local/nagios/bin/nrpe -c /usr/local/nagios/etc/nrpe.cfg -d
}

install_postfix(){
    apt-get install postfix:w
}

install_server(){
    pushd package
    install_nagios
    install_nagios_plugin
    install_nrpe
    popd
}

install_client(){
    pushd package
    install_nagios_plugin
    install_nrpe
    popd

    #copy configure
    cp conf/nrpe.cfg /usr/local/nagios/etc -f
    chown nagios:nagios /usr/local/nagios/etc/nrpe.cfg
    
    #set xinetd service
    cp conf/nrpe /etc/xinetd.d
    service xinetd restart

    echo "*******************notice, this is very import***********************
          df -h
	  and according to dev name ,modify the /usr/local/nagios/etc/nrpe.cfg
          check_disk .... -p /dev/sda
          
          after you modify the configuration, restart the nrpe daemon process 
          *********************************************************************"
}

if [  `id -u` != 0 ]
then
    echo "you must run this by root"
fi

if [ $# == 0 ];then
    echo "Usage : $0 {server | client }"
fi

#1. install dep
apt-get install build-essential libgd2-xpm-dev openssl libssl-dev xinetd apache2-utils unzip

#2. user and group
useradd nagios
groupadd nagcmd
usermod -a -G nagcmd nagios
usermod -a -G nagcmd www-data

#3. install server or install client
if [ $1 == 'server' ];then
    echo "install server"
    install_server
elif [ $1 == 'client' ];then
    echo "install client"
    install_client
fi


exit

a2enmod rewrite
a2enmod cgi

#copy passwd
cp htpasswd.users /usr/local/nagios/etc/
ln -s /etc/apache2/sites-available/nagios.conf /etc/apache2/sites-enabled/
ln -s /etc/init.d/nagios /etc/rcS.d/S99nagios


service nagios start
service apache2 restart
service nagios-nrpe-server restart

get_remote_nagios(){
    #get nagios, first find it local, and then remote
    
    find . -name "nagios-4*.tar.gz" | if read s;
    then
        echo "find nagios package $s"
    else 
        echo "not find nagios"
        curl -L -O https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.1.1.tar.gz
    fi
}

get_remote_nagiosplugin(){
    find . -name "nagios-plugins-2*.tar.gz" | if read s;
    then
        stat -s $s
        if [ st_size != 0 ]
        then
            echo "find nagios-plugin package $s"
        else
            curl -L -O http://nagios-plugins.org/download/nagios-plugins-2.1.1.tar.gz
        fi
    else 
        echo "not find nagios-plugin"
        curl -L -O http://nagios-plugins.org/download/nagios-plugins-2.1.1.tar.gz
    fi
}

get_remote_nrpe(){
    #get nrpe
    find . -name "nrpe-2*.tar.gz" | if read s;
    then
        echo "find nrpe package $s"
    else 
        echo "not find nrpe"
        curl -L -O http://downloads.sourceforge.net/project/nagios/nrpe-2.x/nrpe-2.15/nrpe-2.15.tar.gz
    fi
}
