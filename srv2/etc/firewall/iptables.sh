#!/bin/bash

### BEGIN INIT INFO
# Provides:        firewall
# Required-Start:  $network $syslog $local_fs $named $squid $remote_fs $time
# Required-Stop:   $network $syslog $local_fs $named $squid
# Should-Start:    $named
# Default-Start:   2 3 4 5
# Default-Stop:    0 1 6
# Short-Description: Start Firewall
### END INIT INFO

###########################################################################
#     Feito por Silmar A. Marca      smarca@gmail.com                     #
###########################################################################
#  *  A remocao destas linhas implica na nao observacao da licenca GNU *  #
#  *  Informe o autor sobre falhas ou incremento de funcoes            *  #
#  *  Respeite a propriedade intelectual, http://www.gnu.org/          *  #
###########################################################################
#http://www.ipaddresslocation.org/ip_ranges/get_ranges.php
#http://conntrack-tools.netfilter.org/conntrack.html
#conntrack -E -o timestamp --event-mask NEW
#hdparm -I /dev/sda
#sdparm --set=WCE /dev/sda
#ethtool eth0

DATAVER="07/11/2017-A"
VERSAO="Firewall -> (smarca@gmail.com)  [60G[[1;33m$DATAVER[0;39m]"
# http://www.lartc.org/

##############################################################################
# Funcao que efetua testes basicos, verificando incompatibilidade e abortando 
testes_basicos () {
   . /etc/firewall/defs.inc
   . /lib/lsb/init-functions

  # if [ ! -z "`$IPTABLES -L -n 2>&1 | $EGREP -E "your kernel needs to be upgraded"`" -o ! -f $IPTABLES ]; then
  if [ ! -f $IPTABLES -a "$IPTABLES" != "echo" ]; then
    log_failure_msg "Testando compatibilidade com IPTables" 
    exit 1
  fi
  if [ ! -f $TC ]; then
    log_failure_msg "Testando compatibilidade com Trafic Control" 
    exit 1
  fi
  if [ ! -f $PIP ]; then
    log_failure_msg "Testando compatibilidade com IP Link" 
    exit 1
  fi
  . "$D_FW"funcoes.inc
}
#############################################################################
#Captura variaveis globais
variaveis_basicas () {
    #Associar Mascaramento
    DEV_ADM=`grfile_params $F_INTERF | $EGREP -E "^(rtr_A)" | $GAWK '{ print $2 }' | $UNIQ`
    DEV_CLI=`grfile_params $F_INTERF | $EGREP -E "^(rtr_C)" | $GAWK '{ print $2 }' | $UNIQ`
    DEV_SRV=`grfile_params $F_INTERF | $EGREP -E "^(rtr_S)" | $GAWK '{ print $2 }' | $UNIQ`
    DEV_EXT=`grfile_params $F_INTERF | $EGREP -E "^(rtr_E)" | $GAWK '{ print $3 }' | $UNIQ`
    DEV_MSQSRV=`grfile_params $F_INTERF | $EGREP -E "^(rtr_E)" | $GAWK '{ print $4 }' | $UNIQ`
    DEV_MAC=`grfile_params $F_INTERF | $EGREP -E "^(flt_M)" | $GAWK '{ print $2 }' | $UNIQ`
}
############################################################################
# Limpa as regras atuais, fazendo as ficar sem regra alguma
LIMPAR () {
 log_action_begin_msg "Flush" && {
    $IPTABLES -w -F -t filter # Nao defaults
    $IPTABLES -w -X -t filter # Zerar todas
    $IPTABLES -w -Z -t filter # Estatistica
    $IPTABLES -w -F -t mangle # Nao defaults
    $IPTABLES -w -X -t mangle # Zerar todas
    $IPTABLES -w -Z -t mangle # Estatistica
    $IPTABLES -w -F -t nat    # Nao defaults
    $IPTABLES -w -X -t nat    # Zerar todas
    $IPTABLES -w -Z -t nat    # Estatistica
  } &&  log_action_end_msg $?
}
###########################################################################
LOGSTART () {
 log_action_begin_msg "Log Start" && {
  #Inicializar
  #  grfile_params $F_ACESSOS | while read tipo prot serv pid limini limsec limcon log logden band qos comment;do
  #  done

  #Ignora log de interfaces de clientes se for para redes internas, tipo broadcast por exemplo OU loga
  if [ "$LOGGING_INTLAN" == "0" ]; then
        $IPTABLES -w -t filter -A LOGPLUS -m mark --mark 100 -j RETURN
  else
     for DCLI in $DEV_ADM $DEV_CLI; do
	if [ "`grok_interface $DCLI`" == "1" ]; then
	    #ver modulo -m addrtype 
	    #http://www.vivaolinux.com.br/artigo/Manual-do-IPtables-Comentarios-e-sugestoes-de-regras/?pagina=2
	    $IPTABLES -w -t filter -A INPUT   -i $DCLI -d 255.255.255.255    -m conntrack --ctstate NEW $LOG_LIMITBCAST1_COMMAND log-lanbcastall $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=blk-bcastall " --log-tcp-options --log-ip-options --log-uid
	    $IPTABLES -w -t filter -A LOGPLUS -i $DCLI -d 255.255.255.255    -j RETURN
	fi
     done
  fi

  if [ "$LOGGING_SRVALT" == "1" ]; then
	$IPTABLES -w -t filter -A   INPUT -p tcp --dport 1024:65535 -j LOGPLUS $LOG_LIMIT1_COMMAND log-i_tcp_alt 	#-m conntrack --ctstate NEW 
	$IPTABLES -w -t filter -A   INPUT -p udp --dport 1024:65535 -j LOGPLUS $LOG_LIMIT1_COMMAND log-i_udp_alt 	#-m conntrack --ctstate NEW 
	$IPTABLES -w -t filter -A  OUTPUT -p tcp --dport 1024:65535 -j LOGPLUS $LOG_LIMIT1_COMMAND log-o_tcp_alt	#-m conntrack --ctstate NEW
	$IPTABLES -w -t filter -A  OUTPUT -p udp --dport 1024:65535 -j LOGPLUS $LOG_LIMIT1_COMMAND log-o_udp_alt	#-m conntrack --ctstate NEW
  fi
  if [ "$LOGGING_SRVBAI" == "1" ]; then
	$IPTABLES -w -t filter -A   INPUT -p tcp --dport 0:1023 -j LOGPLUS $LOG_LIMIT1_COMMAND log-i_tcp_bai 		#-m conntrack --ctstate NEW
	$IPTABLES -w -t filter -A   INPUT -p udp --dport 0:1023 -j LOGPLUS $LOG_LIMIT1_COMMAND log-i_udp_bai 		#-m conntrack --ctstate NEW
	$IPTABLES -w -t filter -A  OUTPUT -p tcp --dport 0:1023 -j LOGPLUS $LOG_LIMIT1_COMMAND log-o_tcp_bai 		#-m conntrack --ctstate NEW
	$IPTABLES -w -t filter -A  OUTPUT -p udp --dport 0:1023 -j LOGPLUS $LOG_LIMIT1_COMMAND log-o_udp_bai 		#-m conntrack --ctstate NEW
  fi
  if [ "$LOGGING_CLTALT" == "1" ]; then
	$IPTABLES -w -t filter -A FORWARD -p tcp --dport 1024:65535 -j LOGPLUS $LOG_LIMIT1_COMMAND log-f_tcp_alt	#-m conntrack --ctstate NEW
	$IPTABLES -w -t filter -A FORWARD -p udp --dport 1024:65535 -j LOGPLUS $LOG_LIMIT1_COMMAND log-f_udp_alt	#-m conntrack --ctstate NEW
  fi
  if [ "$LOGGING_CLTBAI" == "1" ]; then
	$IPTABLES -w -t filter -A FORWARD -p tcp --dport 0:1023 -j LOGPLUS $LOG_LIMIT1_COMMAND log-f_tcp_bai		#-m conntrack --ctstate NEW
	$IPTABLES -w -t filter -A FORWARD -p udp --dport 0:1023 -j LOGPLUS $LOG_LIMIT1_COMMAND log-f_udp_bai		#-m conntrack --ctstate NEW
  fi

  $IPTABLES -w -t filter -A   INPUT -p icmp -j LOGPLUS $LOG_LIMIT1_COMMAND log-i_icmp
  $IPTABLES -w -t filter -A  OUTPUT -p icmp -j LOGPLUS $LOG_LIMIT1_COMMAND log-o_icmp
  $IPTABLES -w -t filter -A FORWARD -p icmp -j LOGPLUS $LOG_LIMIT1_COMMAND log-f_icmp

  #Finalizar: http://www.iptables.info/en/connection-state.html 
  #--log-ip-options --log-tcp-options --log-tcp-sequence
  #--ctstate INVALID,NEW,ESTABLISHED,RELATED,UNTRACKED,SNAT,DNAT
  #--ctstatus NONE,EXPECTED,SEEN_REPLY,ASSURED,CONFIRMED 
   $IPTABLES -w -t filter -A LOGPLUS $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=- " --log-uid --log-tcp-options --log-ip-options -m conntrack --ctstate NEW
   $IPTABLES -w -t filter -A LOGPLUS $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=e " --log-uid --log-tcp-options --log-ip-options -m conntrack --ctstate ESTABLISHED
   $IPTABLES -w -t filter -A LOGPLUS $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=r " --log-uid --log-tcp-options --log-ip-options -m conntrack --ctstate RELATED
   $IPTABLES -w -t filter -A LOGPLUS $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=u " --log-uid --log-tcp-options --log-ip-options -m conntrack --ctstate UNTRACKED
   $IPTABLES -w -t filter -A LOGPLUS $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=i " --log-uid --log-tcp-options --log-ip-options -m conntrack --ctstate INVALID
 } &&  log_action_end_msg $?
}

###########################################################################
# Inicializa log de pacotes conhecidos
LOGSET () {
  log_action_begin_msg "Log Set" && { 
    #Log default para todos os pacotes que nele sao enviados
    $IPTABLES -w -t filter -F LOGPLUS 2> /dev/null ; $IPTABLES -w -t filter -N LOGPLUS 2> /dev/null
    #Drop Seletivo para FILTER
    $IPTABLES -w -t filter -F DROPPLUS 2> /dev/null ; $IPTABLES -w -t filter -N DROPPLUS 2> /dev/null
    $IPTABLES -w -t filter -A DROPPLUS -p icmp -j DROP		#Simplesmente ignora os do tipo ICMP
    if [ ! -z "${FLT_FASE1_TIPO}${FLT_FASE1_RATE}" ]; then
	$IPTABLES -w -t filter -A DROPPLUS $FLT_FASE1_RATE -j REJECT --reject-with $FLT_FASE1_TIPO
    fi
    if [ ! -z "${FLT_FASE2_TIPO}${FLT_FASE2_RATE}" ]; then
	$IPTABLES -w -t filter -A DROPPLUS $FLT_FASE2_RATE -j REJECT --reject-with $FLT_FASE2_TIPO
    fi
    if [ ! -z "${FLT_FASE3_TIPO}${FLT_FASE3_RATE}" ]; then
	$IPTABLES -w -t filter -A DROPPLUS $FLT_FASE3_RATE -j REJECT --reject-with $FLT_FASE3_TIPO
    fi
    if [ ! -z "${FLT_FASE4_TIPO}${FLT_FASE4_RATE}" ]; then
	$IPTABLES -w -t filter -A DROPPLUS $FLT_FASE4_RATE -j REJECT --reject-with $FLT_FASE4_TIPO
    fi
    if [ ! -z "${FLT_FASE5_TIPO}${FLT_FASE5_RATE}" ]; then
	$IPTABLES -w -t filter -A DROPPLUS $FLT_FASE5_RATE -j REJECT --reject-with $FLT_FASE5_TIPO
    fi
    $IPTABLES -w -t filter -A DROPPLUS -j DROP
  } &&  log_action_end_msg $?
}
############################################################################
# Abre Geral 
ABRIR () {
  log_action_begin_msg "Open" && { 
    $IPTABLES -w -t filter -P INPUT ACCEPT
    $IPTABLES -w -t filter -P FORWARD ACCEPT
    $IPTABLES -w -t filter -P OUTPUT ACCEPT
    $IPTABLES -w -t nat -P PREROUTING ACCEPT
    $IPTABLES -w -t nat -P POSTROUTING ACCEPT
    $IPTABLES -w -t nat -P OUTPUT ACCEPT
    $IPTABLES -w -t mangle -P PREROUTING ACCEPT
    $IPTABLES -w -t mangle -P OUTPUT ACCEPT
  } &&  log_action_end_msg $?
}
############################################################################
# Fecha acesso a interfaces (Default e Append com Log)
FECHAR () {
  log_action_begin_msg "Close" && {
    #Mais flexibilidade para negativas na rede interna ou proprio servidor, com REJECT
    $IPTABLES -w -t filter -A OUTPUT -j REJECT
    $PIP route | $EGREP -E "($DEV_ADM|$DEV_CLI)" | $EGREP -E "src" | $EGREP -E -v "(^((0|127|224|239)[.]0[.])|(ppp))" |  while read dest1 w11 dev1 w12 w13 w14 w14 w16 src1 linkdown1;do
	$IPTABLES -w -t filter -A INPUT   -i $dev1 -d $src1 -j REJECT
	$IPTABLES -w -t filter -A FORWARD -i $dev1          -j REJECT
    done
    #Redes Ponto a Ponto
    if [ ! -z "$IFF_VPN" ]; then
        $IPTABLES -w -t filter -A INPUT   -i $IFF_VPN -j REJECT 
	$IPTABLES -w -t filter -A FORWARD -i $IFF_VPN -j REJECT 
    fi 

    #Outra redes nega de forma "Pesada"
    $IPTABLES -w -t filter -A INPUT -j DROPPLUS
    $IPTABLES -w -t filter -A FORWARD -j DROPPLUS
    $IPTABLES -w -t filter -P INPUT DROP
    $IPTABLES -w -t filter -P OUTPUT DROP
    $IPTABLES -w -t filter -P FORWARD DROP
    #Flush nas Rotas (#ip route show cached)
    $PIP route flush cached 
  } &&  log_action_end_msg $?
}
############################################################################
# Fecha acesso a interfaces (Default e Append com Log)
TERCEIROS () {
  log_action_begin_msg "IDS de Terceiros" && { 
    if [ -z "$*" ]; then
        $IPTABLES -w -t filter -F FAIL2BAN_S 2> /dev/null                                     ; $IPTABLES -w -t filter -N FAIL2BAN_S 2> /dev/null
 	$IPTABLES -w -t filter -I INPUT   3 -j FAIL2BAN_S -m mark ! --mark 100 #somente para redes externas!
    fi
    #Fail2Ban
    #if [ `cat /proc/uptime | cut -d "." -f 1` -gt 600 ]; then
        if [ -S /var/run/fail2ban/fail2ban.sock ]; then
	    # fail2ban-client -v -x reload 2> /dev/null  > /dev/null
	    systemctl reload fail2ban & 2> /dev/null  > /dev/null
	    [[ "$-" =~ "i" ]] && echo " " > /var/log/fail2ban.log ; fail2ban-client set logtarget /var/log/fail2ban.log >/dev/null #Iterativo
	fi
    #fi
  } &&  log_action_end_msg $?

  log_action_begin_msg "UPNP" && { 
    #UPNP
    if [ -f /var/run/linux-igd.pid ]; then
      service linux-igd restart 2> /dev/null  > /dev/null
    fi
  } &&  log_action_end_msg $?

  log_action_begin_msg "CACHE" && { 
    #Squid
    if [ -f /var/run/squid3.pid ]; then
      squid3 -k check
      service squid3 reload 2> /dev/null  > /dev/null
    fi
  } &&  log_action_end_msg $?
}

############################################################################
#Lista de bloqueios recomendados Dshield
# http://feeds.dshield.org/block.txt
# https://isc.sans.edu/block.txt
# http://feeds.dshield.org/topports.txt
# http://feeds.dshield.org/top10-2.txt
# https://www.dshield.org/feeds/topips.txt
# https://secure.dshield.org/hpb.html?key=c7nsQ9dl2fQlWFh/O/+o4w==
DSHIELD () {
  log_action_begin_msg "DSHIELD ISC Block List" && {
    if [ `$FIND "$DSHIELDFILE_BLK" -mtime -0 -print 2> /dev/null | wc -l` -ne 1 ]; then
        rm -f "$DSHIELDFILE_BLK" 2> /dev/null
	wget --quiet -O - --tries=10 http://feeds.dshield.org/block.txt >  $DSHIELDFILE_BLK 2> /dev/null
	wget --quiet -O - --tries=10 https://isc.sans.edu/block.txt     >> $DSHIELDFILE_BLK 2> /dev/null
    fi
    if [ `$FIND "$DSHIELDFILE_LOG" -mtime -0 -print 2> /dev/null | wc -l` -ne 1 ]; then
        rm -f "$DSHIELDFILE_LOG" 2> /dev/null
	wget --quiet -O - --tries=10 http://feeds.dshield.org/top10-2.txt >  $DSHIELDFILE_LOG 2> /dev/null
	#wget --quiet -O - --tries=10 https://isc.sans.edu/top10-2.txt    >> $DSHIELDFILE_LOG 2> /dev/null	#ERRO arquivo .gz!
    fi

    if [ -z "$*" ]; then
        $IPTABLES -w -t filter -F DSHIELDISCBLK_S 2> /dev/null                                     ; $IPTABLES -w -t filter -N DSHIELDISCBLK_S 2> /dev/null
        $IPTABLES -w -t filter -F DSHIELDISCLOG_S 2> /dev/null                                     ; $IPTABLES -w -t filter -N DSHIELDISCLOG_S 2> /dev/null
        for DCLI in $DEV_EXT; do
            if [ "`grok_interface $DCLI`" == "1" ]; then
    	        $IPTABLES -w -t filter -i $DCLI -I INPUT 3 -j DSHIELDISCBLK_S -m mark ! --mark 100 #Somente para redes externas!
    	        $IPTABLES -w -t filter -i $DCLI -I INPUT 3 -j DSHIELDISCLOG_S -m mark ! --mark 100 #Somente para redes externas!
	    fi
        done
    fi

    if [ -f "$DSHIELDFILE_BLK" ]; then
	$IPTABLES -w -t filter -F DSHIELDISCBLK_S 2> /dev/null
        grfile_params $DSHIELDFILE_BLK | $EGREP -E '^(([0-9]{1,3}[.]){3}([0-9]{1,3}))([/]([0-9]{1,2}))?' | $GAWK '{ print $1"/"$3 }' | $SORT | $UNIQ | while read hst; do
	    $IPTABLES -w -t filter -A DSHIELDISCBLK_S -s $hst $LOG_LIMIT1_COMMAND blk-dshield-isc $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=blk-dshield-isc " --log-tcp-options --log-ip-options --log-uid
	    $IPTABLES -w -t filter -A DSHIELDISCBLK_S -s $hst -j DROP 
	done
    fi
    if [ -f "$DSHIELDFILE_LOG" ]; then
	$IPTABLES -w -t filter -F DSHIELDISCLOG_S 2> /dev/null
        grfile_params $DSHIELDFILE_LOG | $EGREP -E '^(([0-9]{1,3}[.]){3}([0-9]{1,3}))([/]([0-9]{1,2}))?' | $GAWK '{ print $1 }' | $SORT | $UNIQ | while read hst; do
	    $IPTABLES -w -t filter -A DSHIELDISCLOG_S -s $hst $LOG_LIMIT1_COMMAND log-dshield-isc $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=log-dshield-isc " --log-tcp-options --log-ip-options --log-uid
	done
    fi
  } &&  log_action_end_msg $?
}

############################################################################
DYNACCHST () {
  log_action_begin_msg "DYNIP Acc Hst " && {
    if [ -z "$*" ]; then
        #Inicializacao
        $IPTABLES -w -t nat -F PREROUTING-DYN-E 2> /dev/null 				   ; $IPTABLES -w -t nat -N PREROUTING-DYN-E 2> /dev/null
        $IPTABLES -w -t filter -F DYN_ECT 2> /dev/null                                     ; $IPTABLES -w -t filter -N DYN_ECT 2> /dev/null
	#Associacoes por redes internas ou clientes ou servidores
        $ROUTE -n | $EGREP -E "^[[:digit:]]" | $EGREP -E -v  "(^((0|127|224|239)[.]0[.])|(UH|UG))" | while read dest1 gw1 mask1 op1 met1 ref1 uso1 dev1; do #Redes Locais
            $IPTABLES -w -t filter -A FORWARD -j DYN_ECT -i $dev1 -s $dest1/$mask1 -m conntrack --ctstate NEW  -m mark ! --mark 100 #Apenas redes Nao Locais
        done
    fi

    #Sempre dar Flush antes
    $IPTABLES -w -t filter -F DYN_ECT 2> /dev/null
    $IPTABLES -w -t nat -F PREROUTING-DYN-E 2> /dev/null

    #Inicialmente sem log, apenas acesso o mais simples possivel
    grfile_params $F_ACCDYN | while read hst comment; do
        $IPTABLES -w -t filter -A DYN_ECT -d $hst -j ACCEPT
        $IPTABLES -w -t nat -A PREROUTING-DYN-E -d $hst -j RETURN
    done
  } &&  log_action_end_msg $?
}

############################################################################
# Lista de MacAddress
# Parametros: interface 

# /etc/sudoers (para usuario mac, senha mac)
# ##mac  ALL=/sbin/firewall mac, /usr/bin/mcedit /etc/firewall/mac.ini, /sbin/firewall monmac continue
#
# ~mac/.bash_profile (mudar o dono pra root, pra evitar sacanagens) chamando...
# ##!/bin/bash
# #/usr/bin/sudo /usr/bin/mcedit /etc/firewall/mac.ini
# #/usr/bin/sudo /sbin/firewall mac
# #echo -Aguarde 5 segundos...
# #sleep 5
# #/usr/bin/sudo /sbin/firewall monmac continue
# #exec login

MACACC () {
if [ "$MACFILT" == "1" ]; then
  log_action_begin_msg "Mac Acc $*" && { 
    $IPTABLES -w -t mangle -F MACACC 2> /dev/null ; $IPTABLES -w -t mangle -N MACACC 2> /dev/null
    #Associar
    if [ -z "$*" ]; then
        $ROUTE -n | $EGREP -E "^[[:digit:]]" | $EGREP -E -v  "(^((0|127|224|239)[.]0[.])|(UH|UG))" | $SORT -dbfru -k 8 | while read dest1 gw1 mask1 op1 met1 ref1 uso1 dev1; do #Redes Locais
            if [ ! -z "`echo .$DEV_MAC. | $EGREP -E $dev1`" ]; then
		$IPTABLES -w -t mangle -A PREROUTING  -i $dev1 -j MACACC   	#Associacao GLOBAL
		log_action_cont_msg "$dev1 "
	    fi
	done
    fi
    #Acessa tranquilamente a rede ADMIN sem restricao para possibilitar "manejos" (ex: manipular bridges sem precisar liberar elas)
    $ROUTE -n | $EGREP -E "^[[:digit:]]" | $EGREP -E -v  "(^((0|127|224|239)[.]0[.])|(UH|UG))" | while read dest1 gw1 mask1 op1 met1 ref1 uso1 dev1; do #Redes Locais
            if [ ! -z "`echo .$DEV_ADM. | $EGREP -E $dev1`" ]; then
	       	$IPTABLES -w -t mangle -A MACACC -d $dest1/$mask1 -j RETURN -m conntrack --ctstate ESTABLISHED #Apenas da admin para a outra, nao ao contrario
            fi
            if [ ! -z "`echo .$DEV_MAC. | $EGREP -E $dev1`" ]; then
	       	$IPTABLES -w -t mangle -A MACACC -d $dest1/$mask1 -j RETURN -m conntrack --ctstate ESTABLISHED #Apenas do servidor para a outra, nao ao contrario
	    fi	    
    done
    #Filtrar
    grfile_params $F_MAC | while read mac src ttl comment;do
        if [ "$ttl" == "-" ]; then X_TTL=""		; else X_TTL="-m ttl --ttl-lt $ttl"; fi 
    	$IPTABLES -w -t mangle -A MACACC -m mac --mac-source $mac -s ${src/-/"0.0.0.0/0"} $X_TTL -j RETURN
    done
    if [ "$LOGGING_MACFILT" == "1" ]; then 
	$IPTABLES -w -t mangle -A MACACC -j LOGPLUS
    fi
    $IPTABLES -w -t mangle -A MACACC -j DROPPLUS 
  } &&  log_action_end_msg $?
fi
}
############################################################################
# Lista de MacAddress Fixados via DHCPD (dhcpd.conf)
# Parametros: interface 
MACFIX () {
if [ "$MACFIX" == "1" ]; then
  log_action_begin_msg "Mac Fix $*" && { 
    $IPTABLES -w -t mangle -F MACFIX 2> /dev/null ; $IPTABLES -w -t mangle -N MACFIX 2> /dev/null
    #Associar
    if [ -z "$*" ]; then
        $ROUTE -n | $EGREP -E "^[[:digit:]]" | $EGREP -E -v  "(^((0|127|224|239)[.]0[.])|(UH|UG))" | while read dest1 gw1 mask1 op1 met1 ref1 uso1 dev1; do #Redes Locais
            if [ ! -z "`echo .$DEV_MAC. | $EGREP -E $dev1`" ]; then
		$IPTABLES -w -t mangle -A PREROUTING  -i $dev1 -j MACFIX   	#Associacao GLOBAL
    		log_action_cont_msg " $dev1"
	    fi	    
	done
    fi
    #Filtrar
    $IPTABLES -w -t mangle -A MACFIX -s 0.0.0.0 -d 255.255.255.255 -j RETURN 	#Broadcasts
    $EGREP -E -v "^#"  /etc/dhcpd.conf | $EGREP -E "(fixed-address|hardware)" | $GAWK -F " " '{
      if ($1 == "fixed-address")
        A=$2;
      if ($1 == "hardware")
        printf("%s %s\n",substr($3,1,length($3)-1),substr(A,1,length(A)-1));}' | while read mac host; do
	    $IPTABLES -w -t mangle -A MACFIX -m mac --mac-source $mac ! -s $host  -j DROPPLUS 
	done
  } &&  log_action_end_msg $?
fi
}

###########################################################################
#Port Knock para o SSH
#/proc/net/xt_recent/
SSHKNOCK () {
  log_action_begin_msg "PORTKNOCK" && {
    REGRA_KNOCK="KNOCK_SSHPORTS"
    #Associacao de Update
    if [ -z "$*" ]; then
	$IPTABLES -w -t filter -F $REGRA_KNOCK 2> /dev/null 					; $IPTABLES -w -t filter -N $REGRA_KNOCK 2> /dev/null
	$IPTABLES -w -t filter -I INPUT 1 -j $REGRA_KNOCK
    fi
    SSHPRT="`cat $CONFSSHD | $EGREP -E ^Port | $GAWK -F " " '{ printf("tcp:%s",$2);}'`"
    portknock "$SSHPRT tcp:telnet tcp:ssh" "$SSH_KNOCK" "$REGRA_KNOCK"
  } &&  log_action_end_msg $?
}
###########################################################################
#Inicializa controle remoto
SSH () {
  log_action_begin_msg "SSH DIRETO" && {
    SSHPRT="`cat $CONFSSHD | $EGREP -E ^Port | cut -f2 -d" "`"
    for SSHMOD in $SSHPRT; do
        $IPTABLES -w -t filter -A INPUT  -p tcp --dport $SSHMOD -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
        $IPTABLES -w -t filter -A OUTPUT -p tcp --sport $SSHMOD -m conntrack --ctstate ESTABLISHED     -j ACCEPT
        # echo "$SSHMOD "
    done
  } &&  log_action_end_msg $?
}
############################################################################
# Hosts Extermamente Confiaveis e especificas
# Parametros: INTERNAS, EXTERNAS
ESPECIFICAS () {
  log_action_begin_msg "ESPEC" && { 
    #Minha interface local
    $IPTABLES -w -t filter -A  INPUT  -i lo -j ACCEPT
    $IPTABLES -w -t filter -A OUTPUT  -o lo -j ACCEPT
    #Multicast
    $PIP route | $EGREP -E "($DEV_ADM|$DEV_CLI)" | $EGREP -E "link" | $EGREP -E "(^((224|239)[.]0[.]))" |  while read dest1 w11 dev1 w12 w13 w14 w14 w16 src1 linkdown1;do
        $IPTABLES -w -t filter -A INPUT   -i $dev1 -s $dest1 -j ACCEPT
        $IPTABLES -w -t filter -A OUTPUT  -o $dev1 -d $dest1 -j ACCEPT
    done
    #DNS Publicos
    $IPTABLES -w -t filter -A OUTPUT -d 8.8.8.8 -j ACCEPT
    $IPTABLES -w -t filter -A OUTPUT -d 8.8.4.4 -j ACCEPT
    $IPTABLES -w -t filter -A OUTPUT -d 4.2.2.1 -j ACCEPT
    $IPTABLES -w -t filter -A OUTPUT -d 4.2.2.2 -j ACCEPT
    $IPTABLES -w -t filter -A OUTPUT -d 4.2.2.3 -j ACCEPT
    $IPTABLES -w -t filter -A OUTPUT -d 4.2.2.4 -j ACCEPT
    $IPTABLES -w -t filter -A OUTPUT -d 4.2.2.5 -j ACCEPT
    $IPTABLES -w -t filter -A OUTPUT -d 4.2.2.6 -j ACCEPT
    $IPTABLES -w -t filter -A OUTPUT -d 208.67.220.220 -j ACCEPT
    $IPTABLES -w -t filter -A OUTPUT -d 208.67.222.222 -j ACCEPT
    #Relatados ICMP
    $IPTABLES -w -t filter -A INPUT   -j ACCEPT -m conntrack --ctstate RELATED -p icmp
    $IPTABLES -w -t filter -A OUTPUT  -j ACCEPT -m conntrack --ctstate RELATED -p icmp
    $IPTABLES -w -t filter -A FORWARD -j ACCEPT -m conntrack --ctstate RELATED -p icmp
    #Ident
    $IPTABLES -w -t filter -A INPUT   -p tcp --dport auth -j REJECT -m conntrack --ctstate NEW --reject-with tcp-reset
    $IPTABLES -w -t filter -A OUTPUT  -p tcp --dport auth -j ACCEPT -m conntrack --ctstate NEW 
    $IPTABLES -w -t filter -A FORWARD -p tcp --dport auth -j REJECT --reject-with tcp-reset
    #DHCP via Broadcast
    $IPTABLES -w -t filter -A  INPUT  -p udp --dport bootps -s 0.0.0.0 --sport bootpc -d 255.255.255.255 -j ACCEPT
    #Multicast Client/Server
    #$IPTABLES -w -t filter -A   INPUT -p igmp -j ACCEPT
    #$IPTABLES -w -t filter -A  OUTPUT -p igmp -j ACCEPT
    #ADSL somente se ADSL! Serve para Forward tambem!
    #$IPTABLES -w -t filter -A OUTPUT  -p tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1400:1536 -j TCPMSS --clamp-mss-to-pmtu #ADSL
    #$IPTABLES -w -t filter -A OUTPUT  -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 			   #ADSL
    #Log Roteador
    for slog in $EXT_SYSLOG; do
	$IPTABLES -w -t filter -A  INPUT -p udp --dport snmp-trap -s $slog -j ACCEPT 
	$IPTABLES -w -t filter -A  INPUT  -p udp --dport syslog   -s $slog -j ACCEPT 
        $IPTABLES -w -t filter -A  INPUT  -p udp --dport tftp   -s $slog -j ACCEPT
    done
    #Referentes a outras conexoes com helper (ftp-2121 h323 pptp irc proto-gre sip netbios-ns proto-udplite)
    #FTP
    $IPTABLES -w -t filter -A INPUT   -j ACCEPT -m helper --helper ftp-2121		-p tcp -m conntrack --ctstate RELATED
    $IPTABLES -w -t filter -A INPUT   -j ACCEPT -m helper --helper ftp-2121		-p tcp -m conntrack --ctstate RELATED
    $IPTABLES -w -t filter -A OUTPUT  -j ACCEPT -m helper --helper ftp-2121		-p tcp -m conntrack --ctstate RELATED
    $IPTABLES -w -t filter -A OUTPUT  -j ACCEPT -m helper --helper ftp-2121		-p tcp -m conntrack --ctstate RELATED
    #SIP e RS323
    $IPTABLES -w -t filter -A FORWARD -j ACCEPT -m helper --helper sip  		-p udp -m conntrack --ctstate RELATED
    $IPTABLES -w -t filter -A FORWARD -j ACCEPT -m helper --helper h323 		-p udp -m conntrack --ctstate RELATED
    $IPTABLES -w -t filter -A FORWARD -j ACCEPT -m helper --helper proto-udplite	-p udp -m conntrack --ctstate RELATED
    #NETBIOS-NS
    $IPTABLES -w -t filter -A INPUT   -j ACCEPT -m helper --helper netbios-ns           -p udp --sport netbios-ns -m mark --mark 100
    $IPTABLES -w -t filter -A OUTPUT  -j ACCEPT -m helper --helper netbios-ns           -p udp --dport netbios-ns -m mark --mark 100
    #        #Referentes a outras conexoes com helper (ftp-2121 h323 pptp irc proto_gre sip netbios_ns proto_udplite)
    #        for helpType in ftp-2121 h323 proto_gre sip netbios_ns proto_udplite; do
    #            $IPTABLES -w -t filter -A INPUT   -j ACCEPT -m helper --helper $helpType -m conntrack --ctstate RELATED.
    #            $IPTABLES -w -t filter -A OUTPUT  -j ACCEPT -m helper --helper $helpType -m conntrack --ctstate RELATED.
    #            $IPTABLES -w -t filter -A FORWARD -j ACCEPT -m helper --helper $helpType -m conntrack --ctstate RELATED.
    #        done
    #Verisign Null
    #route add net 64.94.110.0 -netmask 255.255.255.0 127.0.0.1 1
    #224.0.0.0       0.0.0.0         240.0.0.0       U     0      0        0 eth0
    #239.0.0.0       0.0.0.0         255.0.0.0       U     0      0        0 eth0
  } &&  log_action_end_msg $?
}
############################################################################
# Mascaramento de Ips invalidos de saida externa
# Parametros Interface EXTERNA
# Balanceamento de carga exemplo
# iptables -A PREROUTING -i eth0 -p tcp --dport 80 -m conntrack --ctstate NEW -m nth --counter 0 --every 4 --packet 0 -j DNAT --persistent --to-destination 192.168.1.10:80
# iptables -A PREROUTING -i eth0 -p tcp --dport 80 -m conntrack --ctstate NEW -m nth --counter 0 --every 4 --packet 1 -j DNAT --persistent --to-destination 192.168.1.20:80
# iptables -A PREROUTING -i eth0 -p tcp --dport 80 -m conntrack --ctstate NEW -m nth --counter 0 --every 4 --packet 2 -j DNAT --persistent --to-destination 192.168.1.30:80
# iptables -A PREROUTING -i eth0 -p tcp --dport 80 -m conntrack --ctstate NEW -m nth --counter 0 --every 4 --packet 3 -j DNAT --persistent --to-destination 192.168.1.40:80
#
#iptables -w -t nat -A M-PREROUTING  -i + -o + -p tcp --dport 11111               -j DNAT --persistent --to-destination 10.10.0.30:11111
#iptables -w -t nat -I M-POSTROUTING -i + -o + -p tcp --dport 11111 -d 10.10.0.30 -j SNAT --persistent --to-source 10.0.0.2
#
NAT () {
  log_action_begin_msg "NAT" && {
    #Corta Repasse
    echo 0 > /proc/sys/net/ipv4/ip_forward
    $IPTABLES -w -t nat -F POSTROUTING-SNAT-I 2> /dev/null ; $IPTABLES -w -t nat -N POSTROUTING-SNAT-I 2> /dev/null
    $IPTABLES -w -t nat -F POSTROUTING-SNAT-E 2> /dev/null ; $IPTABLES -w -t nat -N POSTROUTING-SNAT-E 2> /dev/null
    #Portas redir em si
    grfile_params "$F_REDIR1 $F_REDIR2" | while read prot dportori dnetori dnetdest dportredir dredir dtype comment;do
	if [ "$dredir" != "-" -a -z "`echo .$dnetori. | $EGREP -E /`" ]; then 	#Apenas aqueles que nao ha redirecionamentos tipo desvio do squid proxy transparente ou de qualquer origem
	    #--------------------------------------------------------------
	    #-- Achar protocolo
            prot=${prot/-/all} 
            #-- Destino especifico
            if [ "$dnetdest" != "-" ]; then
                DDH="-d $dnetdest" ; DSH="-d $dnetdest" ; DHH="$dnetdest"
            else
                DDH="" ; DSH="" ; DHH=""
            fi
            #-- Origem Especifica
            if [ "$dnetori" != "-" ]; then
                SSH="-s $dnetori" ; SDH="-d $dnetori" ; SHH="$dnetori"
            else
                SSH="" ; SDH="" ;  SHH=""
            fi
            #-- Porta original em que a conexao vem
            if [ "$dportori" != "-" ]; then
                OPP=":$dportori"
                if [ ! -z "`echo .$dportori. | $EGREP -E ,`" ]; then
                    ODP="-m multiport --dports $dportori" ;     OSP="-m multiport --sports $dportori"
                elif [ "$prot" == "icmp" ]; then
                    ODP="--icmp-type $dportori";                OSP="--icmp-type $dportori"
                else
                    ODP="--dport $dportori" ;                   OSP="--sport $dportori"
                fi
            else
                ODP="" ; OSP="" ; OPP=""
            fi
            #-- Porta redirecionada em que a conexao vai
            if [ "$dportredir" != "-" ]; then
                RPP=":$dportredir"
                if [ ! -z "`echo .$dportredir. | $EGREP -E ,`" ]; then
                    RDP="-m multiport --dports $dportredir" ;   RSP="-m multiport --sports $dportredir"
                elif [ "$prot" == "icmp" ]; then
                    RDP="--icmp-type $dportredir";              RSP="--icmp-type $dportredir"
                else
                    RDP="--dport $dportredir" ;                 RSP="--sport $dportredir"
                fi
            else
                RDP="" ; RSP="" ; RPP=""
            fi

	    #-- Achar Ip da Interface
	    dredir=`grok_addr $dredir`	#Pega o ip caso seja uma interface
  	    #echo RDP: $RDP - ODP: $ODP - OSP: $OSP - RSP: $RSP 
	    #--------------------------------------------------------------
	    #Readaptar porta de origem para multiportas
	    if [ "${RPP}" != "" -a "$dportredir" != "$dportori" -o "$DDH" != "" ]; then
		$IPTABLES -w -t nat -A POSTROUTING-SNAT-E -p $prot -s $dredir $OSP $SDH -j SNAT --to-source ${DHH}${RPP} #--persistent 
	    fi
	    #Readaptacao de Source para enderecos sem rota e internos
	    if [ "$dtype" != "" -a "$dtype" != "-" ]; then
           	$IPTABLES -w -t nat -A POSTROUTING-SNAT-E -p $prot -d $dredir $RDP $SSH -o $dtype -j MASQUERADE
    	       #$IPTABLES -w -t nat -A POSTROUTING-SNAT-E -p $prot -d $dredir $RDP $SSH -j SNAT --to-source `grok_addr $dtype` #--persistent 
	    fi
	#else
	#    echo "ERRO Redir NAT: $prot $dportori $dnetori $dportredir $dredir $dtype $comment"
    	fi
    done

    #Associar Mascaramento
    grfile_params $F_INTERF | $EGREP -E "^(rtr)_" | while read TpIff IffSrc IffOut IffNat IffFlag comment; do
	if [ "$IffSrc" == "-" ] && [ "$IffOut" != "-" ] && [ "$IffNat" != "-" ] && [ "$IffFlag" != "-" ]; then
	     $IPTABLES -w -t nat -A POSTROUTING-SNAT-E -m mark ! --mark 100 -o $IffOut -j MASQUERADE
	elif [ "$IffOut" != "-" ] && [ "$IffNat" != "-" ] && [ "$IffFlag" != "-" ]; then
            NET_IffSrc=`grok_netmask $IffSrc`
	    NET_IffNat=`grok_addr $IffNat`
    	    if [ "$IffNat" == "$IffOut" ]; then
		if [ "$IffSrc" != "$IffNat" ]; then
        	    for NET in $NET_IffSrc; do
			[[ "$IffFlag" =~ "e" ]] && $IPTABLES -w -t nat -A POSTROUTING-SNAT-E -s $NET -o $IffOut -j MASQUERADE
			[[ "$IffFlag" =~ "i" ]] && $IPTABLES -w -t nat -A POSTROUTING-SNAT-I -s $NET -o $IffOut -j MASQUERADE
        	    done
		fi
    	    elif [ "$IffNat" != "-" ]; then
		#echo -n " $IffSrc->$IffNat"
        	for NET in $NET_IffSrc; do
            	    [[ "$IffFlag" =~ "e" ]] && $IPTABLES -w -t nat -A POSTROUTING-SNAT-E -s $NET -o $IffOut -j SNAT --to-source $NET_IffNat #--persistent 
            	    [[ "$IffFlag" =~ "i" ]] && $IPTABLES -w -t nat -A POSTROUTING-SNAT-I -s $NET -o $IffOut -j SNAT --to-source $NET_IffNat #--persistent 
        	done
    	    fi
	fi
    done

    #Associar
    if [ -z "$*" ]; then #Associar global Masq em segundo
	#Existe alguma vpn?
	if [ ! -z "$NET_VPN" -a ! -z "$MSQ_VPN"  ]; then
	    $IPTABLES -w -t nat -A POSTROUTING -s $NET_VPN -o $MSQ_VPN -j MASQUERADE	#Por outro ip?
	fi
        $IPTABLES -w -t nat -A POSTROUTING  -j POSTROUTING-SNAT-I -m mark    --mark 100 #Apenas Interno
        $IPTABLES -w -t nat -A POSTROUTING  -j POSTROUTING-SNAT-E -m mark  ! --mark 100 #Apenas Externo
    fi
    #Habilita Repasse
    echo 1 > /proc/sys/net/ipv4/ip_forward
  } &&  log_action_end_msg $?
}

############################################################################
# Redirecionamentos 
# VERIFICAR SERVIDORES NAS REDES INTERNAS (OBSERVE SNAT ANTERIOR)
# iptables -t nat -A OUTPUT -p all -d  200.164.229.59 -j DNAT --persistent --to-destination 10.0.1.249
REDIR () {
    log_action_begin_msg "DMZ Redir $*" && {
    echo 0 > /proc/sys/net/ipv4/ip_forward
    #Inicializacao
    $IPTABLES -w -t nat -F PREROUTING-RDR-E 2> /dev/null ; $IPTABLES -w -t nat -N PREROUTING-RDR-E 2> /dev/null 
    $IPTABLES -w -t nat -F PREROUTING-DNAT  2> /dev/null ; $IPTABLES -w -t nat -N PREROUTING-DNAT  2> /dev/null 
    #$IPTABLES -w -t nat -F OUTPUT-DNAT  2> /dev/null ; $IPTABLES -w -t nat -N OUTPUT-DNAT  2> /dev/null 
    #$IPTABLES -w -t nat -F POSTROUTING-SNAT  2> /dev/null ; $IPTABLES -w -t nat -N POSTROUTING-SNAT  2> /dev/null
    #Para Ips Restantes outros para Locais SSSSSS
    $PIP route | $EGREP -E "src" | $EGREP -E -v "(^((0|127|224|239)[.]0[.])|(ppp))" | while read dest1 w11 dev1 w12 w13 w14 w14 w16 src1 linkdown1;do
       $IPTABLES -w -t nat -A PREROUTING-RDR-E -d $src1  -j RETURN # (opcional apenas para estatistica?)
       $IPTABLES -w -t nat -A PREROUTING-RDR-E -d $dest1 -j RETURN
    done

    #Acesso direto, sem redirecionamentos (Veja acessos_hst.ini) - Squid e outros
     grfile_params "$F_ACCHST1 $F_ACCHST2" | while read tipo prot serv src dst dstnonet rdrout band qos limini limsec limcon log comment; do
        if [ "$rdrout" == "y" ]; then
    	    IPdst="`get_ip $dst $dstnonet`"
            if [ "$IPdst" == "" ]; then
                echo -n "o $dst $dstnonet"
            elif [ "$src" == "-" -a "$dst" == "-" ]; then
                echo -n "x $dst $src"
    	    else for IPdsthst in $IPdst; do
        	    $IPTABLES -w -t nat -A PREROUTING-RDR-E -s $src -d $IPdsthst -j RETURN
		 done
	    fi
	fi
    done

    #Portas redir em si
    grfile_params "$F_REDIR1 $F_REDIR2" | while read prot dportori dnetori dnetdest dportredir dredir dtype comment;do
	    #--------------------------------------------------------------
    	    prot=${prot/-/all}
            #-- Destino especifico
            if [ "$dnetdest" != "-" ]; then
                DDH="-d $dnetdest" ; DSH="-d $dnetdest" ; DHH="$dnetdest"
            else
                DDH="" ; DSH="" ; DHH=""
            fi
            #-- Origem Especifica
            if [ "$dnetori" != "-" ]; then
                SSH="-s $dnetori" ; SDH="-d $dnetori" ; SHH="$dnetori"
            else
                SSH="" ; SDH="" ;  SHH=""
            fi
    	    #-- Porta original em que a conexao vem
    	    if [ "$dportori" != "-" ]; then
    	        OPP=":$dportori"
    	        if [ ! -z "`echo .$dportori. | $EGREP -E ,`" ]; then
    		    ODP="-m multiport --dports $dportori" ; 	OSP="-m multiport --sports $dportori"  
                elif [ "$prot" == "icmp" ]; then
                    ODP="--icmp-type $dportori";              	OSP="--icmp-type $dportori"
		else
    	    	    ODP="--dport $dportori" ;			OSP="--sport $dportori" 
		fi
    	    else 
	        ODP="" ; OSP="" ; OPP=""
	    fi
    	    #-- Porta redirecionada em que a conexao vai
    	    if [ "$dportredir" != "-" ]; then 
    	        RPP=":$dportredir"
    	        if [ ! -z "`echo .$dportredir. | $EGREP -E ,`" ]; then
    		    RDP="-m multiport --dports $dportredir" ; 	RSP="-m multiport --sports $dportredir"  
                elif [ "$prot" == "icmp" ]; then
                    RDP="--icmp-type $dportredir";              RSP="--icmp-type $dportredir"
		else
    	    	    RDP="--dport $dportredir" ; 		RSP="--sport $dportredir" 
		fi
    	    else 
	        RDP="" ; RSP="" ; RPP=""
	    fi

	    #Loop de Redirecionamentoss
            if [ "$dredir" != "-" ]; then 
		dredir=${dredir/-/`grok_addr $dredir 127.0.0.1`}		#Pega o ip caso seja uma interface
	        $IPTABLES -w -t nat -A PREROUTING-DNAT -p $prot $SSH $ODP $DDH -j DNAT --to-destination ${dredir}${RPP} #--persistent
	        #$IPTABLES -w -t nat -A OUTPUT-DNAT    -p $prot $ODP -j DNAT --to-destination ${dredir}${RPP} #--persistent
	    else
		$IPTABLES -w -t nat -A PREROUTING-RDR-E -p $prot $SSH $ODP $DDH -j REDIRECT --to-ports ${dportredir/-/$dportori} -m mark ! --mark 100 #Apenas Externo
	    fi
	    #--------------------------------------------------------------
	done
	#Ativacao
	if [ -z "$1" ]; then
	    $IPTABLES -w -t nat -A PREROUTING  -j PREROUTING-RDR-E  -m mark ! --mark 100 	#Trafego antes rotear
	    $IPTABLES -w -t nat -A PREROUTING  -j PREROUTING-DNAT  				#Trafego antes rotear
	fi
	echo 1 > /proc/sys/net/ipv4/ip_forward
    } &&  log_action_end_msg $?
}

############################################################################
# UPNP Teste
#/etc/default/linux-igd
#/etc/init.d/linux-igd
UPNP () {
    log_action_begin_msg "UPNP Forward and Redir $*" && {
    $IPTABLES -w -t filter -F FORWARD-UPNP 2> /dev/null ; $IPTABLES -w -t filter -N FORWARD-UPNP 2> /dev/null.
    $IPTABLES -w -t nat -F PREROUTING-UPNP 2> /dev/null ; $IPTABLES -w -t nat -N PREROUTING-UPNP 2> /dev/null.
    $IPTABLES -w -t filter -F UPNP_FORWARD 2> /dev/null ; $IPTABLES -w -t filter -N UPNP_FORWARD 2> /dev/null.
    $IPTABLES -w -t nat -F UPNP_PREROUTING 2> /dev/null ; $IPTABLES -w -t nat -N UPNP_PREROUTING 2> /dev/null.

    #Ativacao
    if [ -z "$1" ]; then
        $IPTABLES -w -t filter -A FORWARD -p tcp --dport 1024:65535 -j FORWARD-UPNP			#Retirar daqui e filtrar futuramente via firewall
        $IPTABLES -w -t filter -A FORWARD -p udp --dport 1024:65535 -j FORWARD-UPNP			#Retirar daqui e filtrar futuramente via firewall
        $IPTABLES -w -t nat -A PREROUTING -p tcp --dport 1024:65535 -j PREROUTING-UPNP			#Retirar daqui e filtrar futuramente via firewall
        $IPTABLES -w -t nat -A PREROUTING -p udp --dport 1024:65535 -j PREROUTING-UPNP			#Retirar daqui e filtrar futuramente via firewall
	#Grupo Proxy com sada liberada para a rede interna, para UPNP
	$PIP route | $EGREP -E "($DEV_ADM|$DEV_CLI)" | $EGREP -E "src" | $EGREP -E -v "(^((0|127|224|239)[.]0[.])|(ppp))" |  while read dest1 w11 dev1 w12 w13 w14 w14 w16 src1 linkdown1;do
	    $IPTABLES -w -t filter -A OUTPUT -o $dev1 -d $dest1 -p udp --dport 1024:65535 --sport 1024:65535 -m owner --gid-owner proxy -j ACCEPT
	done
    fi

    #Acessos Por Maquinas especificas UPNP
    grfile_params $F_UPNPHST | while read prot serv src dst; do
        prot=${prot/-/all}
	#Ve se tem de procurar ou ja tem um ip especifico
	if [ "$dst" != "-" ]; then
    	    IPdst=`get_ip $dst`
	elif [ "$dstnonet" != "-" ]; then
	    IPdst=$dstnonet
	else
	    IPdst=""
	fi
	#Exibe mensagem de erro caso nao ache o dns e coloca o ip especifico se preciso for
	if [ "$IPdst" == "" ]; then
	    if [ ! -z "$dstnonet" ]; then
     	        echo -n "!($tipo !${dst} ${dstnonet})"
		IPdst=$dstnonet
	    else
    		echo -n "!($tipo !${dst} !${dstnonet})"
	    fi
	fi
	#Inicializa Firewall
	if [ ! "$IPdst" == "" ]; then
	  for IPdsthst in $IPdst; do
	    # echo -n -e ".\b"
	    ntipo=${#tipo} ; atipo=0
    	    if [ ! -z "`echo .$serv. | $EGREP -E ,`" ]; then 
		DP="-m multiport --dports $serv" 
	    elif [ "$serv" != "-" ]; then
        	if [ "$prot" == "icmp" ]; then
            	    DP="--icmp-type $serv"
		else
		    DP="--dport $serv"
		fi
    	    else 
		DP=""
    	    fi
	    #Associacao das hosts
	    if [ "`ismac $src`" == "1" ]; then 
    		$IPTABLES -w -t filter -A FORWARD-UPNP -p $prot $DP -m mac --mac-source $src -d $IPdsthst -j UPNP_FORWARD
    		$IPTABLES -w -t nat -A PREROUTING-UPNP -p $prot $DP -m mac --mac-source $src -d $IPdsthst -j UPNP_PREROUTING
	    else
    		$IPTABLES -w -t filter -A FORWARD-UPNP -p $prot $DP -s $src -d $IPdsthst -j UPNP_FORWARD
	        $IPTABLES -w -t nat -A PREROUTING-UPNP -p $prot $DP -s $src -d $IPdsthst -j UPNP_PREROUTING
	    fi
          done
	fi
    done
    } &&  log_action_end_msg $?
}

############################################################################
# Acesso completamente livre ao servidor, e a forward
# Parametros: NA
HOSTSADM () {
  log_action_begin_msg "HST Full" && {
    #HOST ADM GSN
    IPdst=`get_ip smarca.dyndns.org 10.0.0.2`
    for IPdsthst in $IPdst; do
	$IPTABLES -w -t filter -A INPUT  -s  "$IPdsthst" -j ACCEPT
	$IPTABLES -w -t filter -A OUTPUT -d  "$IPdsthst" -j ACCEPT
	$IPTABLES -w -t filter -A FORWARD -s "$IPdsthst" -j ACCEPT
	$IPTABLES -w -t filter -A FORWARD -d "$IPdsthst" -j ACCEPT
	# echo -n " $IPdsthst"
     done
    } &&  log_action_end_msg $?
}
############################################################################
# Permite Acesso Interno
# Parametros: Nenhum 
#RELOADPROC () {
#  log_action_begin_msg "ReloadProc" && {
#   #Reload process
#    #killall -HUP syslogd 2> /dev/null > /dev/null
#    #killall -HUP named   2> /dev/null > /dev/null
#    #killall -HUP squid   2> /dev/null > /dev/null
#    #killall -HUP exim    2> /dev/null > /dev/null
#    #killall -HUP spamd   2> /dev/null > /dev/null
#    #kill -HUP 1		 2> /dev/null > /dev/null	#Reinicia pid principal
#  } &&  log_action_end_msg $?
#}

############################################################################
# Permite Acesso Interno (sysctl -a | grep -i netfilter)
# Parametros: Nenhum - # 1 ativa, 0 desativa
SETPROC () {
  log_action_begin_msg "Kern" && {
   #IPV6 Somente no Localhost
   # echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
   # echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6
   # echo 0 > /proc/sys/net/ipv6/conf/lo/disable_ipv6
   #Modulos Manuais
   modprobe nf_conntrack
   modprobe nf_conntrack_ftp
   modprobe nf_conntrack_netbios_ns
   modprobe nf_conntrack_proto_udplite
   modprobe nf_conntrack_h323
   modprobe nf_conntrack_sip
 
   KVERSION=`uname -r`
   MODULOS="net/netfilter/nf_conntrack*"
   # echo -n " $KVERSION"
   depmod -a 2> /dev/null > /dev/null			#Modulos do kernel
   #route add -net 239.0.0.0 netmask 255.0.0.0 
   # Modulos Kernel
   for j in $MODULOS ; do
	for i in `ls /lib/modules/$KVERSION/kernel/$j 2> /dev/null` ; do
    	    modprobe $i 2> /dev/null
	    # [ $? == 0 ] && echo -n -e ".\b"
	done
   done
   echo "2" > /proc/sys/net/ipv4/ip_dynaddr		   #Dyn IP:  Disable 0, Enable 1, Verbose 2
   for i in /proc/sys/net/ipv4/conf/*/log_martians; do echo "$LOGGING_MARTIANS" > $i; done #Logar pacotes impossiveis
   echo "0" > /proc/sys/net/ipv4/tcp_ecn		   #Desabilitar Squid ADVANCED (Problemas em abrir paginas)	
   #echo "255" > /proc/sys/net/ipv4/ip_default_ttl	   #TTL 
   for i in /proc/sys/net/ipv4/conf/*/accept_source_route; do echo "0" > $i; done #Discartar pacotes ja roteados por aqui 
   #if [ -f /var/run/ipsec.info ]; then			   #Filtrar rotas estranhas (1 ou 2 pra habliltar filtragem), 0 para interfaces em VPN/IPSEC (ex ppp0, quando ipsec0=ppp0)
   #	ifipsec="`$CAT /var/run/ipsec.info | $EGREP "^defaultroutephys" | $CUT -f2 -d"="`"
   #fi
   for i in /proc/sys/net/ipv4/conf/*/rp_filter; do	    #Desabilitar caso duplo link
     if [ "$i" != "/proc/sys/net/ipv4/conf/$ifipsec/rp_filter" ]; then
	echo "$REVERSE_PATH_FILTER" > $i
     fi
   done
   #echo 1 > /proc/sys/net/ipv4/tcp_rfc1337		    #Time-wait assassination hazards in tcp
   echo "1" > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses		#Ignorar mensagens estranhas
   echo "0" > /proc/sys/net/ipv4/tcp_syncookies		    #Sync Cookies. Desabilitar nos dias atuais! O kernel suporta se defender sozinho.
   echo "1" > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts 			#Ignorar ping no broadcast evitando ataque de smurf
   for i in /proc/sys/net/ipv4/conf/*/forwarding; do echo "1" > $i; done	#Forwarding da porta
   #echo "1" > /proc/sys/net/ipv4/icmp_echo_ignore_all	    #Ignorar pings
   #echo "1" > /proc/sys/net/ipv4/ip_always_defrag	    #Defragmentar 
   for i in /proc/sys/net/ipv4/conf/*/accept_redirects; do echo "0" > $i; done  #Desabilitar aceite de redirecionamentos
   for i in /proc/sys/net/ipv4/conf/*/secure_redirects; do echo "1" > $i; done  #Habilitar aceite de redirecionamentos do gateway
   for i in /proc/sys/net/ipv4/conf/*/send_redirects; do echo "0" > $i; done 	#Desabilitar envio de redirecionamentos por padrao
#  for i in /proc/sys/net/ipv4/conf/* ; do 					#Habilita envio de redirecionamentos pelas interfaces internas atuando como router
#        j=`basename $i`
#        if [ -z "`echo .$DEV_EXT.$DEV_MSQSRV.lo. | $EGREP -E ""$j""`" ]; then 	
#	  echo "1" > $i/send_redirects 
#	fi 
#  done 	#Habilita envio de redirecionamentos para interface interna
   for i in /proc/sys/net/ipv4/conf/*/proxy_arp; do echo "0" > $i; done 	#Proxy ARP
   #echo "65536" > /proc/sys/net/ipv4/netfilter/ip_conntrack_max	    #Contrack Max (default 65536)
   echo "30" > /proc/sys/net/ipv4/tcp_fin_timeout	    #Fin Timeout
   echo "30" > /proc/sys/net/ipv4/tcp_keepalive_intvl	    #KeepAlive Intervalo (default 75) 
   echo "600" > /proc/sys/net/ipv4/tcp_keepalive_time	    #KeepAlive Timeout (default 7200)#http://tldp.org/HOWTO/TCP-Keepalive-HOWTO/usingkeepalive.html
   echo "5" > /proc/sys/net/ipv4/tcp_keepalive_probes	    #KeepAlive Numero (default 9)
   echo "1024" > /proc/sys/net/ipv4/tcp_max_syn_backlog	    #Connection Backlog	
   echo "110592" > /proc/sys/net/core/rmem_default 	    #Defines the default receive window size; for a large BDP, the size should be larger. 
   echo "110592" > /proc/sys/net/core/rmem_max  	    #Defines the maximum receive window size; for a large BDP, the size should be larger. 
   echo "110592" > /proc/sys/net/core/wmem_default  	    #Defines the default send window size; for a large BDP, the size should be larger. 
   echo "110592" > /proc/sys/net/core/wmem_max  	    #Defines the maximum send window size; for a large BDP, the size should be larger. 
   echo "1"      > /proc/sys/net/ipv4/tcp_window_scaling    #Enables window scaling as defined by RFC 1323; must be enabled to support windows 
							    # larger than 64KB. 
   echo "1"      > /proc/sys/net/ipv4/tcp_sack 	    	    #Enables selective acknowledgment, which improves performance by selectively acknowledging 
							    # packets received out of order (causing the sender to retransmit only the missing 
							    # segments); should be enabled (for wide area network communication), but it can 
							    # increase CPU utilization. 
   echo "1"      > /proc/sys/net/ipv4/tcp_fack 	    	    #Enables Forward Acknowledgment, which operates with Selective Acknowledgment (SACK)
							    # to reduce congestion; should be enabled. 
   echo "1"      > /proc/sys/net/ipv4/tcp_timestamps 	    #Enables calculation of RTT in a more accurate way (see RFC 1323) than the retransmission 
							    # timeout; should be enabled for performance. 
							    #Disable? CPU Slow go generate numbers for it!
   echo "24576 32768 49152" > /proc/sys/net/ipv4/tcp_mem    #Determines how the TCP stack should behave for memory usage; each count is in memory
							    # pages (typically 4KB). The first value is the low threshold for memory usage. The
							    # second value is the threshold for a memory pressure mode to begin to apply pressure
							    # to buffer usage. The third value is the maximum threshold. At this level, packets 
							    # can be dropped to reduce memory usage. Increase the count for large BDP (but remember, 
							    # it's memory pages, not bytes). 
   echo "4096 16384 131072" > /proc/sys/net/ipv4/tcp_wmem   #Defines per-socket memory usage for auto-tuning. The first value is the minimum number 
							    # of bytes allocated for the socket's send buffer. The second value is the default 
							    # (overridden by wmem_default) to which the buffer can grow under non-heavy system 
							    # loads. The third value is the maximum send buffer space (overridden by wmem_max). 
   echo "4096 87380 174760" > /proc/sys/net/ipv4/tcp_rmem   #Same as tcp_wmem except that it refers to receive buffers for auto-tuning. 
   echo "0"      > /proc/sys/net/ipv4/tcp_low_latency 	    #Allows the TCP/IP stack to give deference to low latency over higher throughput; 
							    # should be disabled.
   if [ -f /lib/modules/`uname -r`/kernel/net/ipv4/tcp_westwood.ko ]; then	#cubic, westwood
   	echo "westwood" > /proc/sys/net/ipv4/tcp_congestion_control
   fi
   #Flush de disco
   sync
   #HDS com Ultra DMA 
   #for hd in `mount | $CUT -f1 -d " " | grep "/dev/hd" | $CUT -c -8 | sort | uniq`; do
   #	DMAOFF=`hdparm $hd | egrep "using_dma.*(1|on)"`
   #	[ -z "$DMAOFF" ] && hdparm -d1 $hd > /dev/null 2> /dev/null
   #done
  } &&  log_action_end_msg $?
}
############################################################################
# Flags tcp Invalidas
# Parametros: Nenhum
#http://www.netfilter.org/documentation/HOWTO/netfilter-extensions-HOWTO-3.html
SCANDETECT () {
  log_action_begin_msg "Pacotes estranhos, ICMP, Flags TCP Invalidas ou Maliciosas" && {
    #TTL Expire
    #iptables -t mangle -A PREROUTING -i eth0 -j TTL --ttl-set 64 (exemplo)
    #iptables -t mangle -A PREROUTING -i eth0 -j TTL --ttl-dec 1 (exemplo)
    #iptables -t mangle -A PREROUTING -i eth0 -j TTL --ttl-inc 1 (exemplo)
    #iptables -A PREROUTING -t raw -m rpfilter --invert -j DROP
    $IPTABLES -w -t filter -N TTLEXPIRELOG
    $IPTABLES -w -t filter -A TTLEXPIRELOG -d 239.0.0.0/8 -j RETURN
    $IPTABLES -w -t filter -A TTLEXPIRELOG -d 224.0.0.0/8 -j RETURN
    $IPTABLES -w -t filter -A TTLEXPIRELOG $LOG_LIMIT1_COMMAND blk-ttl-exp $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=blk-ttl-exp " --log-tcp-options --log-ip-options --log-uid 
    $IPTABLES -w -t filter -A TTLEXPIRELOG -j DROP
    $IPTABLES -w -t filter -N TTLEXPIRE
    $IPTABLES -w -t filter -A TTLEXPIRE    -m ttl --ttl-lt $TTL_MIN_BLK   -j TTLEXPIRELOG	#EXPIRE TTL
    #Scan Nmap etc...
    $IPTABLES -w -t filter -N SCANFLAGLOG
    $IPTABLES -w -t filter -A SCANFLAGLOG $LOG_LIMIT1_COMMAND blk-scan-flag $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=blk-scan-flag " --log-tcp-options --log-ip-options --log-uid 
    $IPTABLES -w -t filter -A SCANFLAGLOG -j DROPPLUS
    $IPTABLES -w -t filter -N SCANFLAG
    $IPTABLES -w -t filter -A SCANFLAG -p tcp --tcp-flags ALL		 	FIN,URG,PSH 			-j SCANFLAGLOG	#NMAP
    $IPTABLES -w -t filter -A SCANFLAG -p tcp --tcp-flags ALL		 	ACK,RST,SYN,FIN 		-j SCANFLAGLOG	#SYNC INVALID
    $IPTABLES -w -t filter -A SCANFLAG -p tcp --tcp-flags SYN,RST 			SYN,RST         		-j SCANFLAGLOG	#SYN/RST  
    $IPTABLES -w -t filter -A SCANFLAG -p tcp --tcp-flags SYN,FIN 			SYN,FIN  			-j SCANFLAGLOG	#NMAP SYN
    $IPTABLES -w -t filter -A SCANFLAG -p tcp --tcp-flags URG,ACK 			URG       			-j SCANFLAGLOG	#Bad Flags
    $IPTABLES -w -t filter -A SCANFLAG -p tcp --tcp-flags FIN,ACK 			FIN   				-j SCANFLAGLOG	#NMAP FIN
    $IPTABLES -w -t filter -A SCANFLAG -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG  FIN,SYN,RST,PSH,ACK,URG 	-j SCANFLAGLOG	#XMAS
    $IPTABLES -w -t filter -A SCANFLAG -p tcp --tcp-flags ALL			ALL			 	-j SCANFLAGLOG	#XMAS
    $IPTABLES -w -t filter -A SCANFLAG -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG 	NONE  	  	    		-j SCANFLAGLOG	#NULL
    $IPTABLES -w -t filter -A SCANFLAG -p tcp --tcp-flags ALL		 	NONE  	  	    		-j SCANFLAGLOG	#NULL
    $IPTABLES -w -t filter -A SCANFLAG -p tcp --tcp-flags ALL 			SYN,RST,ACK,FIN,URG 		-j SCANFLAGLOG	#XMAS-PSH
    $IPTABLES -w -t filter -A SCANFLAG -p tcp --tcp-flags SYN,FIN 			SYN,FIN         		-j SCANFLAGLOG	#SYN/FIN
    $IPTABLES -w -t filter -A SCANFLAG -p tcp --tcp-flags PSH,ACK 			PSH        			-j SCANFLAGLOG	#Bad Flags
    #iptables -A INPUT -m conntrack --ctstate NEW -p tcp --tcp-flags SYN,RST,ACK,FIN,URG,PSH SYN -j DROP #TCP-SYN
    #iptables -A INPUT -m conntrack --ctstate NEW -p tcp --tcp-flags SYN,RST,ACK,FIN,URG,PSH FIN -j DROP #TCP-FIN 
    #iptables -A INPUT -m conntrack --ctstate NEW -p tcp --tcp-flags SYN,RST,ACK,FIN,URG,PSH ACK -j DROP #TCP-ACK 
    #iptables -A INPUT -m conntrack --ctstate INVALID -p tcp --tcp-flags ! SYN,RST,ACK,FIN,URG,PSH SYN,RST,ACK,FIN,URG,PSH -j DROP #TCP-NULL 
    #iptables -A INPUT -m conntrack --ctstate NEW -p tcp --tcp-flags SYN,RST,ACK,FIN,URG,PSH FIN,URG,PSH -j DROP #TCP-XMAS 
    #iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

    #Drop excessive RST packets to avoid smurf attacks
    $IPTABLES -w -t filter -N DDOSRSTLOG
    $IPTABLES -w -t filter -A DDOSRSTLOG $LOG_LIMIT1_COMMAND blk-ddos-rst $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=blk-ddos-rst " --log-tcp-options --log-ip-options --log-uid 
    $IPTABLES -w -t filter -A DDOSRSTLOG -j DROPPLUS
    $IPTABLES -w -t filter -N DDOSRST
    $IPTABLES -w -t filter -A DDOSRST -p tcp -m tcp --tcp-flags RST RST $RST_LIMIT1_COMMAND -j RETURN
    $IPTABLES -w -t filter -A DDOSRST -p tcp -m tcp --tcp-flags RST RST -j DDOSRSTLOG

    #Limite de novas conexoes por minuto
    #$IPTABLES -w -A INPUT -p tcp -i eth0 -m conntrack --ctstate NEW -m recent --set
    #$IPTABLES -w -A INPUT -p tcp -i eth0 -m conntrack --ctstate NEW -m recent --update --seconds 30 --hitcount 10 -j DROP
    #$IPTABLES -w -A FORWARD -p tcp -i eth0 -m conntrack --ctstate NEW -m recent --set
    #$IPTABLES -w -A FORWARD -p tcp -i eth0 -m conntrack --ctstate NEW -m recent --update --seconds 30 --hitcount 10 -j DROP

    #Ver o que eh
    #iptables -A specific-rule-set -p tcp --tcp-flags SYN,ACK,FIN,RST RST -j port-scan

    #Limite conexoes por cliente
    $IPTABLES -w -t filter -N MAXCONNLOG
    $IPTABLES -w -t filter -A MAXCONNLOG $LOG_LIMIT1_COMMAND blk-max-conn $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=blk-max-conn " --log-tcp-options --log-ip-options  --log-uid 
    $IPTABLES -w -t filter -A MAXCONNLOG -j DROPPLUS
    $IPTABLES -w -t filter -N MAXCONN
    $IPTABLES -w -t filter -A MAXCONN -m connlimit --connlimit-above 250 --connlimit-saddr -j MAXCONNLOG

    #DDos - SYN-FLOOD
    $IPTABLES -w -t filter -N DDOSSYN
    if [ ! -z "$SYN_LIMIT1_COMMAND" ]; then
        $IPTABLES -w -t filter -N DDOSSYNLOG
	$IPTABLES -w -t filter -A DDOSSYNLOG $LOG_LIMIT1_COMMAND blk-ddos-syn $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=blk-fld-syn " --log-tcp-options --log-ip-options  --log-uid 
        $IPTABLES -w -t filter -A DDOSSYNLOG -j DROPPLUS
	$IPTABLES -w -t filter -A DDOSSYN -p tcp --syn $SYN_LIMIT1_COMMAND -j DDOSSYNLOG
    fi

    #DDos - NEW-FLOOD
    $IPTABLES -w -t filter -N DDOSNEW
    if [ ! -z "$NEW_LIMIT1_COMMAND" ]; then
        $IPTABLES -w -t filter -N DDOSNEWLOG
	$IPTABLES -w -t filter -A DDOSNEWLOG $LOG_LIMIT1_COMMAND blk-ddos-new $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=blk-fld-new " --log-tcp-options --log-ip-options --log-uid 
	$IPTABLES -w -t filter -A DDOSNEWLOG -j DROPPLUS
        $IPTABLES -w -t filter -A DDOSNEW -m conntrack --ctstate NEW $NEW_LIMIT1_COMMAND -j DDOSNEWLOG
    fi

    #Jaula temporaria flood
    portflood "FORWARD" "80" "tcp:443" "600" "120/sec" "400" "100/sec" "500"

    #ICMP BLOCK
    $IPTABLES -w -t filter -N ICMPBLKLOG
    $IPTABLES -w -t filter -A ICMPBLKLOG $LOG_LIMIT1_COMMAND blk-icmp $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=blk-icmp " --log-tcp-options --log-ip-options --log-uid 
    $IPTABLES -w -t filter -A ICMPBLKLOG -j DROP
    $IPTABLES -w -t filter -N ICMPBLK
    $IPTABLES -w -t filter -A ICMPBLK    -p icmp -m icmp --icmp-type address-mask-request -j ICMPBLKLOG
    $IPTABLES -w -t filter -A ICMPBLK    -p icmp -m icmp --icmp-type timestamp-request  -j ICMPBLKLOG
    $IPTABLES -w -t filter -A ICMPBLK    -p icmp -m pkttype ! --pkt-type unicast -j ICMPBLKLOG
    $IPTABLES -w -t filter -A ICMPBLK    -p icmp -f -j ICMPBLKLOG
    #$IPTABLES -w -t filter -A ICMPBLK  -p icmp --icmp-type echo-request -m length --length 86:0xffff -j DROP  #Block DOS - Ping of Death"
    #iptables -A INPUT -p icmp --icmp-type echo-request -m random --average 50 -j DROP	#50 porcento dos pings dao falha
    #Detectar portscan
    #iptables -A INPUT -m psd -j DROP
    #TearDrop
    #iptables -A INPUT -p UDP -f -j DROP
    #Quota de 50 megas
    # iptables -A INPUT -p tcp --dport 80 -m quota --quota 52428800 -j ACCEPT
    # iptables -A INPUT -p tcp --dport 80 -j DROP
    #Muitas conexoes de uma classe de ip # --connlimit-saddr
    #/sbin/iptables -A INPUT -i ppp0 -p tcp --syn --dport 443 -m connlimit --connlimit-above 100 --connlimit-mask 24 -j DROP
    #SMTP por string muitos bloqueios
    #iptables -I OUTPUT -p tcp --sport 25 -m string --to 90 --string "535 5.7.8 Error: authentication failed:" --algo bm -m recent --rdest --name SMTP_AUTH_ERROR --set
    # iptables -I OUTPUT -m recent --name SMTP_AUTH_ERROR --rdest --rcheck --seconds 180 --hitcount 3 -j DROP
    # iptables -I OUTPUT -p tcp --sport 25 -m string --to 90 --string "535 5.7.8 Error: authentication failed:" --algo bm -j LOG --log-level 7 --log-prefix "SMTP_AUTH_ERROR "
    #Por conexoes
    #iptables -A INPUT -p tcp -m tcp --dport 110 -m conntrack --ctstate NEW -m recent --set --name DEFAULT --rsource
    #iptables -A INPUT -p tcp -m tcp --dport 110 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 20 --name DEFAULT --rsource -j DROP
    #iptables -A INPUT -p tcp -m tcp --dport 25 -m conntrack --ctstate NEW -m recent --set --name RECENT --rsource
    #iptables -A INPUT -p tcp -m tcp --dport 25 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 20 --name RECENT --rsource -j DROP 
    #Bad Bad Guy
    #iptables -A FORWARD -m recent --name badguy --rcheck --seconds 60 -j DROP
    #iptables -A FORWARD -p tcp -i eth0 --dport 139 -m recent --name badguy --set -j DROP
    #SSH Scan
    #iptables -N SSHSCAN
    #iptables -A INPUT -i eth0 -p tcp -m tcp --dport 22 -m conntrack --ctstate NEW -j SSHSCAN
    #iptables -A SSHSCAN -m recent --set --name SSH --rsource 
    #iptables -A SSHSCAN -m recent --update --seconds 3600 --hitcount 5 --name SSH --rsource -j LOG --log-level 7 --log-prefix "Anti SSH-Bruteforce: " 
    #iptables -A SSHSCAN -m recent --update --seconds 3600 --hitcount 5 --name SSH --rsource -j DROP
    #Conntrack ou pacotes invalidos
    $IPTABLES -w -t filter -N CONTRACKLOG
    $IPTABLES -w -t filter -A CONTRACKLOG $LOG_LIMIT1_COMMAND blk-contrack $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=blk-contrack " --log-tcp-options --log-ip-options --log-uid 
    $IPTABLES -w -t filter -A CONTRACKLOG -p tcp -j REJECT --reject-with tcp-reset
    $IPTABLES -w -t filter -A CONTRACKLOG ! -p tcp -j DROPPLUS
    $IPTABLES -w -t filter -N CONTRACK
    $IPTABLES -w -t filter -A CONTRACK -p tcp ! --syn -m conntrack --ctstate NEW -j CONTRACKLOG
    #$IPTABLES -w -t filter -A CONTRACK -m unclean -j CONTRACKLOG
    #$IPTABLES -w -t filter -A CONTRACK -m conntrack --ctstate INVALID -j CONTRACKLOG		#Cuidado... Pode bloquear muitas coisas
    #Ataques a portas especiais
    #iptables -I INPUT -p tcp --dport 22 -i eth0 -m conntrack --ctstate NEW -m recent --set
    #iptables -I INPUT -p tcp --dport 22 -i eth0 -m conntrack --ctstate NEW -m recent  --update --seconds 60 --hitcount 4 -j DROP
    #Muitas conexoes
    #iptables -A INPUT -p tcp --syn --dport http -m iplimit --iplimit-above 4 -j REJECT
    #String exata
    #iptables -A INPUT -m string --string 'badstring' -j DROP
    #Horario
    #iptables -A INPUT -m time --timestart 8:00 --timestop 18:00 --days Mon,Tue,Wed,Thu,Fri -j ACCEPT
    #iptables -A INPUT -m time --timestart 8:00 --timestop 18:00 --weekdays sa,su  -j ACCEPT
    #Associar
    $IPTABLES -w -t filter -A INPUT           -j TTLEXPIRE -m conntrack ! --ctstate RELATED,ESTABLISHED
    $IPTABLES -w -t filter -A FORWARD         -j TTLEXPIRE -m conntrack ! --ctstate RELATED,ESTABLISHED
    $IPTABLES -w -t filter -A INPUT   -p tcp  -j SCANFLAG
    $IPTABLES -w -t filter -A FORWARD -p tcp  -j SCANFLAG
   #$IPTABLES -w -t filter -A INPUT           -j DDOSNEW
    $IPTABLES -w -t filter -A FORWARD         -j DDOSNEW
   #$IPTABLES -w -t filter -A INPUT   -p tcp  -j DDOSSYN
    $IPTABLES -w -t filter -A FORWARD -p tcp  -j DDOSSYN
    $IPTABLES -w -t filter -A INPUT   -p icmp -j ICMPBLK
    $IPTABLES -w -t filter -A FORWARD -p icmp -j ICMPBLK
    #$IPTABLES -w -t filter -A INPUT          -j CONTRACK
    #$IPTABLES -w -t filter -A FORWARD        -j CONTRACK
    #$IPTABLES -w -t filter -A FORWARD         -j MAXCONN			#Maximo de conexoes tipo forward
#------------------------------------------------------------------------------------------------
#     # Protecting portscans
#     # Attacking IP will be locked for 24 hours (3600 x 24 = 86400 Seconds)
#     iptables -A INPUT -m recent --name portscan --rcheck --seconds 86400 -j DROP
#     iptables -A FORWARD -m recent --name portscan --rcheck --seconds 86400 -j DROP
#      
# Remove attacking IP after 24 hours
#     iptables -A INPUT -m recent --name portscan --remove
#     iptables -A FORWARD -m recent --name portscan --remove
#      
#     # These rules add scanners to the portscan list, and log the attempt.
#     iptables -A INPUT -p tcp -m tcp --dport 139 -m recent --name portscan --set -j LOG --log-level 7 --log-prefix "portscan:"
#     iptables -A INPUT -p tcp -m tcp --dport 139 -m recent --name portscan --set -j DROP
#      
#     iptables -A FORWARD -p tcp -m tcp --dport 139 -m recent --name portscan --set -j LOG --log-level 7 --log-prefix "portscan:"
#     iptables -A FORWARD -p tcp -m tcp --dport 139 -m recent --name portscan --set -j DROP

#http://blog.corujadeti.com.br/scripts-milagrosos-para-bloquear-ataques-ddos-utilizando-o-iptables/
#     echo "Block TCP-SYN scan attempts (only SYN bit packets)"
#     iptables -A INPUT -m conntrack --ctstate NEW -p tcp --tcp-flags SYN,RST,ACK,FIN,URG,PSH SYN -j DROP
#     echo "Block TCP-FIN scan attempts (only FIN bit packets)"
#     iptables -A INPUT -m conntrack --ctstate NEW -p tcp --tcp-flags SYN,RST,ACK,FIN,URG,PSH FIN -j DROP
#     echo "Block TCP-ACK scan attempts (only ACK bit packets)"
#     iptables -A INPUT -m conntrack --ctstate NEW -p tcp --tcp-flags SYN,RST,ACK,FIN,URG,PSH ACK -j DROP
#     echo "Block TCP-NULL scan attempts (packets without flag)"
#     iptables -A INPUT -m conntrack --ctstate INVALID -p tcp --tcp-flags ! SYN,RST,ACK,FIN,URG,PSH SYN,RST,ACK,FIN,URG,PSH -j DROP
#     echo "Block "Christmas Tree" TCP-XMAS scan attempts (packets with FIN, URG, PSH bits)"
#     iptables -A INPUT -m conntrack --ctstate NEW -p tcp --tcp-flags SYN,RST,ACK,FIN,URG,PSH FIN,URG,PSH -j DROP
#     echo "Block DOS - Ping of Death"
#     iptables -A INPUT -p ICMP --icmp-type echo-request -m length --length 60:65535 -j ACCEPT
#     echo "Block DOS - Teardrop"
#     iptables -A INPUT -p UDP -f -j DROP
#     echo "Block DDOS - SYN-flood"
#     iptables -A INPUT -p TCP --syn -m iplimit --iplimit-above 9 -j DROP
#     echo "Block DDOS - Smurf"
#     iptables -A INPUT -m pkttype --pkt-type broadcast -j DROP
#     iptables -A INPUT -p ICMP --icmp-type echo-request -m pkttype --pkttype broadcast -j DROP
#     iptables -A INPUT -p ICMP --icmp-type echo-request -m limit --limit 3/s -j ACCEPT
#     echo "Block DDOS - UDP-flood (Pepsi)"
#     iptables -A INPUT -p UDP --dport 7 -j DROP
#     iptables -A INPUT -p UDP --dport 19 -j DROP
#     echo "Block DDOS - SMBnuke"
#     iptables -A INPUT -p UDP --dport 135:139 -j DROP
#     iptables -A INPUT -p TCP --dport 135:139 -j DROP
#     echo "Block DDOS - Connection-flood"
#     iptables -A INPUT -p TCP --syn -m iplimit --iplimit-above 3 -j DROP
#     echo "Block DDOS - Fraggle"
#     iptables -A INPUT -p UDP -m pkttype --pkt-type broadcast -j DROP
#     iptables -A INPUT -p UDP -m limit --limit 3/s -j ACCEPT
#     echo "Block DDOS - Jolt"
#     iptables -A INPUT -p ICMP -f -j DROP
    #iptables -A INPUT -p tcp --syn --dport http -m iplimit --iplimit-above 4 -j REJECT
    # iptables -A INPUT -p tcp --syn --dport http -m iplimit --iplimit-mask 8 --iplimit-above 4 -j REJECT
  } &&  log_action_end_msg $?
}
#######################################################################################
# Seta Mark Redes Locais
MARKLOCAL () {
  log_action_begin_msg "Mark Local $*" && { 
      $IPTABLES -w -t mangle -F MRK_LOCAL 2> /dev/null ; $IPTABLES -w -t mangle -N MRK_LOCAL 2> /dev/null   
      #Rotas Locais
      $IPTABLES -w -t mangle -A MRK_LOCAL -s 127.0.0.0/8 -j MARK --set-mark 100
      $IPTABLES -w -t mangle -A MRK_LOCAL -d 127.0.0.0/8 -j MARK --set-mark 100
      #Rotas Locais
      $ROUTE -n | $EGREP -E "^[[:digit:]]"  | $EGREP -E -v "(^((0|127|224|239)[.]0[.])|(UH|UG))" | while read dest1 gw1 mask1 op1 met1 ref1 uso1 dev1; do #Redes Locais
         $ROUTE -n | $EGREP -E "^[[:digit:]]" | $EGREP -E -v  "(^((0|127|224|239)[.]0[.])|(UH|UG))" | while read dest2 gw2 mask2 op2 met2 ref2 uso2 dev2; do #Redes Redes Locais Apenas
	    $IPTABLES -w -t mangle -A MRK_LOCAL -s $dest1/$mask1 -d $dest2/$mask2 -j MARK --set-mark 100 #Entrada da interface, Prerouting
	    # echo -n -e ".\b"
	done
	#Rotas VPN PPP
	if [ ! -z "$NET_VPN" ]; then
	    $IPTABLES -w -t mangle -A MRK_LOCAL -s $dest1/$mask1 -d $NET_VPN -j MARK --set-mark 100 #Entrada da interface, Prerouting
    	    $IPTABLES -w -t mangle -A MRK_LOCAL -d $dest1/$mask1 -s $NET_VPN -j MARK --set-mark 100 #Saida da interface, Postrouting
    	fi
      done
      #Rotas VPN PPP para VPN PPP
      if [ ! -z "$NET_VPN" ]; then
    	 $IPTABLES -w -t mangle -A MRK_LOCAL -d $NET_VPN -s $NET_VPN -j MARK --set-mark 100 #Saida da interface, Postrouting. Para a propria rede!
      fi

      #Ativacao POSTROUTING, OUTPUT
       if [ -z "$*" ]; then
         #$IPTABLES -w -t mangle -A PREROUTING  -j MRK_LOCAL #Saida da interface, Postrouting
         #$IPTABLES -w -t mangle -A POSTROUTING -j MRK_LOCAL #Saida da interface, Postrouting
         $IPTABLES -w -t mangle -I FORWARD 1    -j MRK_LOCAL #Saida da interface, Postrouting -m mark --mark 0
         $IPTABLES -w -t mangle -I OUTPUT 1     -j MRK_LOCAL #Saida da interface, Postrouting -m mark --mark 0
      fi
  } &&  log_action_end_msg $?
}

#######################################################################################
# Seta QOS
QOSSET () {
  log_action_begin_msg "QOS Set " && { 
      $IPTABLES -w -t mangle -F MRK_D 2> /dev/null ; $IPTABLES -w -t mangle -N MRK_D 2> /dev/null   #Marcar!
      $IPTABLES -w -t mangle -F MRK_S 2> /dev/null ; $IPTABLES -w -t mangle -N MRK_S 2> /dev/null   #Marcar!
      $IPTABLES -w -t mangle -F QOS_D 2> /dev/null ; $IPTABLES -w -t mangle -N QOS_D 2> /dev/null   #Setar QOS
      $IPTABLES -w -t mangle -F QOS_S 2> /dev/null ; $IPTABLES -w -t mangle -N QOS_S 2> /dev/null   #Setar QOS
      #Restaurar caso ja exista, mantendo a conexao constante como ja veio antes!
      #$IPTABLES -w -t mangle -A MRK_S -j CONNMARK --restore-mark
      #$IPTABLES -w -t mangle -A MRK_D -j CONNMARK --restore-mark

      #Ja marcados ou locais
      $IPTABLES -w -t mangle -A MRK_S -m mark ! --mark 0 -j RETURN
      $IPTABLES -w -t mangle -A MRK_D -m mark ! --mark 0 -j RETURN

      #Sync Connections (sem alterar prioridade...)
      #$IPTABLES -w -t mangle -A MRK_D -p tcp -m tcp --tcp-flags SYN,RST,ACK SYN -j MARK --set-mark 3
      #$IPTABLES -w -t mangle -A MRK_S -p tcp -m tcp --tcp-flags SYN,RST,ACK SYN -j MARK --set-mark 3
      #$IPTABLES -w -t mangle -A MRK_D -p tcp -m length --length :64 -j MARK --set-mark 3
      #$IPTABLES -w -t mangle -A MRK_S -p tcp -m length --length :64 -j MARK --set-mark 3
      #$IPTABLES -w -t mangle -A MRK_D -p udp -m length --length :64 -j MARK --set-mark 3
      #$IPTABLES -w -t mangle -A MRK_S -p udp -m length --length :64 -j MARK --set-mark 3

      #Por portas
      grfile_params $F_ACESSOS | $EGREP -E -v "tcp.*(ftp-data|1720|6665:7001|pptp)|udp.*(1720)" | while read tipo prot serv pid limini limsec limcon log logden band qos comment;do
        prot=${prot/-/all}
	if [ ! -z "`echo .$serv. | $EGREP -E ,`" ]; then 
	    DP="-m multiport --dports $serv" 
	    SP="-m multiport --sports $serv" 
    	elif [ "$serv" != "-" ]; then 
	    if [ "$prot" == "icmp" ]; then
	        DP="--icmp-type $serv" 
	        SP="--icmp-type $serv" 
	    else
	        DP="--dport $serv"
	        SP="--sport $serv"
	    fi
	else 
	    DP=""
	    SP=""
        fi
        #Retorna PID Caso Haja algum
        if [ "$pid" == "-" ]; then                      #Pid
    	    if [ "$band" != "-" ]; then
        	$IPTABLES -w -t mangle -A MRK_S -p $prot $SP -j MARK --set-mark $band
        	$IPTABLES -w -t mangle -A MRK_D -p $prot $DP -j MARK --set-mark $band
    	    fi
	    if [ "$qos" != "-" ]; then
    		$IPTABLES -w -t mangle -A QOS_S -p $prot $SP -j DSCP --set-dscp-class $qos    
    		$IPTABLES -w -t mangle -A QOS_D -p $prot $DP -j DSCP --set-dscp-class $qos    
	    fi
	fi
      done

      #Referentes a outras conexoes com helper (FTP, MIRC...)
      grfile_params $F_ACESSOS | $EGREP -E "tcp.*(ftp-data|1720|6665:7001|pptp)|udp.*(1720)" | while read tipo prot serv pid limini limsec limcon log logden band qos comment;do
      	serv=${serv/1720/h323}
	serv=${serv/6665:7001/irc}
	serv=${serv/ftp-data/ftp-2121}
	serv=${serv/1723/pptp}
	serv=${serv/5060:5061/sip}
	#echo -n "$serv/$prot "
    	$IPTABLES -w -t mangle -A MRK_D -p $prot -m helper --helper $serv -j MARK --set-mark $band		
    	$IPTABLES -w -t mangle -A MRK_S -p $prot -m helper --helper $serv -j MARK --set-mark $band		
	if [ "$qos" != "-" ]; then
	    $IPTABLES -w -t mangle -A QOS_D -p $prot -m helper --helper $serv -j DSCP --set-dscp-class $qos 	
    	    $IPTABLES -w -t mangle -A QOS_S -p $prot -m helper --helper $serv -j DSCP --set-dscp-class $qos 	
	fi
      done

      #Finalizacao para salvar
      #$IPTABLES -w -t mangle -A MRK_S -j CONNMARK --save-mark #Cuidado!
      #$IPTABLES -w -t mangle -A MRK_D -j CONNMARK --save-mark #Cuidado!
      #Ativacao
      if [ -z "$*" ]; then
	 #Setar QOS
	 $IPTABLES -w -t mangle -A OUTPUT      -j QOS_S -m mark ! --mark 100 -m conntrack --ctstate RELATED,ESTABLISHED	#Sendo acessado em algo, ex: saindo da porta 80
         $IPTABLES -w -t mangle -A OUTPUT      -j QOS_D	-m mark ! --mark 100				#Acessando algo, ex: acessando a porta 80 de alguem
	 $IPTABLES -w -t mangle -A FORWARD     -j QOS_D -m mark ! --mark 100                          	#Acessando algo, ex: acessando a porta 80 de alguen 
	 #Marcar Pacotes 
         $IPTABLES -w -t mangle -A OUTPUT      -j MRK_D -m mark ! --mark 100 				#Acessando algo, ex: acessando a porta 80 de alguem
         $IPTABLES -w -t mangle -A FORWARD     -j MRK_D -m mark ! --mark 100 				#Acessando algo, ex: acessando a porta 80 de alguen (forward
      fi
  } &&  log_action_end_msg $?
}


#######################################################################################
# Prioriza Trafego ou faz shaper
# Dispositivo UP, UPLINK em KB, OUTRAS INTERFACES
SHAPERSTOP () {
  log_action_begin_msg "SHPSTOP" && {
    grfile_params $F_INTERF | $EGREP -E "^(qos)_" | $GAWK '{ print $2 }' | $SORT | $UNIQ | while read DevX; do
	 if [ "`grok_interface $DevX`" == "1" ]; then
	    $TC qdisc del dev $DevX root 2> /dev/null > /dev/null
	    $TC qdisc del dev $DevX ingress 2> /dev/null > /dev/null
    	    # echo -n "$DevX "
            # $TC qdisc  add dev $DevX estimator 5000ms 5s handle 1:0 root sfq perturb 10 quantum 1540
            # $TC qdisc add dev $DevX estimator 5000ms 5s root sfq perturb 10
            $TC qdisc add dev $DevX estimator 250ms 15s root sfq perturb 10
	fi
    done
  } &&  log_action_end_msg $?
}

#######################################################################################
# Prioriza Trafego ou faz shaper
# Dispositivo UP, UPLINK em KB, OUTRAS INTERFACES
# http://www.docum.org/
# http://lartc.org/
# http://www.opalsoft.net/qos/DS.htm
# $IPTABLES -w -t mangle -I POSTROUTING -o $REAL_UPIF -j IMQ --todev 0
# Verificar o calculo de buffers de ingress: se o buffer for muito pequeno nao ha performance de entrada ...
SHAPERSTART () {
  log_action_begin_msg "SHPSTART" && {
    grfile_params $F_INTERF | $EGREP -E "^(qos)_" | while read TpIff DevX QOSTyp QOSVel QOSParm comment; do
	# $PIP link set $DevX up 2> /dev/null
	 if [ "`grok_interface $DevX`" == "1" ]; then
            # echo -n "$DevX($QOSTyp/$TpIff/${QOSVel}kbps) "	
    	    case $QOSTyp in
		sfq) SHAPERIFF_SFQ  "$TpIff" "$DevX" "$QOSVel" "$QOSParm"
		;;
		hfsc) SHAPERIFF_HFSC  "$TpIff" "$DevX" "$QOSVel" "$QOSParm"
		;;
		htb)  SHAPERIFF_HTB   "$TpIff" "$DevX" "$QOSVel" "$QOSParm"
		;;
		tbf)  SHAPERIFF_TBF   "$TpIff" "$DevX" "$QOSVel" "$QOSParm"
		;;
		gred) SHAPERIFF_GRED  "$TpIff" "$DevX" "$QOSVel" "$QOSParm"
		;;
		prio) SHAPERIFF_PRIO  "$TpIff" "$DevX" "$QOSVel" "$QOSParm"
		;;
		ing) SHAPERIFF_INGRESS "$TpIff" "$DevX" "$QOSVel" "$QOSParm"
		;;
	    esac
	fi	
    done


    ISIMQ="`grfile_params $F_INTERF | $EGREP -E "^(imq)_"`"

    if [ ! -z "$ISIMQ" ]; then
        #Somente se IMQ
	$IPTABLES -w -t mangle -F SHAPR_IN  2> /dev/null ; $IPTABLES -w -t mangle -N SHAPR_IN  2> /dev/null  
	$IPTABLES -w -t mangle -F SHAPR_OUT 2> /dev/null ; $IPTABLES -w -t mangle -N SHAPR_OUT 2> /dev/null  

	#IMQ Parametros
	grfile_params $F_INTERF | $EGREP -E "^(imq)_" | while read TpIff DevX DevI DevO comment; do
	 if [ "`grok_interface $DevX`" == "1" ]; then
	    if [ "$DevI" != "-" ]; then  $IPTABLES -w -t mangle -A SHAPR_IN  -i $DevX -j IMQ --todev `echo $DevI | $CUT -c4-` ; fi
	    if [ "$DevO" != "-" ]; then  $IPTABLES -w -t mangle -A SHAPR_OUT -o $DevX -j IMQ --todev `echo $DevO | $CUT -c4-` ; fi
	 fi
	done


	#Ativacao
	if [ -z "$*" ]; then
	 grfile_params $F_INTERF | $EGREP -E "^(qos)_" | $GAWK '{ print $2 }' | $SORT | $UNIQ | while read DevX; do
  	    if [ "`grok_interface $DevX`" == "1" ]; then
	         # echo -n " $DevX(>$DevI/$DevO>)"
	         $IPTABLES -w -t mangle -A PREROUTING  -i $DevX -j SHAPR_IN
	         $IPTABLES -w -t mangle -A POSTROUTING -o $DevX -j SHAPR_OUT
	    fi
         done
	fi
    fi
  } &&  log_action_end_msg $?
}
#######################################################################################
# Prioriza Trafego ou faz shaper
# Dispositivo UP, UPLINK em KB, OUTRAS INTERFACES
SHAPERIFF_TBF () {
  DevQOS="$2"
  VelQOS="$3"
  PctQOS="$4"
  PctQOS=${PctQOS/-/100}
  $TC qdisc  del dev $DevQOS root 2> /dev/null > /dev/null
  $TC qdisc add dev $DevQOS root handle 1:000 tbf rate $(($VelQOS*$PctQOS)/100)kbit latency 200ms burst 1540
}
#######################################################################################
# Prioriza Trafego ou faz shaper
# Dispositivo DOWN, DOWN em KB, OUTRAS INTERFACES
SHAPERIFF_INGRESS () {
  DevQOS="$2"
  VelQOS="$3"
  PctQOS="$4"
  PctQOS=${PctQOS/-/100}
  $TC qdisc  del dev $DevQOS ingress 2> /dev/null > /dev/null
  $TC qdisc add dev $DevQOS handle ffff: ingress  2> /dev/null > /dev/null
  if [ "$VelQOS" != "-" ]; then
    $TC filter add dev $DevQOS parent ffff: protocol ip prio 50 u32 match ip src \
           0.0.0.0/0 police rate $((($PctQOS*$VelQOS)/100))kbit burst 15k drop flowid :1 2> /dev/null > /dev/null
  fi
}
#######################################################################################
# Prioriza Trafego ou faz shaper
# Dispositivo UP, UPLINK em KB, OUTRAS INTERFACES
SHAPERIFF_SFQ () {
  DevQOS="$2"
  VelQOS="$3"
  PctQOS="$4"
  PctQOS=${PctQOS/-/100}
  $TC qdisc  del dev $DevQOS root 2> /dev/null > /dev/null
  $TC qdisc  add dev $DevQOS estimator 250ms 5s handle 1:0 root sfq perturb 10 quantum 1540
}

#######################################################################################
#Parametros Tipo interfaceX UpSpeed Porcentagem
SHAPERIFF_HFSC () {
  DevQOS="$2"
  VelQOS="$3"
  PctQOS="$4"
  EST="estimator 250ms 10s"
  MTU="`$PIP link | $EGREP -E $DevQOS | $GAWK -F " " '{print $5}'`"
  QUANDEF="1540" #Default:1540 ou $MTU
  OPT="" #  OPT="overhead 128 quantum $QUANDEF mpu $MPU mtu $MTU"
  if [ "$VelQOS" != "-" -a "$VDGR" != "-" ]; then 
    #Liberar interface do Shaper
    $TC qdisc  del dev $DevQOS root 2> /dev/null > /dev/null
    #Ajustes de parametros para inibir erros de sintaxe
    PctQOS=${PctQOS/-/100}
    # ((qlen * mtu) / rate) / 1024 = time  (Specify ethernet device, Queue length, and MTU size )
    #$PIP link set dev $DevQOS qlen 30
    #Inicializar Egress
    DEFhfsc=`grfile_params $F_QOS | $EGREP -E "^$1"  | tail -n1 | $GAWK '{ print 2$4 }'`
    if [ "$DEFhfsc" == "2" ]; then
	DEFhfsc="243"
	# echo -n "DEFAULT=$DEFhfsc! Verifique!!!!"
    fi
    #Arvore Root (Todo o trafego da interface)
    $TC qdisc  add dev $DevQOS $EST handle 1:000 root hfsc default $DEFhfsc 
    #Arvore A: trafego local apenas
    $TC class  add dev $DevQOS $EST parent 1:000 classid   1:110  hfsc $OPT sc rate 1000Mbit 
    $TC filter add dev $DevQOS $EST parent 1:000 protocol ip prio 110 handle 100 fw flowid 1:110 	
    $TC qdisc  add dev $DevQOS $EST parent 1:110 handle  110: sfq perturb 10 quantum $QUANDEF			
    #Arvore B: trafego remoto
    $TC class add  dev $DevQOS $EST parent 1:000 classid   1:120  hfsc $OPT sc rate $((($PctQOS*$VelQOS)/100))kbit ul rate $((($PctQOS*$VelQOS)/100))kbit
    #Arvore B: No A - Sem shaper
    $TC class add  dev $DevQOS $EST parent 1:120 classid   1:121  hfsc $OPT sc rate $((($PctQOS*$VelQOS)/100))kbit ul rate $((($PctQOS*$VelQOS)/100))kbit
    $TC filter add dev $DevQOS $EST parent 1:000 protocol ip prio 121 handle 101 fw flowid 1:121
    $TC qdisc  add dev $DevQOS $EST parent 1:121 handle  120: sfq perturb 10 quantum $QUANDEF	
    #Arvore B: No B - Com shaper
    $TC class add  dev $DevQOS $EST parent 1:120 classid   1:200  hfsc $OPT sc rate $((($PctQOS*$VelQOS)/100))kbit ul rate $((($PctQOS*$VelQOS)/100))kbit
    grfile_params $F_QOS | $EGREP -E "^$1" | while read Tp Mrk VPai VSlf VRt  DlRt VLs  DlLs VUl  DlUl Q_Tp Q_Pr1 Comment; do
    	if [ "$VPai" == "-" ]; then X_VPai="200"  ; else X_VPai="2${VPai}"; fi	#Classe Pai
	if [ "$VUl" != "-" -a "$VLs" == "-" ]; then 						#Upper Limit sem Link share
	      VLs=$VUl
	fi    
        if [ "$VRt" != "-" ]; then								#Real Time
              SHPRT="rt dmax ${DlRt/-/0}ms rate $((($VelQOS*$PctQOS*$VRt)/10000))kbit"		#Real Time Calculado
        else  SHPRT="rt dmax ${DlRt/-/0}ms rate $((($VelQOS*$PctQOS)/2000))kbit"; fi 		#Real Time no minimo de 5% do link em realtime
        if [ "$VLs" != "-" ]; then								#Link Share
              SHPLS="ls dmax ${DlLs/-/0}ms rate $((($VelQOS*$PctQOS*$VLs)/10000))kbit"		#Link Share Calculado
        else  SHPLS="ls dmax ${DlLs/-/0}ms rate $((($PctQOS*$VelQOS)/100))kbit"; fi		#Link Share no maximo
        if [ "$VUl" != "-" ]; then								#Upper Limit
              SHPUL="ul dmax ${DlUl/-/0}ms rate $((($VelQOS*$PctQOS*$VUl)/10000))kbit"		#Upper Limit Calculado
        else  SHPUL="ul dmax ${DlUl/-/0}ms rate $((($PctQOS*$VelQOS)/100))kbit"; fi		#Upper Limit Calculado
	#Arvore B1: No A - Com shaper
	$TC class add  dev $DevQOS $EST parent 1:${X_VPai} classid 1:2${VSlf} hfsc $OPT $SHPRT $SHPLS $SHPUL
	if [ "${Mrk}" != "-" ]; then
	    #Pacotes Ack - Agilizar o upload
	    if [ "$VPai" == "10" -a "$VSlf" == "13" ]; then
		$TC filter add dev $DevQOS $EST parent 1:000 protocol ip prio 2${VSlf}0 u32 match ip protocol 6 0xff match u8 0x05 0x0f at 0 match u16 0x0000 0xffc0 at 2 match u8 0x10 0xff at 33 classid 1:2${VSlf}  
	    fi
    	    #Filtro Saida
            $TC filter add dev $DevQOS $EST parent 1:000 protocol ip prio 2${VSlf}9 handle ${Mrk} fw flowid 1:2${VSlf} # police burst 1k rate $[($PctQOS*$VelQOS)/100]kbit action reclassify # 2> /dev/null
            [ $? != 0 ] && echo Erro no filtro!!! 
    	    #Disciplina de saida
            case $Q_Tp in
                p) $TC qdisc add  dev $DevQOS $EST parent 1:2${VSlf} handle 2${VSlf}: pfifo limit ${Q_Pr1/-/20}
                ;;
                b) $TC qdisc add  dev $DevQOS $EST parent 1:2${VSlf} handle 2${VSlf}: bfifo limit ${Q_Pr1/-/$QUANDEF}
                ;;
                s) $TC qdisc add  dev $DevQOS $EST parent 1:2${VSlf} handle 2${VSlf}: sfq perturb ${Q_Pr1/-/10}
                ;;
            esac
	fi
    done 
  fi
}

#######################################################################################
#Parametros Tipo interfaceX UpSpeed Porcentagem
SHAPERIFF_HTB () {
  DevQOS="$2"
  VelQOS="$3"
  PctQOS="$4"
  EST="estimator 250ms 10s"
  MTU="`$PIP link | $EGREP -E $DevQOS | $GAWK -F " " '{print $5}'`"
  QUANDEF="1540" #Default:1540 ou $MTU
  OPT="" #  OPT="overhead 128 quantum $QUANDEF mpu $MPU mtu $MTU"
  if [ "$VelQOS" != "-" -a "$VDGR" != "-" ]; then 
    #Liberar interface do Shaper
    $TC qdisc  del dev $DevQOS root 2> /dev/null > /dev/null
    #Ajustes de parametros para inibir erros de sintaxe
    PctQOS=${PctQOS/-/100}
    # ((qlen * mtu) / rate) / 1024 = time  (Specify ethernet device, Queue length, and MTU size )
    #$PIP link set dev $DevQOS qlen 30
    #Inicializar Egress
    DEFHTB=`grfile_params $F_QOS | $EGREP -E "^$1"  | tail -n1 | $GAWK '{ print 2$4 }'`
    if [ "$DEFHTB" == "2" ]; then
	DEFHTB="243"
	echo -n "DEFAULT=$DEFHTB! Verifique!!!!"
    fi
    #Arvore Root (Todo o trafego da interface)
    $TC qdisc  add dev $DevQOS $EST handle 1:000 root htb default $DEFHTB r2q 1
    #Arvore A: trafego local apenas
    $TC class  add dev $DevQOS $EST parent 1:000 classid   1:110  htb $OPT rate 1000Mbit ceil 1000Mbit quantum $QUANDEF # burst 20k/8 cburst 20k/8
    $TC filter add dev $DevQOS $EST parent 1:000 protocol ip prio 110 handle 100 fw flowid 1:110 	
    $TC qdisc  add dev $DevQOS $EST parent 1:110 handle  110: sfq perturb 10 quantum $QUANDEF			
    #Arvore B: trafego remoto
    $TC class add  dev $DevQOS $EST parent 1:000 classid   1:120  htb $OPT rate $((($PctQOS*$VelQOS)/100))kbit ceil $((($PctQOS*$VelQOS)/100))kbit quantum $QUANDEF burst 30k/16 cburst 30k/16 
    #Arvore B: No A - Sem shaper
    $TC class add  dev $DevQOS $EST parent 1:120 classid   1:121  htb $OPT rate $((($PctQOS*$VelQOS)/100))kbit ceil $((($PctQOS*$VelQOS)/100))kbit quantum $QUANDEF # burst 30k/16 cburst 20k/16
    $TC filter add dev $DevQOS $EST parent 1:000 protocol ip prio 121 handle 101 fw flowid 1:121
    $TC qdisc  add dev $DevQOS $EST parent 1:121 handle  120: sfq perturb 10 quantum $QUANDEF	
    #Arvore B: No B - Com shaper
    $TC class add  dev $DevQOS $EST parent 1:120 classid   1:200  htb $OPT rate $((($PctQOS*$VelQOS)/100))kbit ceil $((($PctQOS*$VelQOS)/100))kbit quantum $QUANDEF burst 20k/16 cburst 20k/16
    #
    grfile_params $F_QOS | $EGREP -E "^$1" | while read TPBanda Mrk VPai VSlf Prio VComp VMax Q_Tp Q_Pr1 Comment; do
	VComp=${VComp/-/100}						#Velocidade "Garantida"
	VMax=${VMax/-/100}						#Velocidade "Compartilhada" ou Maxima
	Prio=${Prio/-/8}						#Prioridade
    	if [ "$VPai" == "-" ]; then X_VPai="200"  ; else X_VPai="2${VPai}"; fi	#Classe Pai
	#Arvore B1: No A - Com shaper
	$TC class add  dev $DevQOS $EST parent 1:${X_VPai} classid 1:2${VSlf} htb $OPT rate $((($VelQOS*$VComp*$PctQOS)/10000))kbit prio ${Prio} ceil $((($VelQOS*$PctQOS*$VMax)/10000))kbit quantum $QUANDEF burst 2k/16 cburst 2k/16
	#Pacotes Ack - Agilizar o upload
	if [ "$VPai" == "10" -a "$VSlf" == "13" ]; then
	    $TC filter add dev $DevQOS $EST parent 1:000 protocol ip prio 2${VSlf}0 u32 match ip protocol 6 0xff match u8 0x05 0x0f at 0 match u16 0x0000 0xffc0 at 2 match u8 0x10 0xff at 33 classid 1:2${VSlf}  
	fi
	if [ "${Mrk}" != "-" ]; then
    	    #Filtro Saida
            $TC filter add dev $DevQOS $EST parent 1:000 protocol ip prio 2${VSlf}9 handle ${Mrk} fw flowid 1:2${VSlf} # police rate $[($VelQOS*$VMax)/100]kbit burst 2400 mtu 9k action reclassify # 2> /dev/null
            # [ $? != 0 ] && echo Erro no filtro!!! 
    	    #Disciplina de saida
    	    case $Q_Tp in
	    	p) $TC qdisc add  dev $DevQOS $EST parent 1:2${VSlf} handle 2${VSlf}: pfifo limit ${Q_Pr1/-/20}
		;;
		b) $TC qdisc add  dev $DevQOS $EST parent 1:2${VSlf} handle 2${VSlf}: bfifo limit ${Q_Pr1/-/$QUANDEF}
		;;
		s) $TC qdisc add  dev $DevQOS $EST parent 1:2${VSlf} handle 2${VSlf}: sfq perturb ${Q_Pr1/-/10} 
		;;
	    esac			
	fi
    done 
  fi
}

#######################################################################################
# Hosts com acessos especificos bloqueados
HSTBLK () {
    log_action_begin_msg "Block Hosts " && { 
	$IPTABLES -w -t filter -F BLK_HST_S 2> /dev/null ; $IPTABLES -w -t filter -N BLK_HST_S 2> /dev/null
	$IPTABLES -w -t filter -F BLK_HST_D 2> /dev/null ; $IPTABLES -w -t filter -N BLK_HST_D 2> /dev/null
	grfile_params $F_BLKHST | while read hst log comment; do
	    if [ "${log}" != "-" ]; then  $IPTABLES -w -t filter -A BLK_HST_S -s $hst $LOG_LIMIT1_COMMAND blk-${log} $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=blk-${log} " --log-tcp-options --log-ip-options --log-uid ; fi
		                          $IPTABLES -w -t filter -A BLK_HST_S -s $hst -j DROP
	    if [ "${log}" != "-" ]; then  $IPTABLES -w -t filter -A BLK_HST_D -d $hst $LOG_LIMIT1_COMMAND blk-${log} $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=blk-${log} " --log-tcp-options --log-ip-options --log-uid ; fi
		                          $IPTABLES -w -t filter -A BLK_HST_D -d $hst -j DROP
	done
	#Bloqueio squid
	if [ ! -z "$F_BLKSQUID1" ]; then
	  grfile_params $F_BLKSQUID1 | while read hst comment; do
	     $IPTABLES -w -t filter -A BLK_HST_S -s $hst $LOG_LIMIT1_COMMAND blk-${L_BLKSQUID1} $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=blk-${L_BLKSQUID1} " --log-tcp-options --log-ip-options --log-uid
	     $IPTABLES -w -t filter -A BLK_HST_S -s $hst -j DROP
	     $IPTABLES -w -t filter -A BLK_HST_D -d $hst $LOG_LIMIT1_COMMAND blk-${L_BLKSQUID1} $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=blk-${L_BLKSQUID1} " --log-tcp-options --log-ip-options --log-uid
	     $IPTABLES -w -t filter -A BLK_HST_D -d $hst -j DROP
	  done
	fi
        #Bloqueios genericos em arquivos com nome blk_, exceto o ja existente blk_hst.ini que tem preferencia anterior de execucao 
	for F_HSTDIVERSOS in `$LS -1 -d -p ${D_LST}/blk_*.ini 2> /dev/null | $EGREP -E -v "(hst|port|upnp|dyn)"`; do
	    LOG_HSTSUFIX="`$BASENAME "$F_HSTDIVERSOS" .ini | $CUT -c5-`" 
    	    grfile_params $F_HSTDIVERSOS | while read hst comment; do
		$IPTABLES -w -t filter -A BLK_HST_S -s $hst $LOG_LIMIT1_COMMAND blk-${LOG_HSTSUFIX} $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=blk-${LOG_HSTSUFIX} " --log-tcp-options --log-ip-options --log-uid 
		$IPTABLES -w -t filter -A BLK_HST_S -s $hst -j DROP
		$IPTABLES -w -t filter -A BLK_HST_D -d $hst $LOG_LIMIT1_COMMAND blk-${LOG_HSTSUFIX} $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=blk-${LOG_HSTSUFIX} " --log-tcp-options --log-ip-options --log-uid 
		$IPTABLES -w -t filter -A BLK_HST_D -d $hst -j DROP
	    done
	done

	$IPTABLES -w -t filter -I INPUT 5   -j BLK_HST_S  -m mark ! --mark 100 #Somente redes externas!
	# $IPTABLES -w -t filter -A OUTPUT  -j BLK_HST_D  -m mark ! --mark 100 #Somente redes externas!
	$IPTABLES -w -t filter -I FORWARD 2 -j BLK_HST_D  -m mark ! --mark 100 #Somente redes externas!
    } && log_action_end_msg $?
}

#------------------------------------------------------------------------
# Para TCP, novos servicos= --tcp-flags SYN,RST,ACK SYN 
ACESSOS () {
  log_action_begin_msg "ACC Set $*" && { 
    #SS: Servidor como servidor, SC: Servidor como Cliente
    #ES: Estacao  como servidor, EC: Estacao  como Cliente, EL: Estacao Loop para a mesma rede, vai e volta na mesma eth
    #T: Todos, S: Servidores, A: Adminstracao, C: Clientes, B: Bloqueio
    $IPTABLES -w -t filter -F SCB 2> /dev/null ; $IPTABLES -w -t filter -N SCB 2> /dev/null
    $IPTABLES -w -t filter -F SCT 2> /dev/null ; $IPTABLES -w -t filter -N SCT 2> /dev/null
    $IPTABLES -w -t filter -F ECB 2> /dev/null ; $IPTABLES -w -t filter -N ECB 2> /dev/null
    $IPTABLES -w -t filter -F ECT 2> /dev/null ; $IPTABLES -w -t filter -N ECT 2> /dev/null
    $IPTABLES -w -t filter -F ECI 2> /dev/null ; $IPTABLES -w -t filter -N ECI 2> /dev/null
    $IPTABLES -w -t filter -F ECS 2> /dev/null ; $IPTABLES -w -t filter -N ECS 2> /dev/null
    $IPTABLES -w -t filter -F ECA 2> /dev/null ; $IPTABLES -w -t filter -N ECA 2> /dev/null
    $IPTABLES -w -t filter -F ELA 2> /dev/null ; $IPTABLES -w -t filter -N ELA 2> /dev/null
    $IPTABLES -w -t filter -F ECC 2> /dev/null ; $IPTABLES -w -t filter -N ECC 2> /dev/null
    $IPTABLES -w -t filter -F SSB 2> /dev/null ; $IPTABLES -w -t filter -N SSB 2> /dev/null
    $IPTABLES -w -t filter -F SST 2> /dev/null ; $IPTABLES -w -t filter -N SST 2> /dev/null
    $IPTABLES -w -t filter -F SSS 2> /dev/null ; $IPTABLES -w -t filter -N SSS 2> /dev/null
    $IPTABLES -w -t filter -F SSA 2> /dev/null ; $IPTABLES -w -t filter -N SSA 2> /dev/null
    $IPTABLES -w -t filter -F SSC 2> /dev/null ; $IPTABLES -w -t filter -N SSC 2> /dev/null
    $IPTABLES -w -t filter -F ESB 2> /dev/null ; $IPTABLES -w -t filter -N ESB 2> /dev/null
    $IPTABLES -w -t filter -F EST 2> /dev/null ; $IPTABLES -w -t filter -N EST 2> /dev/null
    $IPTABLES -w -t filter -F ESS 2> /dev/null ; $IPTABLES -w -t filter -N ESS 2> /dev/null
    $IPTABLES -w -t filter -F ESA 2> /dev/null ; $IPTABLES -w -t filter -N ESA 2> /dev/null
    $IPTABLES -w -t filter -F ESC 2> /dev/null ; $IPTABLES -w -t filter -N ESC 2> /dev/null
    $IPTABLES -w -t filter -F ESI 2> /dev/null ; $IPTABLES -w -t filter -N ESI 2> /dev/null
    $IPTABLES -w -t mangle -F MRK_HST_D 2> /dev/null ; $IPTABLES -w -t mangle -N MRK_HST_D 2> /dev/null   #Marcar!
    $IPTABLES -w -t mangle -F MRK_HST_S 2> /dev/null ; $IPTABLES -w -t mangle -N MRK_HST_S 2> /dev/null   #Marcar!
    $IPTABLES -w -t mangle -F QOS_HST_D 2> /dev/null ; $IPTABLES -w -t mangle -N QOS_HST_D 2> /dev/null   #Setar QOS
    $IPTABLES -w -t mangle -F QOS_HST_S 2> /dev/null ; $IPTABLES -w -t mangle -N QOS_HST_S 2> /dev/null   #Setar QOS
  
    #Ativacao
    if [ -z "$*" ]; then
	#Associacoes por redes internas ou clientes ou servidores
        $ROUTE -n | $EGREP -E "^[[:digit:]]" | $EGREP -E -v  "(^((0|127|224|239)[.]0[.])|(UH|UG))" | while read dest1 gw1 mask1 op1 met1 ref1 uso1 dev1; do #Redes Locais
            $IPTABLES -w -t filter -A FORWARD -j ECB -i $dev1 -s $dest1/$mask1 -m conntrack --ctstate NEW 
            $IPTABLES -w -t filter -A FORWARD -j ESB -o $dev1 -d $dest1/$mask1 -m conntrack --ctstate NEW 
            $IPTABLES -w -t filter -A FORWARD -j ECT -i $dev1 -s $dest1/$mask1 -m conntrack --ctstate NEW  -m mark ! --mark 100 #Apenas redes Nao Locais
            $IPTABLES -w -t filter -A FORWARD -j ECI -i $dev1 -s $dest1/$mask1 -m conntrack --ctstate NEW  -m mark ! --mark 100 #Apenas redes Nao Locais
            $IPTABLES -w -t filter -A FORWARD -j ESI -o $dev1 -d $dest1/$mask1 -m conntrack --ctstate NEW  -m mark --mark 100   #Apenas entre redes Locais 
            $IPTABLES -w -t filter -A OUTPUT  -j ESI -o $dev1 -d $dest1/$mask1 -m conntrack --ctstate NEW  -m mark --mark 100   #Apenas       redes Locais
            $IPTABLES -w -t filter -A FORWARD -j EST -o $dev1 -d $dest1/$mask1 -m conntrack --ctstate NEW,RELATED,ESTABLISHED 
            if [ ! -z "`echo .$DEV_SRV. | $EGREP -E $dev1`" ]; then
                        $IPTABLES -w -t filter -A INPUT   -i $dev1 -s $dest1/$mask1 -j SSS -m conntrack --ctstate NEW,RELATED,ESTABLISHED  #-m mark --mark 100
                        $IPTABLES -w -t filter -A FORWARD -i $dev1 -s $dest1/$mask1 -j ECS -m conntrack --ctstate NEW  -m mark ! --mark 100 #Apenas redes Nao Locais
                        $IPTABLES -w -t filter -A FORWARD -o $dev1 -d $dest1/$mask1 -j ESS -m conntrack --ctstate NEW,RELATED,ESTABLISHED 
            fi
            if [ ! -z "`echo .$DEV_ADM. | $EGREP -E $dev1`" ]; then
                        $IPTABLES -w -t filter -A INPUT   -i $dev1 -s $dest1/$mask1 -j SSA -m conntrack --ctstate NEW,RELATED,ESTABLISHED  #-m mark --mark 100
                        $IPTABLES -w -t filter -A FORWARD -i $dev1 -s $dest1/$mask1 -j ECA -m conntrack --ctstate NEW  -m mark ! --mark 100 #Apenas redes Nao Locais
                        $IPTABLES -w -t filter -A FORWARD -o $dev1 -d $dest1/$mask1 -j ESA -m conntrack --ctstate NEW,RELATED,ESTABLISHED 
                        $IPTABLES -w -t filter -A FORWARD -i $dev1 -o $dev1 -s $dest1/$mask1 -d $dest1/$mask1 -j ELA -m conntrack --ctstate NEW,RELATED,ESTABLISHED  -m mark --mark 100 #Apenas redes Locais Loop, vai e volta por causa de filtros
            fi
            if [ ! -z "`echo .$DEV_CLI. | $EGREP -E $dev1`" ]; then
                        $IPTABLES -w -t filter -A INPUT   -i $dev1 -s $dest1/$mask1 -j SSC -m conntrack --ctstate NEW,RELATED,ESTABLISHED  #-m mark --mark 100
                        $IPTABLES -w -t filter -A FORWARD -i $dev1 -s $dest1/$mask1 -j ECC -m conntrack --ctstate NEW  -m mark ! --mark 100 #Apenas redes Nao Locais
                        $IPTABLES -w -t filter -A FORWARD -o $dev1 -d $dest1/$mask1 -j ESC -m conntrack --ctstate NEW,RELATED,ESTABLISHED 
            fi
        done
	#Interfaces administrativas as que tem VPN, equivalem a estacoes Administrativas! ECA, ESI, ESB. etc
        if [ ! -z "$NET_VPN" ]; then
            $IPTABLES -w -t filter -A INPUT   -s $NET_VPN -j SSA -m conntrack --ctstate NEW,RELATED,ESTABLISHED  #-m mark --mark 100
	    $IPTABLES -w -t filter -A FORWARD -s $NET_VPN -j ECA -m conntrack --ctstate NEW  -m mark ! --mark 100 #Apenas redes Nao Locais
    	    $IPTABLES -w -t filter -A FORWARD -d $NET_VPN -j ESA -m conntrack --ctstate NEW,RELATED,ESTABLISHED 
	    $IPTABLES -w -t filter -A FORWARD -j ECB -s $NET_VPN -m conntrack --ctstate NEW
            $IPTABLES -w -t filter -A FORWARD -j ESB -d $NET_VPN -m conntrack --ctstate NEW 
	    $IPTABLES -w -t filter -A FORWARD -j ECT -s $NET_VPN -m conntrack --ctstate NEW  -m mark ! --mark 100 #Apenas redes Nao Locais
	    $IPTABLES -w -t filter -A FORWARD -j ESI -d $NET_VPN -m conntrack --ctstate NEW  -m mark --mark 100   #Apenas entre redes Locais
	    $IPTABLES -w -t filter -A OUTPUT  -j ESI -d $NET_VPN -m conntrack --ctstate NEW  -m mark --mark 100   #Apenas       redes Locais
	    $IPTABLES -w -t filter -A FORWARD -j EST -d $NET_VPN -m conntrack --ctstate NEW
            $IPTABLES -w -t filter -A INPUT   -s $NET_VPN -j SSA -m conntrack --ctstate NEW,RELATED,ESTABLISHED  #-m mark --mark 100
            $IPTABLES -w -t filter -A FORWARD -s $NET_VPN -j ECA -m conntrack --ctstate NEW  -m mark ! --mark 100 #Apenas redes Nao Locais
            $IPTABLES -w -t filter -A FORWARD -d $NET_VPN -j ESA -m conntrack --ctstate NEW,RELATED,ESTABLISHED
	    # $IPTABLES -A INPUT -m policy --dir in --pol ipsec -p udp --dport 1701 -j ACCEPT
	    # $IPTABLES -A INPUT -m policy --dir in --pol ipsec --mode tunnel -j ACCEPT
	    # $IPTABLES -A OUTPUT -m policy --dir out --pol ipsec --mode tunnel -j ACCEPT
	    # $IPTABLES -A FORWARD -m policy --dir in --pol ipsec --mode tunnel -j ACCEPT
	    # $IPTABLES -A FORWARD -m policy --dir out --pol ipsec --mode tunnel -j ACCEPT
	fi
	#Outras Associacoes
	$IPTABLES -w -t filter -A INPUT   -j SSB -m conntrack --ctstate NEW 
	$IPTABLES -w -t filter -A OUTPUT  -j SCB -m conntrack --ctstate NEW 
	$IPTABLES -w -t filter -A INPUT   -j SST -m conntrack --ctstate NEW,RELATED,ESTABLISHED 
	$IPTABLES -w -t filter -A OUTPUT  -j SCT -m conntrack --ctstate NEW
	#Estabelecidos 
	$IPTABLES -w -t filter -A INPUT   -j ACCEPT -m conntrack --ctstate ESTABLISHED				#Não, apenas estabelecido. Relatado atraves de helpers
	$IPTABLES -w -t filter -A OUTPUT  -j ACCEPT -m conntrack --ctstate ESTABLISHED				#Não, apenas estabelecido. Relatado atraves de helpers
	$IPTABLES -w -t filter -A FORWARD -j ACCEPT -m conntrack --ctstate ESTABLISHED				#Sim, Relatado para Forward! 
	#$IPTABLES -w -t filter -A FORWARD -j ACCEPT -m conntrack --ctstate RELATED				#Sim, Relatado para Forward! (PERIGOSO?) - Separado para Estatisticas
	#Redirecionados e Aceitos
	#verificar -m connmark --ctstate snat ou -m connmark --ctstate dnat 
        #Setar QOS (Todos ainda nao foram mascarados, entao tem de ser PREROUTING)
        $IPTABLES -w -t mangle -A OUTPUT      -j QOS_HST_S -m mark ! --mark 100 -m conntrack --ctstate RELATED,ESTABLISHED #Sendo acessado em algo, ex: saindo da porta 80
        $IPTABLES -w -t mangle -A OUTPUT      -j QOS_HST_D -m mark ! --mark 100                               #Acessando algo, ex: acessando a porta 80 de alguem
        $IPTABLES -w -t mangle -A PREROUTING  -j QOS_HST_D -m mark ! --mark 100                               #Acessando algo, ex: acessando a porta 80 de alguem(forward)
        #Marcar Pacotes (Todos ainda nao foram mascarados, entao tem de ser PREROUTING)
        $IPTABLES -w -t mangle -A OUTPUT      -j MRK_HST_D                                                    #Acessando algo, ex: acessando a porta 80 de alguem
        $IPTABLES -w -t mangle -A PREROUTING  -j MRK_HST_D -m mark ! --mark 100       		    	      #Estacao Saindo
        $IPTABLES -w -t mangle -A PREROUTING  -j MRK_HST_S                        		    	      #Estacao Saindo 
    fi
  } && log_action_end_msg $?

  #Acessos Por Hosts
  log_action_begin_msg "ACC Hst " && { 
    #Acessos Por Maquinas especificas (macs ou hosts)
     grfile_params "$F_ACCHST1 $F_ACCHST2" | $TAC | while read tipo prot serv src dst dstnonet rdrout band qos limini limsec limcon log comment; do
        prot=${prot/-/all}
        #dst=${dst/-/"0.0.0.0/0"}
        #src=${src/-/"0.0.0.0/0"}
        #IPdst=`get_ip $dst $dstnonet`
	#Ve se tem de procurar ou ja tem um ip especifico
	if [ "$dst" != "-" ]; then
    	    IPdst=`get_ip $dst`
	elif [ "$dstnonet" != "-" ]; then
	    IPdst=$dstnonet
	else
	    IPdst=""
	fi
	#Exibe mensagem de erro caso nao ache o dns e coloca o ip especifico se preciso for
	if [ "$IPdst" == "" ]; then
	    if [ ! -z "$dstnonet" ]; then
     	        echo -n "!($tipo !${dst} ${dstnonet})"
		IPdst=$dstnonet
	    else
    		echo -n "!($tipo !${dst} !${dstnonet})"
	    fi
	fi
	#Inicializa Firewall
	if [ ! "$IPdst" == "" ]; then
	  for IPdsthst in $IPdst; do
	    # echo -n -e ".\b"
	    ntipo=${#tipo} 
    	    if [ ! -z "`echo .$serv. | $EGREP -E ,`" ]; then 
		DP="-m multiport --dports $serv" 
		SP="-m multiport --sports $serv" 
	    elif [ "$serv" != "-" ]; then
        	if [ "$prot" == "icmp" ]; then
            	    DP="--icmp-type $serv"
            	    SP="--icmp-type $serv"
		else
		    DP="--dport $serv"
		    SP="--sport $serv"
		fi
    	    else 
		DP=""
		SP=""
    	    fi
	    if [ "${limini}${limsec}" != "--" ]; then 
		if [ "$limini" != "-" ]; then 			#Limit Inicial
		    LI="--limit-burst $limini" 
    		else 
		    LI=""
    		fi
		if [ "$limsec" != "-" ]; then 			#Limit Inicial
		    LS="--limit $limsec" 
    		else 
		    LS=""
    		fi
		LM="-m limit $LI $LS"
	    else
		LM=""
	    fi

	    #QOS e Mark
	    atipo=0
    	    while [[ $atipo -le $ntipo ]]; do
        	case ${tipo:$atipo:2} in 
            	  EC|SC)        #Acoes como Cliente (Liberacao) MRK_HST_D
        		if [ "$band" != "-" ]; then
            		    $IPTABLES -w -t mangle -A MRK_HST_D -p $prot $DP -s $src -d $IPdsthst -j MARK --set-mark $band 
        		fi
        		if [ "$qos" != "-" ]; then
            		    $IPTABLES -w -t mangle -A QOS_HST_D -p $prot $DP -s $src -d $IPdsthst -j DSCP --set-dscp-class $qos
        		fi
		  ;;
        	  ES|SS) 	#Acoes como Servidor (Liberacao) MRK_HST_S
        		if [ "$band" != "-" ]; then
            		    $IPTABLES -w -t mangle -A MRK_HST_S -p $prot $SP -s $src -d $IPdsthst -j MARK --set-mark $band 
        		fi
        		if [ "$qos" != "-" ]; then
            		    $IPTABLES -w -t mangle -A QOS_HST_S -p $prot $SP -s $src -d $IPdsthst -j DSCP --set-dscp-class $qos
        		fi
		  ;;
		esac
		atipo=$(($atipo+4))
    	    done

	    #Limite de Conexoes simultaneas
    	    if [ "$limcon" != "-" ]; then
        	LC="-m connlimit --connlimit-saddr --connlimit-upto $limcon"
	    else
		LC=""
    	    fi
	    #Outros
	    atipo=0
    	    while [[ $atipo -le $ntipo ]]; do
        	case ${tipo:$atipo:3} in 
            	  SCT)                    		#Acoes como Cliente (Liberacao)
		    IPdsthst=${IPdsthst/-/"0.0.0.0/0"}
		    src=${src/-/"0.0.0.0/0"}
    		    if [ "`ismac $src`" == "1" ]; then 
		        if [ "${log}" != "-" ]; then  $IPTABLES -w -t filter -A ${tipo:$atipo:3}         -p $prot $DP -m mac --mac-source $src -d $IPdsthst $LOG_LIMIT1_COMMAND acc-${log} $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=acc-${tipo:$atipo:3}-${log} " --log-tcp-options --log-ip-options  --log-uid ; fi
		                                      $IPTABLES -w -t filter -A ${tipo:$atipo:3}         -p $prot $DP -m mac --mac-source $src -d $IPdsthst -j ACCEPT
		    else
		        if [ "${log}" != "-" ]; then  $IPTABLES -w -t filter -A ${tipo:$atipo:3}         -p $prot $DP -d $src -s $IPdsthst $LOG_LIMIT1_COMMAND acc-${log} $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=acc-${tipo:$atipo:3}-${log} " --log-tcp-options --log-ip-options --log-uid ; fi
		                                      $IPTABLES -w -t filter -A ${tipo:$atipo:3}         -p $prot $DP -d $src -s $IPdsthst -j ACCEPT
		    fi
		  ;;
            	  ECT|ECS|ECA|ECC|ELA)                  #Acoes como Cliente (Liberacao)
    		    if [ "`ismac $src`" == "1" ]; then 
		        if [ "${log}" != "-" ]; then  $IPTABLES -w -t filter -A ${tipo:$atipo:3}         -p $prot $DP -m mac --mac-source $src -d $IPdsthst $LOG_LIMIT1_COMMAND acc-${log} $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=acc-${tipo:$atipo:3}-${log} " --log-tcp-options --log-ip-options --log-uid ; fi
		                                      $IPTABLES -w -t filter -A ${tipo:$atipo:3} $LC $LM -p $prot $DP -m mac --mac-source $src -d $IPdsthst -j ACCEPT
		    else
		        if [ "${log}" != "-" ]; then  $IPTABLES -w -t filter -A ${tipo:$atipo:3}         -p $prot $DP -s $src -d $IPdsthst $LOG_LIMIT1_COMMAND acc-${log} $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=acc-${tipo:$atipo:3}-${log} " --log-tcp-options --log-ip-options --log-uid ; fi
		                                      $IPTABLES -w -t filter -A ${tipo:$atipo:3} $LC $LM -p $prot $DP -s $src -d $IPdsthst -j ACCEPT
		    fi
		  ;;
            	  ECI)                    		#Acoes como Cliente porta invertida (Liberacao)
    		    if [ "`ismac $src`" == "1" ]; then 
		        if [ "${log}" != "-" ]; then  $IPTABLES -w -t filter -A ${tipo:$atipo:3}         -p $prot $SP -m mac --mac-source $src -d $IPdsthst $LOG_LIMIT1_COMMAND acc-${log} $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=acc-${tipo:$atipo:3}-${log} " --log-tcp-options --log-ip-options --log-uid ; fi
		                                      $IPTABLES -w -t filter -A ${tipo:$atipo:3} $LC $LM -p $prot $SP -m mac --mac-source $src -d $IPdsthst -j ACCEPT
		    else
		        if [ "${log}" != "-" ]; then  $IPTABLES -w -t filter -A ${tipo:$atipo:3}         -p $prot $SP -s $src -d $IPdsthst $LOG_LIMIT1_COMMAND acc-${log} $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=acc-${tipo:$atipo:3}-${log} " --log-tcp-options --log-ip-options --log-uid ; fi
		                                      $IPTABLES -w -t filter -A ${tipo:$atipo:3} $LC $LM -p $prot $SP -s $src -d $IPdsthst -j ACCEPT
		    fi
		  ;;
                  SCB|ECB)                    		#Acoes como Cliente (Bloqueio)
    		    if [ "`ismac $src`" == "1" ]; then 
		        if [ "${log}" != "-" ]; then  $IPTABLES -w -t filter -A ${tipo:$atipo:3}         -p $prot $DP -m mac --mac-source $src -d $IPdsthst $LOG_LIMIT1_COMMAND acc-${log} $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=blk-${tipo:$atipo:3}-${log} " --log-tcp-options --log-ip-options  --log-uid ; fi
		                                      $IPTABLES -w -t filter -A ${tipo:$atipo:3}         -p $prot $DP -m mac --mac-source $src -d $IPdsthst -j DROPPLUS 
		    else
		        if [ "${log}" != "-" ]; then  $IPTABLES -w -t filter -A ${tipo:$atipo:3}         -p $prot $DP -s $src -d $IPdsthst $LOG_LIMIT1_COMMAND acc-${log} $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=blk-${tipo:$atipo:3}-${log} " --log-tcp-options --log-ip-options --log-uid ; fi
		                                      $IPTABLES -w -t filter -A ${tipo:$atipo:3}         -p $prot $DP -s $src -d $IPdsthst -j DROPPLUS 
		    fi
		  ;;
        	  SST|SSS|SSA|SSC|ESI) 			#Acoes como Servidor (Liberacao)
    		    if [ "`ismac $IPdsthst`" == "1" ]; then 
		        if [ "${log}" != "-" ]; then  $IPTABLES -w -t filter -A ${tipo:$atipo:3}         -p $prot $DP -m mac --mac-source $IPdsthst -d $src $LOG_LIMIT1_COMMAND acc-${log} $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=acc-${tipo:$atipo:3}-${log} " --log-tcp-options --log-ip-options --log-uid ; fi
		                                      $IPTABLES -w -t filter -A ${tipo:$atipo:3}         -p $prot $DP -m mac --mac-source $IPdsthst -d $src -j ACCEPT
		    else
		        if [ "${log}" != "-" ]; then  $IPTABLES -w -t filter -A ${tipo:$atipo:3}         -p $prot $DP -d $IPdsthst -s $src $LOG_LIMIT1_COMMAND acc-${log} $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=acc-${tipo:$atipo:3}-${log} " --log-tcp-options --log-ip-options --log-uid ; fi
		                                      $IPTABLES -w -t filter -A ${tipo:$atipo:3}         -p $prot $DP -d $IPdsthst -s $src -j ACCEPT
		    fi
		  ;;
        	  EST|ESS|ESA|ESC) 	#Acoes como Servidor (Liberacao)
    		    if [ "`ismac $IPdsthst`" == "1" ]; then 
		        if [ "${log}" != "-" ]; then  $IPTABLES -w -t filter -A ${tipo:$atipo:3}         -p $prot $DP -m mac --mac-source $IPdsthst -d $src $LOG_LIMIT1_COMMAND acc-${log} $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=acc-${tipo:$atipo:3}-${log} " --log-tcp-options --log-ip-options  --log-uid ; fi
		                                      $IPTABLES -w -t filter -A ${tipo:$atipo:3} $LC $LM -p $prot $DP -m mac --mac-source $IPdsthst -d $src -j ACCEPT
		    else
		        if [ "${log}" != "-" ]; then  $IPTABLES -w -t filter -A ${tipo:$atipo:3}         -p $prot $DP -s $IPdsthst -d $src $LOG_LIMIT1_COMMAND acc-${log} $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=acc-${tipo:$atipo:3}-${log} " --log-tcp-options --log-ip-options --log-uid ; fi
		                                      $IPTABLES -w -t filter -A ${tipo:$atipo:3} $LC $LM -p $prot $DP -s $IPdsthst -d $src -j ACCEPT
		    fi
		  ;;
                  SSB|ESB)                  		#Acoes como Servidor (Bloqueio)
    		    if [ "`ismac $IPdsthst`" == "1" ]; then 
		        if [ "${log}" != "-" ]; then  $IPTABLES -w -t filter -A ${tipo:$atipo:3}         -p $prot $DP -m mac --mac-source $IPdsthst -d $src $LOG_LIMIT1_COMMAND blk-${log} $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=blk-${tipo:$atipo:3}-${log} " --log-tcp-options --log-ip-options  --log-uid ; fi
                        $IPTABLES -w -t filter -A ${tipo:$atipo:3}         -p $prot $DP -m mac --mac-source $IPdsthst -d $src -j DROPPLUS 
		    else
		        if [ "${log}" != "-" ]; then  $IPTABLES -w -t filter -A ${tipo:$atipo:3}         -p $prot $DP -s $IPdsthst -d $src $LOG_LIMIT1_COMMAND blk-${log} $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=blk-${tipo:$atipo:3}-${log} " --log-tcp-options --log-ip-options --log-uid ; fi
		                                      $IPTABLES -w -t filter -A ${tipo:$atipo:3}         -p $prot $DP -s $IPdsthst -d $src -j DROPPLUS 
		    fi
		  ;;
        	  ---)
		    echo -n -e ".\b"
		  ;;
                  *)
		    echo -n "x"
		  ;;
		esac
		atipo=$(($atipo+4))
    	    done
	  done
	fi
    done
  } && log_action_end_msg $?

  #Acessos Por Hosts
  log_action_begin_msg "ACC Hst2 " && { 
        #Bloqueios genericos em arquivos com nome blk_, exceto o ja existente blk_hst.ini que tem preferencia anterior de execucao
        for F_HSTDIVERSOS in `$LS -1 -d -p ${D_LST}/acc_*.ini 2> /dev/null | $EGREP -E -v "(hst|port|upnp|dyn)"`; do
            LOG_HSTSUFIX="`$BASENAME "$F_HSTDIVERSOS" .ini | $CUT -c5-`"
            grfile_params $F_HSTDIVERSOS | while read prot serv hst comment; do
                if [ ! -z "`echo .$serv. | $EGREP -E ,`" ]; then
	            DP="-m multiport --dports $serv"
        	elif [ "$serv" == "-" ]; then
                    DP=""
                else
                    DP="--dport $serv"
                fi
                $IPTABLES -w -t filter -A ECT -p $prot $DP -d $hst -j ACCEPT
            done
        done
  } && log_action_end_msg $?

  #Especifica NFS (rede administrativa e rede de servidores)
  #showmount --export 10.0.0.1
  if [ -f /var/lock/subsys/nfs -o -f /var/lock/subsys/unfs ]; then 
    log_action_begin_msg "ACC NFS " && { 
        rpcinfo -p | $EGREP -E "(tcp|udp)" | $GAWK '{ print $3" "$4" "$5 }' | $SORT | $UNIQ | while read prot serv comment;do
           $IPTABLES -w -t filter -A SSA -p $prot --dport $serv -j ACCEPT
           $IPTABLES -w -t filter -A SSS -p $prot --dport $serv -j ACCEPT
	    # echo -n -e ".\b"
	done
    } && log_action_end_msg $?
  fi

  #Acessos Por Redes/Interfaces inteiras
  log_action_begin_msg "ACC Start " && { 
    grfile_params $F_ACESSOS | while read tipo prot serv pid limini limsec limcon log logden band qos comment;do
	ntipo=${#tipo}
        #Retorna Protocolo
        if [ "$prot" != "-" ]; then 			#Pid
  	    PT="-p $prot" 
    	else 
	    PT=" "
	fi
	#Retorna Porta 		
    	if [ ! -z "`echo .$serv. | $EGREP -E ,`" ]; then 		#Multiport
	    DP="-m multiport --dports $serv" 
        elif [ "$serv" != "-" ]; then
            if [ "$prot" == "icmp" ]; then
                DP="--icmp-type $serv"
	    else
		DP="--dport $serv"
	    fi
	else
	    DP=""
        fi
	#Retorna limite caso Haja algum
	if [ "${limini}${limsec}" != "--" ]; then 
	    if [ "$limini" != "-" ]; then 			#Limit Inicial
		LI="--limit-burst $limini" 
    	    else 
		LI=""
    	    fi
	    if [ "$limsec" != "-" ]; then 			#Limit Inicial
		LS="--limit $limsec" 
    	    else 
		LS=""
    	    fi
	    LM="-m limit $LI $LS"
	else	
	    LM=""
	fi
        #Retorna PID Caso Haja algum
        if [ "$pid" != "-" ]; then 			#Pid
  	    PP="-m owner --uid-owner $pid" 
    	else 
	    PP=" "
	fi
        #Limite de Conexoes simultaneas
	limcon="-" #Desativado por falta de modulos
    	if [ "$limcon" != "-" ]; then
    	    LC="-m connlimit --connlimit-saddr --connlimit-upto $limcon"
	else
	    LC=""
    	fi

	atipo=0
	while [[ $atipo -le $ntipo ]]; do
            case ${tipo:$atipo:3} in 
        	SCT) 				#Acoes Servidor Liberacao (com pid)
		    if [ "${log}" != "-" ]; then  $IPTABLES -w -t filter -A ${tipo:$atipo:3} $PP $PT $DP $LOG_LIMIT1_COMMAND acc-${tipo:$atipo:3}-${log} $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=acc-${tipo:$atipo:3}-${log} " --log-tcp-options --log-ip-options --log-uid ; fi
		    $IPTABLES -w -t filter -A ${tipo:$atipo:3} $PT $DP $PP    -j ACCEPT
		;;
        	SST|SSS|SSA|SSC|ESI) 		#Acoes Servidor Liberacao
		    if [ "${log}" != "-" ]; then  $IPTABLES -w -t filter -A ${tipo:$atipo:3} $PP $PT $DP $LOG_LIMIT1_COMMAND acc-${tipo:$atipo:3}-${log} $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=acc-${tipo:$atipo:3}-${log} " --log-tcp-options --log-ip-options --log-uid ; fi
		    $IPTABLES -w -t filter -A ${tipo:$atipo:3} $PT $DP        -j ACCEPT
		;;
        	SCB) 			 	#Acoes Servidor Bloqueio (com pid)
		    if [ "${log}" != "-" ]; then  $IPTABLES -w -t filter -A ${tipo:$atipo:3} $PP $PT $DP $LOG_LIMIT1_COMMAND blk-${tipo:$atipo:3}-${log} $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=blk-${tipo:$atipo:3}-${log} " --log-tcp-options --log-ip-options --log-uid ; fi
		    $IPTABLES -w -t filter -A ${tipo:$atipo:3} $PT $DP $PP      -j DROPPLUS
		;;
        	SSB) 			 	#Acoes Servidor Bloqueio 
		    if [ "${log}" != "-" ]; then  $IPTABLES -w -t filter -A ${tipo:$atipo:3} $PP $PT $DP $LOG_LIMIT1_COMMAND blk-${tipo:$atipo:3}-${log} $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=blk-${tipo:$atipo:3}-${log} " --log-tcp-options --log-ip-options --log-uid ; fi
		    $IPTABLES -w -t filter -A ${tipo:$atipo:3} $PT $DP         -j DROPPLUS
		;;
        	ECT|ECS|ECA|ECC|EST|ESS|ESA|ESC|ELA) #Liberacao
		    if [ "${log}" != "-" ]; then  $IPTABLES -w -t filter -A ${tipo:$atipo:3}     $PT $DP $LOG_LIMIT1_COMMAND acc-${tipo:$atipo:3}-${log} $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=acc-${tipo:$atipo:3}-${log} " --log-tcp-options --log-ip-options --log-uid ; fi
		    $IPTABLES -w -t filter -A ${tipo:$atipo:3} $PT $DP $LC $LM -j ACCEPT 
		;;
        	ECB|ESB) 		 	#Acoes Servidor Bloqueio
		    if [ "${log}" != "-" ]; then  $IPTABLES -w -t filter -A ${tipo:$atipo:3} $PP $PT $DP $LOG_LIMIT1_COMMAND blk-${tipo:$atipo:3}-${log} $LOG_LIMIT2_COMMAND -j LOG --log-level 7 --log-prefix "Pkt: flag=blk-${tipo:$atipo:3}-${log} " --log-tcp-options --log-ip-options --log-uid ; fi
		    $IPTABLES -w -t filter -A ${tipo:$atipo:3} $PT $DP     -j DROPPLUS
		;;
        	#---)
		#    echo -n -e ".\b"
		#;;
                #*)
		#    echo -n "o"
		#;;
            esac
	    atipo=$(($atipo+4))
        done
        # echo -n -e ".\b"
    done
    } && log_action_end_msg $?
}
#------------------------------------------------------------------------
HELP () {
     log_action_begin_msg " ----------------------------------------------------------------------------"; echo
     log_action_begin_msg " - $VERSAO"; echo
     log_action_begin_msg " - IpTables Script Firewall by marca@grupogsn.com.br"; echo
     log_action_begin_msg " - firewall $0 <opcoes [continue]>"; echo
     log_action_begin_msg " ----------------------------------------------------------------------------"; echo
     log_action_begin_msg " - install                  : Instala o firewall (use caminho completo)"; echo
     log_action_begin_msg " - start                    : Inicia o firewall"; echo
     log_action_begin_msg " - stop                     : Para e abre o firewall"; echo
     log_action_begin_msg " - close                    : Fecha a maquina completamente (menos SSH)"; echo
     log_action_begin_msg " - mac                      : Reload da lista de macs (caso ativa)"; echo
     log_action_begin_msg " - test                     : Executa alguns testes"; echo
     log_action_begin_msg " - mail [send|list [clean]] : Manipula emails"; echo
     log_action_begin_msg " - band [if]                : Lista Classificacao de Pacotes"; echo
     log_action_begin_msg " - cache                    : Lista os maiores objetos no cache (ultimo log)"; echo
     log_action_begin_msg " - mon [continue]           : Monitora bloqueios do firewall"; echo
     log_action_begin_msg " - moncache [continue]      : Monitora acessos a paginas"; echo
     log_action_begin_msg " - mondns   [continue]      : Monitora acessos a dns"; echo
     log_action_begin_msg " - monterm                  : Ativa monitores em nos TTYs[5-12] "; echo
     log_action_begin_msg " ----------------------------------------------------------------------------"; echo
}
#------------------------------------------------------------------------
MONTERM () {
    killall tail > /dev/null 2> /dev/null 
    #clear > /dev/tty5  ; $TAIL -n 10 --sleep-interval=$SLEEPMON -f xxxx.log > /dev/tty5 2> /dev/null& 
    clear > /dev/tty11  ; $0 moncache continue > /dev/tty11 &
    clear > /dev/tty12 ; $0 mon continue > /dev/tty12 &
}


#------------------------------------------------------------------------
MON () {
    clear
    service rsyslog reload
    printf "*----------------MENSAGENS LOG PARA BLOQUEIOS DO FIREWALL--------------*\n"
    printf "*                                               CTRL+C para terminar...*\n"
    if [ "$2" = "cat" ] ; then
	CMDTYPE="$CAT"
        LOGVW="${LOGFW}.1 $LOGFW"
    elif [ "$2" = "tail" ] || [ -z "$2" ]; then
	CMDTYPE="$TAIL --sleep-interval=$SLEEPMON --lines=$LINES -f"
    else 
	CMDTYPE="$TAIL --lines=$LINES"
    fi 
    if [ "$3" != "" ]; then
	LOGVW=$3
    else
	LOGVW=$LOGFW
    fi
    #iptables -p icmp -h
    $CMDTYPE $LOGVW | $GAWK -F " " '{ 
      $201 = ENVIRON["COLUMNS"] + 0;
      if ( match($5$6$7$8$9,"kernel:.*Pkt:") ) {
	// INICIO - Criar array chamada IPT
	delete ipt; 
	split($0, colunas, " ");
	for (i=1; i <= length(colunas); i++) {
	    delete param;
	    split(colunas[i], param, "=");
	    if (length(param) == 2) {
		j=0; 
		while (ipt[gensub("([[]|[]])","","G",param[1])j] != "" ) { j++ }; 
		ipt[gensub("([[]|[]])","","G",param[1])j]=param[2];
	    }
	}
	// TERMINO - Fim da criacao array chamada IPT

	// INICIO - Saida Tela
        if ($201 > 100) {
            printf("%20-s %3-s/%2-s %8-s ",ipt["flag0"],$1,$2,$3);              //Carimbo de flag tripla e hora
        } else if ($201 > 75) {
            printf("%3s %8-s", substr(ipt["flag0"],1,3),$3);                    //Carimbo minimo
        } else {
	    printf("%3s", substr(ipt["flag0"],1,3));
	}
	printf("%4s ", ipt["PROTO0"]); 		                	        //Protocolo

	if (ipt["PROTO0"] != "ICMP") {
	    if ( (ipt["IN0"] != "") && (ipt["OUT0"] != "") ) {
	        printf("%5s:%16-s %3s%s%3s %5s:%16-s ",ipt["SPT0"], ipt["SRC0"], ipt["IN0"]," >> ", ipt["OUT0"], ipt["DPT0"], ipt["DST0"]) ;   //FORWARD
	    } else if ( (ipt["OUT0"] != "") ){
		printf("%5s:%16-s %3s%s%3s %5s:%16-s ",ipt["SPT0"], ipt["SRC0"], ipt["OUT0"]," -> ", ipt["OUT0"], ipt["DPT0"], ipt["DST0"]) ;   //SAIDA
	    } else if ( (ipt["IN0"] != "") ){
	        printf("%5s:%16-s %3s%s%3s %5s:%16-s ",ipt["DPT0"], ipt["DST0"], ipt["IN0"], " <- ", ipt["IN0"], ipt["SPT0"], ipt["SRC0"]) ;    //ENTRADA
	    }
	} else {
	    if ( (ipt["IN0"] != "") && (ipt["OUT0"] != "") ) {
	        printf("%5s %16-s %3s%s%3s %5s %16-s ","", ipt["SRC0"], ipt["IN0"], " >> ", ipt["OUT0"], "", ipt["DST0"]) ;   		        //FORWARD
	    } else if ( (ipt["OUT0"] != "") ){
	        printf("%5s %16-s %3s%s%3s %5s %16-s ","", ipt["SRC0"], ipt["OUT0"], " -> ", ipt["OUT0"], "", ipt["DST0"]) ;   			//SAIDA
	    } else if ( (ipt["IN0"] != "") ){
	        printf("%5s %16-s %3s%s%3s %5s %16-s ","", ipt["DST0"], ipt["IN0"]," <- ",ipt["IN0"], "", ipt["SRC0"]) ;                    	//ENTRADA
	    }
	}

	if ($201>128) {
	    if (ipt["MAC0"] != "") {
		printf("%18-s", substr(ipt["MAC0"],19,17));	//MAC ADDRESS
	    }
    	    if (ipt["TTL0"] != "") {
		printf("ttl=%3-s ",ipt["TTL0"]); //Time to Live
	    }
	    if (ipt["LEN0"] != "") {
		printf("len=%4-s ",ipt["LEN0"]); //Tamanho Pacote
	    }
	    if ( (ipt["PREC0"] != "") ) {
		printf("prec=%s ",substr(ipt["PREC0"],3)); //Precedence packet
	    }
	    if ( (ipt["TOS0"] != "") ) {
		printf("tos=%s ",substr(ipt["TOS0"],3)); //Type of Service
	    }
	    if (ipt["MARK0"] != "") {
		printf("m=%s ", substr(ipt["MARK0"],3,6));	//MARK PACOTE
	    }
	    if ( (ipt["URGP0"] != "") && (ipt["URGP0"] != "0") ) {
		printf("urg=%s ",ipt["URGP0"]); //Urgent Pointer
	    }
	    if ( (ipt["RES0"] != "") && (ipt["RES0"] != "0x00") ) {
		printf("res=%s ",substr(ipt["RES0"],3)); //Bits Reservados
	    }
	    if ( (ipt["UID0"] != "") || (ipt["GID0"] != "") ) {
		printf("uid=%s,gid=%s ",ipt["UID0"],ipt["GID0"]); //Bits Reservados
	    }
	}

	//Exibe qual significado para o pacote ICMP caso esteja vinculado a algum host
	if (ipt["PROTO0"] == "ICMP") { 
	    printf(" t%s.c%s ",ipt["TYPE0"],ipt["CODE0"]); //CODIGO ICMP
	    if ( (ipt["DST1"] != "") && (ipt["SRC1"] != "") ) {
		if ( (ipt["DPT0"] != "") && (ipt["SPT0"] != "") ) {		//Caso tenha porta vinculadas
    		    if ( (ipt["IN0"] != "") && (ipt["OUT0"] != "") ) {
			printf("[%5s:%16-s %s %5s:%16-s",ipt["DPT0"], ipt["DST1"], " << ", ipt["SPT0"], ipt["SRC1"]) ;  //ENTRADA
		    } else if ( (ipt["OUT0"] != "") ){
			printf("[%5s:%16-s %s %5s:%16-s",ipt["DPT0"], ipt["DST1"], " <- ", ipt["SPT0"], ipt["SRC1"]) ;  //Referente para qual Entrada
		    } else if ( (ipt["IN0"] != "") ){
			printf("[%5s:%16-s %s %5s:%16-s",ipt["SPT0"], ipt["SRC1"] ," -> ", ipt["DPT0"], ipt["DST1"]) ;  //Referente para qual Saida
		    }
		} else {
    		    if ( (ipt["IN0"] != "") && (ipt["OUT0"] != "") ) {
			printf("[%16-s %s %16-s",ipt["DST1"], " << ", ipt["SRC1"]) ;  //ENTRADA
		    } else if ( (ipt["OUT0"] != "") ){
			printf("[%16-s %s %16-s",ipt["DST1"], " <- ", ipt["SRC1"]) ;  //Referente para qual Entrada
		    } else if ( (ipt["IN0"] != "") ){
			printf("[%16-s %s %16-s",ipt["SRC1"] ," -> ", ipt["DST1"]) ;  //Referente para qual Saida
		    }
		}
		if ( (ipt["TYPE1"] != "") && (ipt["CODE1"] != "") ) {
		    printf(" t%s.c%s",ipt["TYPE1"],ipt["CODE1"]); //CODIGO ICMP Interno
		}
		printf ("] ");	//Fechar barra
	    }
	}

	printf("\n");		//Pula linha
	// FIM - Saida Tela
      }
    }'
}

#------------------------------------------------------------------------
MONMAC () {
    clear
    printf "*----------------MENSAGENS LOG PARA BLOQUEIOS DE MAC --------------*\n"
    printf "* Lamento, mas nao implementado ... *\n"
    #Exibir apenas as ultimas linhas, ou.... todo o log?
    if [  "$2" = "" ] ; then
      CMD="$TAIL --lines=$LINES --sleep-interval=$SLEEPMON -f"
    else
      CMD="$CAT"
    fi
    exec | $CMD $LOGSSYS | $GAWK -F " " '{
    if ( ($5$6$7 == "kernel:Pkt:m") ) {
        printf("%s%7-s ",$7,$3) ;
        if ((substr($8,4) != "" ) && (substr($9,5) != "")) {
            if ($17 == "DF") { printf("%4s %5s:%15-s%s%5s:%15-s\n",substr($18,7),substr($19,5),substr($10,5),"",substr($20,5),substr($11,5)) }
            else             { printf("%4s %5s:%15-s%s%5s:%15-s\n",substr($17,7),substr($18,5),substr($10,5),"",substr($19,5),substr($11,5)) };
        } else if (substr($8,4) != "" ) {
	    if ($18 == "DF") { printf("%4s %5s:%15-s%s%5s:%15-s %17-s\n",substr($19,7),substr($21,5),substr($12,5),"<",substr($20,5),substr($11,5),substr($10,23,17)) }
	    else             { printf("%4s %5s:%15-s%s%5s:%15-s %17-s\n",substr($18,7),substr($20,5),substr($12,5),"<",substr($19,5),substr($11,5),substr($10,23,17)) };
	} else if (substr($9,5) != "") {
    	    if ($17 == "DF") { printf("%4s %5s:%15-s%s%5s:%15-s\n",substr($18,7),substr($19,5),substr($10,5),">",substr($20,5),substr($11,5)) }
    	    else             { printf("%4s %5s:%15-s%s%5s:%15-s\n",substr($17,7),substr($18,5),substr($10,5),">",substr($19,5),substr($11,5)) };
    	} else {
	    printf("???");
	}
    } } '
}
#logformat especial %{%F %H:%M:%S}tl %6tr %>A %Ss/%03>Hs %<st %rm %ru %[un %Sh/%<a %mt %>eui "%{User-Agent}>h" "%{Referer}>h"
MONSQUID () {
    # TERMWIDTH=${COLUMNS}
    clear
    printf "*--------------------MENSAGENS LOG PARA ACESSOS DO SQUID---------------*\n"
    printf "*                                               CTRL+C para terminar...*\n"
    if [ "$2" = "cat" ] ; then
	CMDTYPE="$CAT"
    elif [ "$2" = "tail" ] || [ -z "$2" ]; then
	CMDTYPE="$TAIL --sleep-interval=$SLEEPMON --lines=$LINES -f"
    else 
	CMDTYPE="$TAIL --lines=$LINES"
    fi 
    $CMDTYPE $LOGSSQUID | $GAWK -F " " '{
                  $101 = (match($5,"_MISS") != 0)    ? " " : "?" ;
                  $101 = (match($5,"_ABORTED") != 0) ? "~" : $101;
                  $101 = (match($5,"_REFRESH") != 0) ? "#" : $101;
                  $101 = (match($5,"_HIT") != 0)     ? "+" : $101;
                  $101 = (match($5,"_DENIED") != 0)  ? "!" : $101;
                  $101 = (match($5,"_TUNNEL") != 0)  ? "*" : $101;
		  $201 = (ENVIRON["COLUMNS"]-70);
                  printf("%s %1-s %15-s %s%s %7.1fk %7.1fs %11-s %s\n",$1,$2,gensub("[.].*[.]localnet","","G",$4),substr($7,1,1),$101,($6/1024),($3/1000),substr(gensub("/.*","","G",$11),1,12),substr(gensub("http://","","G",$8),1,$201)) ;
	     } '
   #cat /var/log/squid3/access.log | awk '{ print $(NF) }' | sort | uniq -c
   #if [ ! "$2" = "continue" ] ; then
   #        exec login 
   #fi
}

#------------------------------------------------------------------------
#Short cut -c 1-20,23-38,60-
MONNAMED () {
    clear
    printf "*--------------------MENSAGENS LOG PARA ACESSOS DO NAMED---------------*\n"
    printf "*                                               CTRL+C para terminar...*\n"
    if [ "$2" = "cat" ] ; then
	CMDTYPE="$CAT"
    elif [ "$2" = "tail" ] || [ -z "$2" ]; then
	CMDTYPE="$TAIL --sleep-interval=$SLEEPMON --lines=$LINES -f"
    else 
	CMDTYPE="$TAIL --lines=$LINES"
    fi 
    $CMDTYPE $LOGSNAMED | $GAWK -F " " '{ 
	    if (substr($6,1,match($6,"#")-1) != "127.0.0.1") {
              printf("%s %8-s %s %18-s %3-s %5-s %7-s %s\n",$1,substr($2,1,8),substr($9,1,1),substr($6,1,match($6,"#")-1),$12,$13,$14,$11) ;  
	    }
    } '
    #if [ ! "$2" = "continue" ] ; then
    # exec login 
    #fi
}


#------------------------------------------------------------------------
INSTALL () {
    if [ "$0" != "${D_FW}iptables.sh" ]; then
        log_action_begin_msg "Execurte o arquivo em ${D_FW}iptables.sh" 
        log_failure_msg
	exit 1
    fi
    log_action_begin_msg "Instalando arquivos do firewall..." && {
    if [ -f /etc/init.d/firewall ]; then 
        log_failure_msg 
    else 
       log_action_end_msg $? 
    fi
    if [ $0 == "/etc/init.d/firewall" ]; then
        log_action_begin_msg "Copie este arquivo para /etc/firewall e execute..." 
        log_failure_msg
	exit 1
    fi 
    if [ -f /etc/init.d/firewall ]; then
        log_action_begin_msg "Arquivo EXISTENTE -> " 
	rm -i /etc/init.d/firewall
    fi
    if [ -f /etc/init.d/firewall ]; then
        log_action_begin_msg "Arquivos de Firewall ja existentes..." 
        log_failure_msg
	exit 1
    fi
    update-rc.d    firewall disable > /dev/null # 2> /dev/null
    update-rc.d -f firewall remove  > /dev/null # 2> /dev/null
    cp -f $0 /etc/init.d/firewall
    ln -f -s /etc/init.d/firewall /etc/ppp/ip-up.d/firewall
    ln -f -s /etc/init.d/firewall /sbin/firewall
    log_action_begin_msg "Arquivos instalados com sucesso..." 
    logger -p authpriv.info -t FIREWALL Instalado!
    log_action_end_msg $?
    update-rc.d firewall defaults
    update-rc.d firewall enable > /dev/null # 2> /dev/null
    # update-rc.d firewall start 90 2 3 4 5 . stop 80 0 1 6 . > /dev/null # 2> /dev/null
    # update-rc.d fail2ban enable
    $0 help
    # run-parts /etc/ppp/ip-up.d --arg="$1" --arg="$2" --arg="$3" --arg="$4" --arg="$5" --arg="$6"
   } 
}
#############################################################################
testes_basicos      #Testes basicos e inclusao de bibliotecas
variaveis_basicas   #Variaveis Globais Basicas
. "$D_FW"configs.ini

echo Executando Firewall: "$*"
#-------------------------Chamada de Funcoes Principal---------------------#
case "$1" in
  mark)
	QOSSET "reload"
  ;; 
  test)
    grfile_params "$F_ACCHST1 $F_ACCHST2"
  ;;
  dhcpflush)
     service isc-dhcp-server stop
     rndc thaw
     service bind9 stop
     find /etc/bind/zones/ | grep jnl | xargs rm
     service bind9 start
     service isc-dhcp-server start
  ;;
  conntrack)
    conntrack -E --event-mask NEW
  ;;
  listpackages)
    dpkg-query -W -f '${status} ${package} ${version}\n' | sed -n 's/^install ok installed //p'
    # dpkg -l
  ;;
  promisc)
    ifconfig eth0:99 169.254.1.1 netmask 255.255.0.0 up
    ifconfig eth0 promisc
    trafshow -i eth0
    ifconfig eth0 -promisc
    ifconfig eth0:99 169.254.1.1 netmask 255.255.0.0 down
  ;;
  openports)
   netstat -tulpn
     ;;
  connections)
   netstat -tue
    ;;
  martian|martians|badmac|bad|macbad|mac)
        martiansource $*
    ;;
  bandstart)
	SHAPERSTOP			#Shaper Stop
	SHAPERSTART 			#Shaper Start
    ;;
  bandopen)
	SHAPERSTOP			#Shaper Stop
    ;;
  bandsimp)
	SHAPERSIMP			#Banda simples
    ;;
#  routereload)
#        makeroutes 			#Multiplas Rotas ou nao (equalize)
#    ;;
  status)
      STATUS $*
    ;;
  dynaccess)
    DYNACCHST "crontab"
  ;;
  dshield)
    DSHIELD "crontab"			#Crontab do Dshield
  ;;
  start)
    logger -p authpriv.info -t FIREWALL Iniciado!	#Logger sistema
    echo $VERSAO			#Copyright
    sync; sleep 1; sync			#sync no disco para evitar travar
    #ip route del 0/0			#Remover todas as rotas
    #if [ "`grok_interface ppp0`" == "1" ]; then
    #   ip route add default dev ppp0
    #fi
    SETPROC				#Seta systema proc, otimizando sistema
    SHAPERSTOP				#Shaper Stop
    ABRIR				#Abrir tudo (para tornar transparente)
#   makeroutes 				#Multiplas Rotas ou nao (equalize)
    LIMPAR				#Limpa diretivas
    LOGSET				#Inicializa Log em messages
    ESPECIFICAS 			#Dhcp, ntp, trace etc...
    MACACC 		   		#Filtro de MAC ADDRES por liberacao
    MACFIX				#Filtro de MAC ADDRES via dhcp
    NAT					#Mascaramento externo caso seja ip real. 
    #SSH				#Abrir gerenciamento SSH
    MARKLOCAL				#Seta Mark redes locais
    QOSSET				#Seta QOS 
    SHAPERSTART				#Shaper Start
    SCANDETECT				#Detecta Flags Maliciosas
    #HOSTSADM				#Hosts Administrativas
    REDIR				#Redirecionamentos e DMZ		 
    ACESSOS				#Lista de acessos			 
    DYNACCHST				#Acessos Dinamicos
    UPNP				#UPNP, Servidor linux-igd, /etc/upnpd.conf, /etc/default/linux-igd
    LOGSTART 				#Inicia log com pacotes rejeitados 
    FECHAR 				#Fecha portas
    SSHKNOCK				#Port Knock Open
    TERCEIROS				#Reload software terceiros tipo fail2ban
    HSTBLK				#Bloqueio de hosts
    DSHIELD				#Dshield Inicial Startup
    #$0 DDNS 2> /dev/null > /dev/null &  # DDNS
    #$0 monterm				#Telas de console de monitoramento filtradas
  ;;
  open|abrir)
    LIMPAR				#Limpa diretivas
    ABRIR				#Abrir tudo (para tornar transparente)   (Antes do REDIR)
    SSH					#Abrir gerenciamento SSH tambem explicitamente
#   makeroutes 				#Multiplas Rotas ou nao
    NAT 				#Mascaramento externo caso seja ip real	 (Apos o Masq)
    UPNP				#UPNP, Servidor linux-igd, /etc/upnpd.conf, /etc/default/linux-igd
#   REDIR				#Redirecionamentos e DMZ		 (Apos o MASQ)
    SHAPERSTOP				#Para shaper
  ;;
  stop)
    LIMPAR				#Limpa diretivas
    ABRIR				#Abrir tudo (para tornar transparente)   (Antes do REDIR)
    SSH					#Abrir gerenciamento SSH tambem explicitamente
#   makeroutes 				#Multiplas Rotas ou nao
    NAT 				#Mascaramento externo caso seja ip real	 (Apos o Masq)
    SHAPERSTOP				#Para shaper
  ;;
  DDNS)
    sync
    DDNS 				#Atualizar DDNS
  ;;
  help)
    HELP $*
  ;;
  install)
     #em ipsec.conf adicionar na conexao: rightupdown="/sbin/firewall ipsec0"
     INSTALL $*
  ;;
  cacheconfig)
    squid3 -k parse
  ;;
  cache)
     # $SORT -r -n +4 -5 $LOGSSQUID | $GAWK '{print $5/1024,$7}' | head -25
     log_action_begin_msg "Aguarde alguns instantes..."; log_action_end_msg $?
     $SORT -r -n +4 -5 $LOGSSQUID | $GAWK -F " " '{ printf("%1-s %18-s %5ik %s\n",substr($6,1,1),substr($3,1,18),int($5/1024),substr(gensub("http://","","G",$7),1,100)) ; }' | head -30
    ;;
  cachebad)
     cat $LOGSSQUID | egrep "[.]cab|[.]exe" | sed -e 's/.*\(HEAD\|GET\) //g' | cut -f1 -d" " | $SORT | $UNIQ
    ;;
  band) 
    OPT="-s -d" #opcoes -s -d
    $TC $OPT qdisc ls dev $2 
    #echo --------------------------------------------------------------- 
    $TC $OPT class ls dev $2
    #echo --------------------------------------------------------------- 
    #$TC $OPT filter ls dev $2 
    ;;
  monband)
    #tc -s filter show dev imq0
    #tc -s class show dev imq0
    #tc -s qdisc show dev imq0
    if [ -z "$2" ]; then	
        echo Use monband interface
    else
	#watch -n 1  tc -s -d filter show dev $2
	#watch -n1 tc -s class show dev imq0
	watch -n 1 tc -s -d qdisc show dev $2
    fi
    ;;
  cpu)
     mpstat -P ALL 
     mpstat -P ALL 10
    ;;
  macaccess)
    MACACC "reload"
    MACFIX "reload"
    ;;
  monterm)
      MONTERM $*
    ;;
  moncache)
      MONSQUID $*
   ;;
  mondns)
      MONNAMED $*
   ;;
  mon)
     MON $*
  ;;
  hank)
    echo Operacao demorada.. aguarde!
    $0 mon cat > /tmp/hank_all.log
    cat /tmp/hank_all.log | cut -c85-99 | sort | uniq -d -c | sort -g -r | head -1000 > /tmp/hank_ext.log
    cat /tmp/hank_all.log | cut -c49-63 | sort | uniq -d -c | sort -g -r | head -1000 > /tmp/hank_int.log
    echo Terminado! Verifique arquivos `ls /tmp/hank_*`
   ;;
  oldkernel)
    aptitude search ~ilinux-headers ~ilinux-image
    ;;
  monmac)
     MONMAC $*
   ;;
  detect)
    lshw -class network
   ;;
  proc)
      ps -eo pid,user,group,%mem,%cpu,args --sort user
   ;;
  mail)
      MAIL $*
   ;;
  monport)
      #tcpdump -i eth0 -qlNnn dst net 65.49.2.0/24 and dst port 443
      if [ -z "$2" ]; then
	echo "Digite '$0 443' ou '$0 443 65.49.2.0/24' por exemplo..."
      elif [ ! -z "$3" ]; then
        tcpdump -i eth0 -qlNnn dst port $2 and dst net $3
      else 
        tcpdump -i eth0 -qlNnn dst port $2
      fi
   ;;
  reload)
    if [ ! -z "`lsmod | grep ^ip_tables`" ]; then
	#Recarrega tudo caso nao especificado ou a inteface especificada apenas...
	# WAITUP "1" "1" "$2"
	logger -p authpriv.info Firewall: $* 
	makeroutes 				#Multiplas Rotas ou nao
	MARKLOCAL 	"reload"		#Remarca locais
	MARKREMOT	"reload"		#Marcar Remoto
	SHAPERSTOP	"$2"			#Parar Shaper
	SHAPERSTART	"$2"			#Shaper Start
	#$0 DDNS 2> /dev/null > /dev/null &
	NAT "reload"			#Nat 
	REDIR "reload"			#Redirecionamentos e DMZ
    fi
   ;;
   *)
    # echo Executando Firewall: $*
    if [ ! -z "$*" ]; then
        logger -p authpriv.info -t FIREWALL Iniciado: "$*" 	#Logger sistema
        if [ ! -z "`pidof named`" -a ! -z "`lsmod | grep ^ip_tables`" ]; then
	    #Caso o parametro passado seja uma interface valida, da reload na interface
    	    #.$DEV_EXT.$DEV_ADM.$DEV_CLI.$DEV_SRV.$DEV_MSQSRV. 
    	    if [ ! -z "`echo .$DEV_EXT.$DEV_MSQSRV. | $EGREP -E ""$1""`" ]; then  #Aguarda caso seja interface externa
		$0 reload $1
	    fi
	fi
    else
	# Caso nao tenha interface passada, tenta adivinhar de onde o comando foi executado...
	DIRNAME="`dirname $0`"
	BASENAME="`basename $DIRNAME`"
	case "$BASENAME" in
	    if-up.d | ip-up.d)
	       $0 reload
    	    ;;
	    *)
		HELP
	    ;;
	esac
    fi
   ;;
esac

exit 

#https://isc.sans.edu/ipinfo.html?ip=10.0.0.1
#https://isc.sans.edu/port.html?port=17500

## Only split on newlines, so each line of data is one record.
#default_IFS=$IFS
#IFS="$(echo -e "\n\r")"
## each $line will be one line, even if there are spaces in it.
#for line in $(cat sample_data.txt) ; do
#    # do stuff...
#done
## Restore default
#IFS=$default_IFS


#chown -R dhcpd:dhcpd /var/lib/dhcp
#sudo setfacl -dm u:dhcpd:rwx /var/lib/dhcp
#sudo setfacl -m u:dhcpd:rwx /var/lib/dhcp
#service --status-all