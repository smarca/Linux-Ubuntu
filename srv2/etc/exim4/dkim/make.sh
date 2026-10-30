#!/bin/bash

#g=* ; (granularity) - pode ser * para todos os emails ou *-maillist para diversos ou xxx para email unico
#n= nota;
#s=*; Servico. Pode ser s=*; ou s=mail;
#t=y:s; t=y; simboliza teste, t=s; simboliza sem sub dominios, t=y:s; Significa teste sem subdominios

#dkim=discardable; O receptor deve descartar emails nao assinados, dkim=all; O receptor deve escolher se descarta ou nao dominios nao assinados, dkim=unknown; Nem todos sao assinados - bom para testes
POLICE="dkim=discardable" 	#dkim=discardable para maior confiabilidade!

if [ -z "$*" ]; then
    echo -n "Apelido do dominio [Ex: dominio.com.br]:"
    read DOMINIO
else 
    DOMINIO=$*
fi

if [ -f /etc/bind/zones/master/${DOMINIO} ]; then
    #Incrementar numeros seriais
    for file in $(ls /etc/bind/zones/master/${DOMINIO});
    do 
        if [ -f ${file} ]; then
	    OLDF=`egrep  "serial" ${file} | egrep -ho "[0-9]{10}"`
	    if [ "`date +%Y%m%d`" != "`echo ${OLDF} | cut -c1-8`"  ]; then
		NEWF="`date +%Y%m%d`00"
	    else
		NEWF=$(($OLDF + 1))		
	    fi
	    sed -i "s/$OLDF.*serial/$NEWF ; serial/g" ${file}
	    echo "fixed $file - OLD: ${OLDF} NEW: ${NEWF}" 
    	    if [ -f ${file}.int ]; then
		OLDFI=`egrep  "serial" ${file}.int | egrep -ho "[0-9]{10}"`
		sed -i "s/$OLDFI.*serial/$NEWF ; serial/g" ${file}.int
		echo "fixed ${file}.int - OLD: ${OLDFI} NEW: ${NEWF}" 
	    fi
	fi
    done

    SELECTOR=dk${NEWF}
    #Gerar nova chave
    openssl genrsa -out /etc/exim4/dkim/${DOMINIO}.${SELECTOR}.private.key 2096
    openssl rsa -in /etc/exim4/dkim/${DOMINIO}.${SELECTOR}.private.key -out /etc/exim4/dkim/${DOMINIO}.${SELECTOR}.public.key -pubout -outform PEM
    # cp /etc/exim4/dkim/${DOMINIO}.${SELECTOR}.private.key /etc/exim4/dkim/${DOMINIO}.cur.private.key ; cp /etc/exim4/dkim/${DOMINIO}.${SELECTOR}.public.key  /etc/exim4/dkim/${DOMINIO}.cur.public.key
    chown root.mail /etc/exim4/dkim/*
    chmod o-rwx /etc/exim4/dkim/*
    echo Chaves criadas para ${DOMINIO} em /etc/exim4/dkim/

    if [ ! -z "`cat /etc/bind/zones/master/${DOMINIO} | grep domainkey`" ]; then
	cat /etc/bind/zones/master/${DOMINIO} | grep -v "._domainkey" > /etc/bind/zones/master/${DOMINIO}.new
	mv -f /etc/bind/zones/master/${DOMINIO}.new /etc/bind/zones/master/${DOMINIO}
    else 
	echo "_domainkey 14400 IN       TXT     \"o=-; r=suporte@${DOMINIO}\"">>/etc/bind/zones/master/${DOMINIO}
    fi
    echo "cur._domainkey 14400 IN       TXT     \"${SELECTOR}\""									>>/etc/bind/zones/master/${DOMINIO}
    echo -n "${SELECTOR}._domainkey 14400 IN TXT (\"v=DKIM1; k=rsa; ${POLICE}; g=*; p=\"" 						>>/etc/bind/zones/master/${DOMINIO}
    cat /etc/exim4/dkim/${DOMINIO}.${SELECTOR}.public.key | grep -v "\-\-\-\-\-" | awk '{ printf ("\"%s\"",$1) }' 			>>/etc/bind/zones/master/${DOMINIO}
    echo ")" 																>>/etc/bind/zones/master/${DOMINIO}
    chown root.bind /etc/bind/zones/master/${DOMINIO} ; chmod 640 /etc/bind/zones/master/${DOMINIO}

    if [ -f /etc/bind/zones/master/${DOMINIO}.int ]; then
	if [ ! -z "`cat /etc/bind/zones/master/${DOMINIO}.int | grep domainkey`" ]; then
	    cat /etc/bind/zones/master/${DOMINIO}.int | grep -v "._domainkey" > /etc/bind/zones/master/${DOMINIO}.int.new
	    mv -f /etc/bind/zones/master/${DOMINIO}.int.new /etc/bind/zones/master/${DOMINIO}.int
	else
	    echo "_domainkey 14400 IN       TXT     \"o=-; r=suporte@${DOMINIO}\"">>/etc/bind/zones/master/${DOMINIO}.int
	fi
        echo "cur._domainkey 14400 IN       TXT     \"${SELECTOR}\""									>>/etc/bind/zones/master/${DOMINIO}.int
	echo -n "${SELECTOR}._domainkey 14400 IN TXT (\"v=DKIM1; k=rsa; ${POLICE}; g=*; p=\"" 						>>/etc/bind/zones/master/${DOMINIO}.int
	cat /etc/exim4/dkim/${DOMINIO}.${SELECTOR}.public.key | grep -v "\-\-\-\-\-" | awk '{ printf ("\"%s\"",$1) }' 			>>/etc/bind/zones/master/${DOMINIO}.int
	echo ")" 															>>/etc/bind/zones/master/${DOMINIO}.int
	chown root.bind /etc/bind/zones/master/${DOMINIO}.int ; chmod 640 /etc/bind/zones/master/${DOMINIO}.int
    fi
    service bind9 restart
    service exim4 reload
    echo Domain ${DOMINIO} foi configurado pelo DKIM.
else
    echo Arquivo /etc/bind/zones/master/${DOMINIO} inexistente!
fi


