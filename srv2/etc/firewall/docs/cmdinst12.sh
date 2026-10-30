#!/bin/bash
exit
#Erro Locales
#perl: warning: Setting locale failed.
#perl: warning: Please check that your locale settings:
#        LANGUAGE = "pt_BR:pt:en",
#        LC_ALL = (unset),
#        LC_PAPER = "pt_BR",
#        LC_ADDRESS = "pt_BR",
#        LC_MONETARY = "pt_BR",
#        LC_NUMERIC = "pt_BR",
#        LC_TELEPHONE = "pt_BR",
#        LC_IDENTIFICATION = "pt_BR",
#        LC_MEASUREMENT = "pt_BR",
#        LC_TIME = "pt_BR",
#        LC_NAME = "pt_BR",
#        LANG = "pt_BR.UTF-8"
#    are supported and installed on your system.
#perl: warning: Falling back to the standard locale ("C").
locale-gen pt_BR.UTF-8 en_US.UTF-8
locale-gen --purge
dpkg-reconfigure locales

resolvconf --disable-updates

#Modulos Perl
apt-get install lib*-perl

#apt-get install lamp-server^ php-pear

lshw -C Network

#Apache
a2enmod xml2enc
a2enmod proxy_html
a2enmod include
a2enmod cgi
a2enmod deflate
a2enmod headers
a2enmod php5
a2enmod proxy
a2enmod proxy_http
a2enmod rewrite
a2enmod usertrack
a2enmod ssl
a2enmod ext_filter
a2enmod expires
a2enmod dbd
a2enmod auth_digest
a2dismod shib2

#Apache bug
ln -s /usr/lib/i386-linux-gnu/libxml2.so.2 /usr/lib/libxml2.so.2

#Mudar numero de montagens para checagem forcada
tune2fs -l /dev/md0
tune2fs -c 30 -i 5m /dev/md0
tune2fs -c 21 -i 6m /dev/sda1
tune2fs -c 22 -i 6m /dev/sdb1

#Smart
smartctl -s on -d ata /dev/sda
smartctl -s on -d ata /dev/sdb
smartctl -i /dev/sda
smartctl -i /dev/sdb

#Modulos Diversos
apt-get install telnetd
apt-get install exim4-daemon-heavy spf-tools-perl swaks
apt-get install conntrack
apt-get install smartmontools
apt-get install fdupes
apt-get install dovecot-mysql
apt-get install dovecot-metadata-plugin
apt-get install rrdtool
apt-get install lm-sensors
apt-get install libgd-tools
apt-get install xinetd
apt-get install ca-certificates
apt-get install sysstat
apt-get install schedtool
apt-get install stunnel
apt-get install imagemagick
apt-get install libspf2-*
apt-get install libmail-spf-perl
apt-get install php5-gd
apt-get install php5-curl
apt-get install php5-xsl
apt-get install php5-geoip
apt-get install libssh2-php
apt-get install php-pear
apt-get install mailutils
apt-get install proftpd
apt-get install unzip
apt-get install zip
apt-get install unrar
apt-get install rar
apt-get install arc 
apt-get install cabextract
apt-get install tofrodos
apt-get install netdiag
apt-get install htop
apt-get install iftop
apt-get install sarg
apt-get install lftp
apt-get install gawk
apt-get install whois
apt-get install linux-igd
apt-get install dos2unix
# apt-get install cyrus-clients-2.4
apt-get install aspell-pt-br imp4 horde3
apt-get install turba2 kronolith2 mnemo2 enscript unrtf gettext xlhtml ppthtml source-highlight wv php-net-imap unrtf libwpd-tools php5-auth-pam
apt-get install sork-passwd-h3 # sork-vacation-h3 sork-forwards-h3 
apt-get install wordpress wordpress-openid wordpress-shibboleth wordpress-xrds-simple
apt-get install fail2ban python-pyinotify
apt-get install iptraf iptraf-ng tshark
apt-get install ethtool 
apt-get install sniffit 
apt-get install attr
apt-get install acl
apt-get remove libpam-smbpass
apt-get remove libapache2-mod-shib2
apt-get remove ufw
apt-get install apache2-utils
apt-get install clamav libclamunrar7
apt-get install shellinabox
apt-get install convmv
apt-get install iperf
apt-get install landscape-common
apt-get install p7zip-full p7zip-rar rar arj zip dtrx
apt-get install php-horde-imp

#Bugs
chown -R dhcpd:dhcpd /var/lib/dhcp
#/etc/paswd -> firebird:x:84:84:Firebird Database Owner:/opt/firebird:/bin/false
#/etc/group -> firebird:x:84:
addgroup bind dhcpd
addgroup dhcpd bind

#Editor
update-alternatives --config editor

#mysqlcheck -c  -u root -p --all-databases

#Fixar dpkg
dpkg --configure -a

update-rc.d rsync defaults
update-rc.d -f smartmontools remove
update-rc.d smartmontools disable
update-rc.d spfd defaults
update-rc.d spfd enable
update-rc.d linux-igd defaults
update-rc.d linux-igd enable
update-rc.d -f memcached remove




#Fixar DHCP
#setfacl -dm u:dhcpd:rwx /var/lib/dhcp
#setfacl -m u:dhcpd:rwx /var/lib/dhcp

#Backups 
#ln -s /etc/rsync/run.bkpprog /etc/cron.daily/bkpprog
#ln -s /etc/rsync/run.rsync1  /etc/cron.hourly/rsync1
#ln -s /etc/rsync/run.bkpsys  /etc/cron.weekly/bkpsys

#Remover mouse desnecessario
update-rc.d -f gpm remove

###############################################################################
# https://help.ubuntu.com/community/LucidUpgrades#AlternateUpgrade
# do-release-upgrade ou /cdrom/cdromupgrade montando a imagem da nova distro em /media/cdrom0
###############################################################################
# apt-get install exim4-daemon-heavy spamc clamav-milter clamav-daemon clamav clamav-freshclam spamassassin libmail-spf-query-perl spfquery dkim-filter 
# dovecot-pop3d dovecot-imapd
#--- Horde
# Habilitar traducao: locale-gen pt_BR
# Instalar pacotes: horde3 imp4 turba2 ou...
#    imp4 php-date php-db php-file php-mail php-services-weather  php-net-smtp php-cache php-soap php-xml-serializer php-net-ftp php-net-dime
#    chora2 enscript gettext libgeoip1 php-net-imap php5-mhash ppthtml source-highlight turba2 webcpp wv xlhtml  
#    aspell ispellaspell-br wbrazilian libpaper-utils uw-mailutils 
#
##>desabilitados ingo1 kronolith2 gollem imapproxy  
# Novo Horde
# apt-get install php5-dev
# aptitude install build-essential mysql-server php5 php5-gd snmp libsnmp9-dev snmpd
#------




#build-essential 
#mysql-server 
#php5 php5-gd 
#snmp libsnmp9-dev snmpd
#ajaxterm

#exim4-doc-info
#pacotes instalados
#mc
#links
#sysvconfig
#exim4-base
#exim4
#acl
#sysv-rc-conf
#ntp
#gdb
#anacron
#dhcp3-server
#
#courier-imap
#courier-authlib-mysql
#phpmyadmin

#Inicializar no init.d
#network
#apparmor


#Compilar pacotes
#build-essential automake checkinstall pbuilder
#Para compilar
#pbuilder create
#pbuilder --update
#pbuilder --build foo_version.dsc


                          
#Check Tabelas
#mysql_upgrade -u marca -p --force
#mysqlcheck -u marca -p  --all-databases --force --extended --auto-repair --check-upgrade --optimize --repair
#Adicionar DHCPD no bind
#adduser dhcpd bind

#PHP GD
#php -m

#Adicionar exim no grupo mail
#addgroup Debian-exim mail

#comandos uteis
#update-pciids
#lspci
#ethtool eth0
#cat /etc/udev/rules.d/70-persistent-net.rules

#Criar e outros comandos
#mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sdc /dev/sde
#mdadm -Es | grep md0  >>/etc/mdadm.conf.new
#mdadm --detail /dev/md0
#mdadm --create /dev/md0 --level=mirror --force --raid-devices=2 /dev/sdc --spare-devices=1 /dev/sdb
#mdadm --assamble --uuid=/dev/md0 --update resync
#mdadm /dev/md0 --add /dev/sdb
##Re Add Hotswap
#mdadm /dev/mdx --re-add /dev/sdax
#mdadm /dev/mdx -a /dev/sdax
#mdadm --grow /dev/mdx --raid-devices=3
#mdadm -I /dev/sdax
#Retirar disco
# mdadm --fail /dev/md0 /dev/sdc2
# mdadm --remove /dev/md0 /dev/sdc2
# mdadm --zero-superblock /dev/sdc2
# mdadm --grow /dev/md0 --raid-devices=2
#apt-get install mdadm 
#mdadm --assemble --scan ; ls /dev/md* 
#mdadm --assemble /dev/md0 /dev/sda1 /dev/sdb1
#Ver uid para mdadm.conf
#mdadm --examine /dev/sda3


##############
#Restaurar arquivo configuracao novo
#apt-get -o Dpkg::Options::="--force-confask" install --reinstall mysql-server-5.7
#apt-get -o Dpkg::Options::="--force-confmiss" install --reinstall mysql-server-5.7
#dpkg -S /etc/mysql/mysql.conf.d
#############