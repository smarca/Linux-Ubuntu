#!/bin/sh

#Instalacao
mkdir -p /srv/www/default/webmail/
pear config-create /srv/www/default/webmail/ /srv/www/default/webmail/pear.conf
pear -c /srv/www/default/webmail/pear.conf install --alldeps pear
/srv/www/default/webmail/pear/pear -c /srv/www/default/webmail/pear.conf channel-discover pear.horde.org
/srv/www/default/webmail/pear/pear -c /srv/www/default/webmail/pear.conf channel-discover pecl.php.net
/srv/www/default/webmail/pear/pear -c /srv/www/default/webmail/pear.conf config-get bin_dir
/srv/www/default/webmail/pear/pear -c /srv/www/default/webmail/pear.conf config-get preferred_state
/srv/www/default/webmail/pear/pear -c /srv/www/default/webmail/pear.conf config-set auto_discover 1
/srv/www/default/webmail/pear/pear -c /srv/www/default/webmail/pear.conf install --alldeps Services_Weather
/srv/www/default/webmail/pear/pear -c /srv/www/default/webmail/pear.conf install --alldeps horde/horde_role
/srv/www/default/webmail/pear/pear -c /srv/www/default/webmail/pear.conf run-scripts horde/Horde_Role
/srv/www/default/webmail/pear/pear -c /srv/www/default/webmail/pear.conf install --alldeps --nobuild horde/horde
/srv/www/default/webmail/pear/pear -c /srv/www/default/webmail/pear.conf install --alldeps horde/imp
/srv/www/default/webmail/pear/pear -c /srv/www/default/webmail/pear.conf install --alldeps horde/turba
/srv/www/default/webmail/pear/pear -c /srv/www/default/webmail/pear.conf install --alldeps horde/nag
/srv/www/default/webmail/pear/pear -c /srv/www/default/webmail/pear.conf install --alldeps horde/mnemo
/srv/www/default/webmail/pear/pear -c /srv/www/default/webmail/pear.conf install --alldeps horde/kronolith
/srv/www/default/webmail/pear/pear -c /srv/www/default/webmail/pear.conf install --alldeps horde/passwd
/srv/www/default/webmail/pear/pear -c /srv/www/default/webmail/pear.conf install --alldeps horde/gollem
/srv/www/default/webmail/pear/pear -c /srv/www/default/webmail/pear.conf install --force --alldeps --force pear/Date_Holidays_Brazil
#/srv/www/default/webmail/pear/pear -c /srv/www/default/webmail/pear.conf install --alldeps horde/webmail
/srv/www/default/webmail/pear/pear -c /srv/www/default/webmail/pear.conf config-show
/srv/www/default/webmail/pear/pear -c /srv/www/default/webmail/pear.conf list -c horde

#UPGRADE
/srv/www/default/webmail/pear/pear -c /srv/www/default/webmail/pear.conf upgrade -Z --alldeps
/srv/www/default/webmail/pear/pear -c /srv/www/default/webmail/pear.conf upgrade-all -Z 
#rm -f /srv/www/default/webmail/pear/download/*

