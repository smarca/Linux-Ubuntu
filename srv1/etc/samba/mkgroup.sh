# http://us3.samba.org/samba/docs/man/Samba-HOWTO-Collection/groupmapping.html#id361112

#http://www.dicas-l.com.br/dicas-l/20060512.php
#net rpc join member -U root
#net rpc join -S gdh -w dominio -U root
#net rpc join -S ipservidor -w dominio
# net rpc testjoin

/etc/init.d/samba stop && sudo /etc/init.d/winbind stop
rm -rf /var/cache/samba/*
rm -rf /var/lib/samba/*
/etc/init.d/samba start && sudo /etc/init.d/winbind start

net sam createbuiltingroup "Administrators"
net sam createbuiltingroup "Guests"
net sam createbuiltingroup "Users"
net sam createbuiltingroup "Power Users"
net sam createbuiltingroup "Account Operators"
net sam createbuiltingroup "Print Operators"
net sam createbuiltingroup "Backup Operators"
net sam createlocalgroup "Domain Admins"
net sam createlocalgroup "Domain Users"
net sam createlocalgroup "Domain Guests"
net sam createlocalgroup "Domain Computers"
net sam createlocalgroup "Domain Controllers"
net sam createlocalgroup "Domain Certificate Admins"
net sam createlocalgroup "Domain Schema Admins"
net sam createlocalgroup "Domain Enterprise Admins"
net sam createlocalgroup "Domain Policy Admins"
net groupmap list verbose
#net groupmap memberships



#net groupmap list
#net groupmap cleanup
#net groupmap add rid=512 unixgroup=nt-dom-admin type=domain ntgroup="Admins do dominio"
#net groupmap add rid=513 unixgroup=nt-dom-users type=domain ntgroup="Usuarios do dominio"
#net groupmap add rid=514 unixgroup=nt-dom-guests type=domain ntgroup="Convidados do dominio"
#net groupmap add rid=515 unixgroup=nt-dom-machines type=domain ntgroup="Computadores de dominio"
#net groupmap add sid=S-1-5-32-544 unixgroup=nt-loc-admin type=builtin ntgroup="Administradores"
#net groupmap add sid=S-1-5-32-545 unixgroup=nt-loc-users type=builtin ntgroup="Usuarios"
#net groupmap add sid=S-1-5-32-546 unixgroup=nt-loc-guests type=builtin ntgroup="Convidados"
#net groupmap add sid=S-1-5-32-247 unixgroup=nt-loc-pwusers type=builtin ntgroup="Usuarios avancados"
#net groupmap add sid=S-1-5-32-248 unixgroup=nt-loc-opcopy type=builtin ntgroup="Operadores de Usuarios"
#net groupmap add sid=S-1-5-32-249 unixgroup=nt-loc-opshare type=builtin ntgroup="Operadores de compartilhamentos"
#net groupmap add sid=S-1-5-32-550 unixgroup=nt-loc-opprint type=builtin ntgroup="Operadores de impressao"
#net groupmap add sid=S-1-5-32-551 unixgroup=nt-loc-opbackup type=builtin ntgroup="Operadores de backup"

# smbclient -U marca -L  //srv
# testparm
# net groupmap list verbose
# net sam createbuiltingroup Administrators -w MYDOMAIN
# wbinfo -t
# wbinfo -u
# wbinfo -g
# pdbedit -L
# net groupmap list
# mount -t smbfs -o username=metropol,password=metropol //10.0.0.2/bkup a

# net groupmap list
# net groupmap cleanup
# net groupmap add ntgroup="Domain Adminis" unixgroup=admin rid=512 type=d
# net groupmap add ntgroup="Domain Users" unixgroup=users rid=513 type=d
# net groupmap add ntgroup="Domain Guests" unixgroup=nogroup rid=514 type=d
# net groupmap add ntgroup="Builtin Admins" unixgroup=admin rid=544 type=b
# net groupmap add ntgroup="Builtin Users" unixgroup=users rid=545 type=b
# net groupmap add ntgroup="Builtin Guests" unixgroup=nogroup rid=546 type=b




