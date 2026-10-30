#!/bin/bash
###########################################################################
#     Feito por Silmar A. Marca      smarca@gmail.com                     #
###########################################################################
#  *  A remocao destas linhas implica na nao observacao da licenca GNU *  #
#  *  Informe o autor sobre falhas ou incremento de funcoes            *  #
#  *  Respeite a propriedade intelectual, http://www.gnu.org/          *  #
###########################################################################

###############################################################################
# Limpa tabelas antigas rules e rotas
flushrules () {	
  #Limpar tabelas antigas
  $PIP rule | $EGREP -E -v "all" | while read id from ipid lookup table; do
    $PIP route flush table $table 		2> /dev/null
    $PIP rule del from $ipid lookup $table  	2> /dev/null
   done
}
###############################################################################
# Faz as tabelas de rotas default e rotas ponto a ponto
makerules () {	
      #Rules: Rota DEFAULT /etc/sysconfig/network
      #. /etc/sysconfig/network
      #if [ ! -z "$GATEWAY" -a ! -z "$GATEWAYDEV" ]; then
      #    $PIP rule add from `grok_addr $GATEWAYDEV` lookup 1 
      #    $PIP route | $EGREP -E ".*\/.*proto kernel.*scope link" | while read netA opt1 op2 op3 op4 op5 op6 op5 srcA; do #Redes Redes Locais Apenas
      #	    $PIP route add $netA via $srcA table 1
      #    done
      #    $PIP route add 0/0 via $GATEWAY table 1
      #fi
      #Rules: Outras Rotas PAP
      TABL=2
      $PIP addr list  | $EGREP -E  "^(.* inet .* peer .* scope global .*)$" | while read opA1 srcA opA2 netA opA3 opA4 devA; do
	if [ "`echo .$DEV_EXT. | $EGREP -E $devA`" != "" ]; then
    	    $PIP rule add from $srcA lookup $TABL
    	    $PIP route | $EGREP -E ".*\/.*proto kernel.*scope link" | while read netA opt1 op2 op3 op4 op5 op6 op5 srcA; do #Redes Redes Locais Apenas
		$PIP route add $netA via $srcA table $TABL
    	    done
    	    $PIP route add 0/0 via `echo $netA| $GAWK -F/ '{ print $1 } '` table $TABL 2> /dev/null   
	fi
	TABL=$[$TABL + 1];
      done
}
###############################################################################
# Retorna comando com as rotas default segundo rules
##ip rule add fwmark 2 table 20 prio 20
 #ip route add default via $GW_ADSL2 dev $IF_ADSL2 table 20

cmd_rotadef () {
    TABL=0
    echo -n $PIP route add default $1
    $PIP rule | $EGREP -E -v "all" | while read id from ipid lookup table; do
          TABL=$[$TABL + 1];
          $PIP route list table $table | $EGREP -E "default" | while read opA1 opA2 srcA optA3 devA; do
            if [ "`grok_interface $DEV_GWT`" == "1" ]; then
                if [ "`echo .$DEV_GWT. | $EGREP -E $devA`" != "" ]; then
                    echo -n "$CMDRTR nexthop weight $TABL via $srcA dev $devA "
                fi
            elif [ "`grok_interface $DEV_GWTBKP`" == "1" ]; then
                if [ "`echo .$DEV_GWTBKP. | $EGREP -E $devA`" != "" ]; then
                    echo -n "$CMDRTR nexthop weight $TABL via $srcA dev $devA "
                fi
            fi
          done
    done
}
###############################################################################
# Faz as tabelas completamente 
# Parametros: Nada ou "equalize"
makeroutes () {	
      #Limpa rotas antigas e Rules
      flushrules
      # Faz as tabelas de rotas default e rotas ponto a ponto
      makerules
      # Route: default
      $PIP route del default 2> /dev/null
      `cmd_rotadef $1` 2> /dev/null
      #Flush no cache de rotas do kernel
      $PIP route flush cache
}
###############################################################################
# Retorna se 1 a interface esta ativa, 0 se inativa
# Parametros: $1 (InterfaceX)
grok_interface () {
if [ ! -z "`$PIP addr | $EGREP -E "global.*$1$"`" ]; then 
  echo "1" 
 else 
  echo "0"
fi
}
###############################################################################
# Retorna IP da interface
# Parametros: $1 (InterfaceX)
grok_addr () {
  declare -f IP
  if [ "`isip $1`" == "1" ]; then
      IP="$1"
  else
      IP=`$PIP addr | $EGREP -E "global.*$1$" |  $GAWK '{ print $2 }' | cut -f1 -d "/" | head -1`
  fi
  [ -z $IP ] && IP="$2"
  echo -e "$IP"
}
###############################################################################
# Retorna IP
# Parametros: $1 (InterfaceX)
grok_bcast () {
  declare -f BCAST
  if [ "`isip $1`" == "1" ]; then
      BCAST="$1"
  else	  
      BCAST=`$PIP addr | $EGREP -E "brd.*global.*$1$" | $GAWK '{ print $4 }' | head -1`
  fi
  [ -z $BCAST ] && BCAST=`grok_addr $1`
  echo -e "$BCAST"
}
###############################################################################
# Retorna Network/Mascara
# Parametros: $1 (InterfaceX)
grok_netmask () {
  declare -f NET
  declare -f RNAME
  if [ "`isip $1`" == "1" ]; then
      NET="$1"
  else
      NET=`$PIP addr | $EGREP -E "global.*$1$" |  $GAWK '{ print $2 }' | head -1`
  fi
  [ -z $NET ] && NET="$2"
  echo -e "$NET"
}
###############################################################################
# Retorna Peer ponto a ponto
grok_pap () {
  declare -f IP
  if [ "`isip $1`" == "1" ]; then
      IP="$1"
  else	  
      IP=`$PIP addr | $EGREP -E "peer.*global.*$1$" |  $GAWK '{ print $4 }' | cut -f1 -d "/" | head -1`
  fi
  [ -z $IP ] && IP="$2"
  echo -e "$IP"
}

###############################################################################
# Retorna Interfaces configuradas (Todas inclusive apelidos)
# Parametros: N/A
grok_interfaces () {
  if [ -z "$1" ]; then
	echo `ip addr | grep "scope global" | $GAWK '{ print $7 }'`
  else
	echo `ip addr | grep "scope global $1$" | $GAWK '{ print $7 }'`
  fi
}
# Retorna Interfaces configuradas (Todas menos apelidos)
grok_interfacesreal () {
  if [ -z "$1" ]; then
	echo `ip addr | grep "scope global" | $GAWK '{ print $7 }' | grep -v ":"`
  else
	echo `ip addr | grep "scope global $1$" | $GAWK '{ print $7 }' | grep -v ":"`
  fi
}

############################################################################
# Retorna se host REAL (0) ou INTERNA (1 2 3 4)
# Parametros: InterfaceX (preferencialmente a interna...)
isfalseinter () {
   IP=`grok_addr $1`
   echo -e `isfalsehost $IP`
}
############################################################################
# Retorna gateway default
grok_defgw () {
   echo -e `route -n| $GAWK '$1=="0.0.0.0" {print $2}'|head -1`
#   echo -e `ip route | $GAWK '$1=="default" {print $5}'|head -1`
}
############################################################################
# Retorna interface gateway default
grok_defif () {
   echo -e `route -n| $GAWK '$1=="0.0.0.0" {print $8}'|head -1`
}
############################################################################
# Retorna ip externo ao gateway default
grok_defip () {
   EXTIF=`grok_defif`
   echo -e `grok_addr $EXTIF`
}

############################################################################
# Retorna se host REAL (0) ou INTERNA (1 2 3 4)
# Parametros: Net (preferencialmente a interna...)
isfalsehost () {
declare -i MASQUERADE
MASQUERADE="0"
if [ $# = 1 ]; then
  declare -i DOTQUAD1
  declare -i DOTQUAD2
  DOTQUAD1=`echo $1 | cut -f1 -d.`           
  DOTQUAD2=`echo $1 | cut -f2 -d.`
  if [ "$DOTQUAD1" = "10" ]; then   
      #Rede Classe A: modo Masq (reenvio de pacotes)"
      MASQUERADE="4"
   elif [ "$DOTQUAD1" = "172" -a $DOTQUAD2 -gt 15 -a $DOTQUAD2 -lt 32 ]; then
      #Rede Classe B: modo Masq (reenvio de pacotes)"
      MASQUERADE="3" 
   elif [ "$DOTQUAD1" = "192" -a "$DOTQUAD2" = "168" ]; then          
      #Rede Classe C: modo Masq (reenvio de pacotes)"
      MASQUERADE="2" 
   elif [ "$DOTQUAD1" = "127" -a "$DOTQUAD2" = "0" ]; then
      #Simulacao por LoopBack: modo Masq (reenvio de pacotes)"
      MASQUERADE="1"
   else
      #> Hosts Reais: modo Router (roteamento de pacotes)"
      MASQUERADE="0"
  fi
fi
echo $MASQUERADE                    
}
#################################################################
#Pega um arquivo contendo portas que devem ser fechadas, abertas etc
#Para comentar uma linha use #
grfile_params () {
   $EGREP -E -h -v "^#|^\$" $* | cut -d"#" -f 1-${2} | cut -d" " -f 1-${2}
   #$EGREP -E -h -v "^#|^\B" $*  | cut -d"#" -f 1-${2} | cut -d" " -f 1-${2}
   #$EGREP -E -h -v "^#|^\B" $* | $GAWK -F " "  '{ printf("%s\n",$1); }'
   #echo -e `cat $1 | $GAWK -F " " '{ if (!match($1,"#")) { printf("%s\n",$1); } } '`
}
###############################################################################
# Retorna mesmo parametro da host caso exista ou o segundo parametro
# ipcalc --network 10.0.0.1 255.0.0.0 | sed s^NETWORK=^^g
get_ip () {
 if   [ "`ismac $1`" == "1" ]; then 
    echo -e "$1"
 elif [ "`isip $1`" == "1" ]; then 
    echo -e "$1"
 elif [ "$1" == "-" ]; then
    if [ "$2" == "-" ]; then
	echo -e ""
    else
	echo -e "$2"  
    fi  
 else
    HS=`echo $1 | $GAWK -F"/" '{ print $1 }'`
    MS=`echo $1 | $GAWK -F"/" '{ print $2 }'`
    if [ ! -z "$HS" ]; then
      IP=`host -R 1 -W 1 $HS | $EGREP -E "has address" | $GAWK '{ print $4 }'`
      if [ ! -z "$IP" ]; then
	if [ ! -z "$MS" ]; then
	     for NIP in $IP; do
	     echo -e $NIP/$MS 
	     done
	else 
	     for NIP in $IP; do
	     echo -e $NIP
	     done
	fi
      elif [ "$2" == "" ]; then
  	echo -e ""
      elif [ "$2" == "-" ]; then
     	echo -e ""  
      else
     	echo -e "$2"  
      fi
    else 
	echo -e "$1 $2"
    fi
 fi
}
###############################################################################
# Retorna IP do host
nfsports () {
 echo `rpcinfo -p | $EGREP -E $1 | $GAWK '{ print $4 }' | $SORT | $GAWK -F " " '{ if (A != $1) { printf("%s\n",$1); } A=$1; }'`
}
###############################################################################
# Retorna porta em numero ao invez de letras do services.. 
# Parametro: nome porta, protocolo : exemplo "www|ident" "tcp"
serviceport () {
  serv=`echo $1| tr "," "|" | expand`
  servnum=`echo $1| tr "," "\n" | $EGREP -E "^[0-9].+$" | tr "\n" " " |expand`
  portas=`cat /etc/services | $EGREP -E "^\<($serv)\>.*$2\>" | expand | cut -f 1 -d"/" | $GAWK " '{ printf("%s ",$2); }'`
  echo "$portas $servnum"
}


###############################################################################
# Verifica sintaxe de mac address
ismac () {
 if [ ! -z "`echo $1: | $EGREP -E '^([0-9A-Fa-f]{2}[:]){6}?$'`" ]; then
     echo "1"
 else
     echo "0"
 fi
}	    

###############################################################################
# Verifica sintaxe do ip, aceita host e host/xx
isip () {
 if [ ! -z "`echo $1 | $EGREP -E '^(([0-9]{1,3}[.]){3}([0-9]{1,3}))([/]([0-9]{1,2}))?$'`" ]; then
     echo "1"
 else
     echo "0"
 fi
}	    
###############################################################################
# Retorna o propio ip/rede/mac ou endereco do host 
ipofhost () {
  if [ "`isip $1`" == "1" ]; then
    echo $1
  elif [ "`ismac $1`" == "1" ]; then
    echo $1 XX
  else
    HOSTIP="`host -R 3 $1 | $EGREP -E  address | cut -f4 -d' '`"
    if [ "$HOSTIP" != "" ]; then
	echo $HOSTIP
    else
	echo $1
    fi
  fi
}

###############################################################################
WAITUP () {
    LOOP=0
    sleep $2
    while [ -z "`$ROUTE -n | $EGREP -E U.*$3`" -a "$LOOP" -lt "$1" ]; do
        LOOP=$[$LOOP+1]
        sleep $[$LOOP*10]
    done
    sleep $2
}
#------------------------------------------------------------------------
MAIL () {
    #Para debug: exim -bd -d
    #/usr/bin/exim.newaliases > /dev/null
    case $2 in
       send)
            /usr/sbin/exim -qqf -v
       ;;
       sendforce)
            /usr/sbin/exim -qqff -v
	    MAIL list clean
       ;;
       list)
            for msg in `mailq|awk '{print $3}'|$EGREP -E -v "^#|^\B"`; do
		echo "* ---------------"
                echo "Message ID: $msg"
                exim -Mvh $msg
                if [ "$3" == "clean" ]; then
                    echo -n "+> Delete this message <$msg> (Y/N)? "
                    read ans
                    if [ "$ans" = "Y" ] || [ "$ans" = "y" ]; then
                        exim -Mrm $msg
                    else
                        echo "+<Message $msg has been skipped..."
                    fi
                fi
		echo " "
            done
       ;;
       frozen)	
	    exiqgrep -z -i 
	    if [ "$3" == "clean" ]; then
		exiqgrep -z -i | xargs exim -Mrm
	    fi
       ;;
    esac
}
############################################################################
# DDNS GrupoGSN
# Parametros: NA
# http://ops.ietf.org/dns/dynupd/secure-ddns-howto.html
DDNS () {
if [ "$KEYNAMED" != "" ]; then
  WAITUP "30" "30" "$DEV_EXT"
  HOSTNAME="$(hostname | cut -d. -f1)"
  gprintf "DDNS ${HOSTNAME}.localhost... " && {
    NIP="`grok_addr $DEV_MSQSRV`"
    echo -n $NIP
    SERVER="ns1.grupogsn.com.br"
    ZONE="ddns.grupogsn.com.br"
    TTL="60"
    TXT="`date +%d/%m/%Y-%T-%Z`"
    RESULT=`nsupdate -v -k $KEYNAMED << EOF
            server $SERVER
            zone $ZONE
            update delete $HOSTNAME A
            update add $HOSTNAME $TTL A $NIP
            update delete $HOSTNAME MX
            update add $HOSTNAME $TTL MX 1 $HOSTNAME
            update delete $HOSTNAME TXT
            update add $HOSTNAME $TTL TXT $TXT
            send
        `
    logger -p authpriv.info -t DDNS $HOSTNAME $NIP Atualizado!
  } &&  echo_success; echo
 fi
}
#------------------------------------------------------------------------
STATUS () {
     gprintf " --[Conexoes atuais]----------------------------"; echo
     cat /proc/net/ip_conntrack | $EGREP -E -v "(TIME_WAIT)" | $SORT +4 | $GAWK -F " " '{
            if ($1 == "tcp") {
                printf("%3s %5s:%15-s -> %5s:%15-s %6s\n",$1,substr($7,7),substr($5,5),substr($8,7),substr($6,5),$4);
            } else if ($1 == "udp") {
                printf("%3s %5s:%15-s -> %5s:%15-s\n",$1,substr($6,7),substr($4,5),substr($7,7),substr($5,5));
            }

    }'
     printf " --[Processos/Portas]---------------------------"; echo
     lsof -i -U
     printf " --[Portas          ]---------------------------"; echo
     netstat -pae
     printf " --[Config Apache   ]---------------------------"; echo
     apachectl configtest
     printf " --[Suid Files      ]---------------------------"; echo
     find / -type f \( -perm -4000 -o -perm -2000 \)

}
#------------------------------------------------------------------------
DOWNLOAD () {
  nohup wget -i $1 --random-wait --limit-rate=10k  --tries=60 --wait=1m &
}

#------------------------------------------------------------------------
martiansource () {
    # ifconfig eth0:0 169.254.1.1 netmask 255.255.0.0
    # trafshow
    clear
    printf "*--------------------MENSAGENS ENDERECO ERRADO ------------------------*\n"
    if [ "$2" = "cat" ] ; then
        TYPEFW="cat $LOGMART"
    elif [ -z "$2" ]; then
        TYPEFW="$TAIL --sleep-interval=$SLEEPMON -f $LOGMART "
    else
        TYPEFW="$TAIL $LOGMART"
    fi
    $TYPEFW | $GAWK -F " " '{ 
        if (match($7$8,"martiansource") != 0) { 
            printf("%s %s %s - %5-s Dst: %18-s Src: %18-s",$1,$2,$3,$14,$9,substr($11,1,length($11)-1)); 
        } 
        if (match($7$8,"llheader") != 0) {
            printf("Mac: %s\n",substr($9,19,17)); 
        } 
    }'
}

###########################################################################
#Port Flood
#portflood "FORWARD" "300" "tcp:443 tcp:80" "150" "50/sec" "1000" "150/sec" "1000"
#Jaula temporaria  cat /proc/net/xt_recent/BLK_TEMP-tcp-443
#                  cat /proc/net/ipt_hashlimit/p443-sdp
#                  cat /proc/net/ipt_hashlimit/p443-sd
portflood () {
    FLD_MASKLOG=32	#mascara /24 /32
    FLD_EXPIRE=$2	#5minutos de punicao
    FLD_MAXCON=$4 				#maximo conexoes simultaneas em uma unica porta
    FLD_SD_LIM=$5  ; FLD_SD_INI=$6		#maximo conexoes simultaneas em uma unica porta de um unico destino (todas as portas observadas sao somadas)
    FLD_SDP_LIM=$7 ; FLD_SDP_INI=$8		#maximo conexoes simultaneas em uma unica porta de um unico destino (sem somar as portas observadas)
    for PORTA_ACC in $3; do
        $IPTABLES -w -t filter -F FLD_BLK-${PORTA_ACC:0:3}${PORTA_ACC:4}  2> /dev/null ; $IPTABLES -w -t filter -N FLD_BLK-${PORTA_ACC:0:3}${PORTA_ACC:4} 2> /dev/null
	$IPTABLES -w -t filter -F FLD_LOG-${PORTA_ACC:0:3}${PORTA_ACC:4}-sp   2> /dev/null ; $IPTABLES -w -t filter -N FLD_LOG-${PORTA_ACC:0:3}${PORTA_ACC:4}-sp 2> /dev/null
	$IPTABLES -w -t filter -F FLD_LOG-${PORTA_ACC:0:3}${PORTA_ACC:4}-sdp  2> /dev/null ; $IPTABLES -w -t filter -N FLD_LOG-${PORTA_ACC:0:3}${PORTA_ACC:4}-sdp 2> /dev/null
	$IPTABLES -w -t filter -F FLD_LOG-${PORTA_ACC:0:3}${PORTA_ACC:4}-sd   2> /dev/null ; $IPTABLES -w -t filter -N FLD_LOG-${PORTA_ACC:0:3}${PORTA_ACC:4}-sd  2> /dev/null
	$IPTABLES -w -t filter -F FLD_CHK-${PORTA_ACC:0:3}${PORTA_ACC:4}  2> /dev/null ; $IPTABLES -w -t filter -N FLD_CHK-${PORTA_ACC:0:3}${PORTA_ACC:4} 2> /dev/null

	$IPTABLES -w -t filter -A FLD_LOG-${PORTA_ACC:0:3}${PORTA_ACC:4}-sp  -m conntrack --ctstate NEW $LOG_LIMIT1_COMMAND blk-max-conn $LOG_LIMIT2_COMMAND --hashlimit-dstmask ${FLD_MASKLOG} -j LOG --log-prefix "Pkt: flag=blk-fld"${PORTA_ACC:0:3}${PORTA_ACC:4}"-sp " --log-tcp-options --log-ip-options  --log-uid 
	$IPTABLES -w -t filter -A FLD_LOG-${PORTA_ACC:0:3}${PORTA_ACC:4}-sdp -m conntrack --ctstate NEW $LOG_LIMIT1_COMMAND blk-max-conn $LOG_LIMIT2_COMMAND --hashlimit-dstmask ${FLD_MASKLOG} -j LOG --log-prefix "Pkt: flag=blk-fld"${PORTA_ACC:0:3}${PORTA_ACC:4}"-sdp " --log-tcp-options --log-ip-options  --log-uid 
	$IPTABLES -w -t filter -A FLD_LOG-${PORTA_ACC:0:3}${PORTA_ACC:4}-sd  -m conntrack --ctstate NEW $LOG_LIMIT1_COMMAND blk-max-conn $LOG_LIMIT2_COMMAND --hashlimit-dstmask ${FLD_MASKLOG} -j LOG --log-prefix "Pkt: flag=blk-fld"${PORTA_ACC:0:3}${PORTA_ACC:4}"-sd "  --log-tcp-options --log-ip-options  --log-uid 
	$IPTABLES -w -t filter -A FLD_LOG-${PORTA_ACC:0:3}${PORTA_ACC:4}-sp  -j DROP
	$IPTABLES -w -t filter -A FLD_LOG-${PORTA_ACC:0:3}${PORTA_ACC:4}-sdp -j DROP
	$IPTABLES -w -t filter -A FLD_LOG-${PORTA_ACC:0:3}${PORTA_ACC:4}-sd  -j DROP

	$IPTABLES -w -t filter -A FLD_BLK-${PORTA_ACC:0:3}${PORTA_ACC:4} -p ${PORTA_ACC:0:3} --dport ${PORTA_ACC:4} -m recent --update --name FLD_BLK-${PORTA_ACC:0:3}${PORTA_ACC:4}-sp  --reap --seconds ${FLD_EXPIRE}
	$IPTABLES -w -t filter -A FLD_BLK-${PORTA_ACC:0:3}${PORTA_ACC:4} -p ${PORTA_ACC:0:3} --dport ${PORTA_ACC:4} -m recent --update --name FLD_BLK-${PORTA_ACC:0:3}${PORTA_ACC:4}-sdp --reap --seconds ${FLD_EXPIRE}
	$IPTABLES -w -t filter -A FLD_BLK-${PORTA_ACC:0:3}${PORTA_ACC:4} -p ${PORTA_ACC:0:3} --dport ${PORTA_ACC:4} -m recent --update --name FLD_BLK-${PORTA_ACC:0:3}${PORTA_ACC:4}-sd  --reap --seconds ${FLD_EXPIRE}

	$IPTABLES -w -t filter -A FLD_BLK-${PORTA_ACC:0:3}${PORTA_ACC:4} -p ${PORTA_ACC:0:3} --dport ${PORTA_ACC:4} -m recent --update --name FLD_BLK-${PORTA_ACC:0:3}${PORTA_ACC:4}-sp  --reap --seconds ${FLD_EXPIRE} -j FLD_LOG-${PORTA_ACC:0:3}${PORTA_ACC:4}-sp #Hard
	$IPTABLES -w -t filter -A FLD_BLK-${PORTA_ACC:0:3}${PORTA_ACC:4} -p ${PORTA_ACC:0:3} --dport ${PORTA_ACC:4} -m recent --update --name FLD_BLK-${PORTA_ACC:0:3}${PORTA_ACC:4}-sdp --reap --seconds ${FLD_EXPIRE} -j FLD_LOG-${PORTA_ACC:0:3}${PORTA_ACC:4}-sdp #Hard
	$IPTABLES -w -t filter -A FLD_BLK-${PORTA_ACC:0:3}${PORTA_ACC:4} -p ${PORTA_ACC:0:3} --dport ${PORTA_ACC:4} -m recent --update --name FLD_BLK-${PORTA_ACC:0:3}${PORTA_ACC:4}-sd  --reap --seconds ${FLD_EXPIRE} -j FLD_LOG-${PORTA_ACC:0:3}${PORTA_ACC:4}-sd  #Hard

       #$IPTABLES -w -t filter -A FLD_BLK-${PORTA_ACC:0:3}${PORTA_ACC:4} -p ${PORTA_ACC:0:3} --dport ${PORTA_ACC:4} -m recent --rcheck --name FLD_BLK-${PORTA_ACC:0:3}${PORTA_ACC:4}-sp  --reap --seconds ${FLD_EXPIRE} -j FLD_LOG-${PORTA_ACC:0:3}${PORTA_ACC:4}-sp #Soft 
       #$IPTABLES -w -t filter -A FLD_BLK-${PORTA_ACC:0:3}${PORTA_ACC:4} -p ${PORTA_ACC:0:3} --dport ${PORTA_ACC:4} -m recent --rcheck --name FLD_BLK-${PORTA_ACC:0:3}${PORTA_ACC:4}-sdp --reap --seconds ${FLD_EXPIRE} -j FLD_LOG-${PORTA_ACC:0:3}${PORTA_ACC:4}-sdp #Soft 
       #$IPTABLES -w -t filter -A FLD_BLK-${PORTA_ACC:0:3}${PORTA_ACC:4} -p ${PORTA_ACC:0:3} --dport ${PORTA_ACC:4} -m recent --rcheck --name FLD_BLK-${PORTA_ACC:0:3}${PORTA_ACC:4}-sd  --reap --seconds ${FLD_EXPIRE} -j FLD_LOG-${PORTA_ACC:0:3}${PORTA_ACC:4}-sd  #Soft 

	$IPTABLES -w -t filter -A FLD_CHK-${PORTA_ACC:0:3}${PORTA_ACC:4} -p ${PORTA_ACC:0:3} --dport ${PORTA_ACC:4} -m connlimit --connlimit-above ${FLD_MAXCON} --connlimit-saddr -m recent --set --name FLD_BLK-${PORTA_ACC:0:3}${PORTA_ACC:4}-sp
	$IPTABLES -w -t filter -A FLD_CHK-${PORTA_ACC:0:3}${PORTA_ACC:4} -p ${PORTA_ACC:0:3} --dport ${PORTA_ACC:4} -m conntrack --ctstate NEW -m hashlimit --hashlimit-mode srcip,dstport       --hashlimit-above ${FLD_SD_LIM}  --hashlimit-burst ${FLD_SD_INI}  --hashlimit-htable-expire 300000 --hashlimit-name ${PORTA_ACC:0:3}${PORTA_ACC:4}-sd  -m recent --set --name FLD_BLK-${PORTA_ACC:0:3}${PORTA_ACC:4}-sd
	$IPTABLES -w -t filter -A FLD_CHK-${PORTA_ACC:0:3}${PORTA_ACC:4} -p ${PORTA_ACC:0:3} --dport ${PORTA_ACC:4} -m conntrack --ctstate NEW -m hashlimit --hashlimit-mode srcip,dstport,dstip --hashlimit-above ${FLD_SDP_LIM} --hashlimit-burst ${FLD_SDP_INI} --hashlimit-htable-expire 300000 --hashlimit-name ${PORTA_ACC:0:3}${PORTA_ACC:4}-sdp -m recent --set --name FLD_BLK-${PORTA_ACC:0:3}${PORTA_ACC:4}-sdp

        #Associacao das regras
	for FLD_ASSOC in $1; do
        	$IPTABLES -w -t filter -A $FLD_ASSOC -j FLD_CHK-${PORTA_ACC:0:3}${PORTA_ACC:4}
		$IPTABLES -w -t filter -A $FLD_ASSOC -j FLD_BLK-${PORTA_ACC:0:3}${PORTA_ACC:4}
	done
    done
}


###########################################################################
#Port Knock
#Primeiro parametro: portas a acessar knock
#Segundo parametros: portas knock
#Exemplo: PORTKNOCK "22 23" "tcp:100 udp:100 tcp: 200"
#/proc/net/xt_recent/
portknock () {
    TIME_INIT=30
    TIME_INC=10
    TIME_EXPIRE=3600
    for PORTA_ACC in $1; do
        $IPTABLES -w -t filter -F KNOCK-${PORTA_ACC:0:3}${PORTA_ACC:4} 2> /dev/null
        $IPTABLES -w -t filter -N KNOCK-${PORTA_ACC:0:3}${PORTA_ACC:4} 2> /dev/null
        i=0
        for PORTA_ATU in $2; do
            if [ $i -eq 0 ]; then
		PORTA_FIRST=$PORTA_ACC
                $IPTABLES -w -t filter -A KNOCK-${PORTA_ACC:0:3}${PORTA_ACC:4} -p ${PORTA_ATU:0:3} --dport ${PORTA_ATU:4} -m recent --update --seconds ${TIME_INIT} --reap --name FASE-${PORTA_ACC:0:3}${PORTA_ACC:4}-${i} #--rttl 
                $IPTABLES -w -t filter -A KNOCK-${PORTA_ACC:0:3}${PORTA_ACC:4} -p ${PORTA_ATU:0:3} --dport ${PORTA_ATU:4} -m recent --set --name FASE-${PORTA_ACC:0:3}${PORTA_ACC:4}-${i} -j DROP	#drop silencioso,para nao divulgar firewall
            else
                $IPTABLES -w -t filter -F KNOCK-${PORTA_ACC:0:3}${PORTA_ACC:4}-${i} 2> /dev/null ; $IPTABLES -w -t filter -N KNOCK-${PORTA_ACC:0:3}${PORTA_ACC:4}-${i}  2> /dev/null
                $IPTABLES -w -t filter -A KNOCK-${PORTA_ACC:0:3}${PORTA_ACC:4}-${i} -m recent --name FASE-${PORTA_ACC:0:3}${PORTA_ACC:4}-$[$i-1] --remove
                $IPTABLES -w -t filter -A KNOCK-${PORTA_ACC:0:3}${PORTA_ACC:4}-${i} -m recent --name FASE-${PORTA_ACC:0:3}${PORTA_ACC:4}-$[$i] --set -j REJECT #Reject eh mais rapido #-m limit --limit 2/min --limit-burst 10 
                $IPTABLES -w -t filter -I KNOCK-${PORTA_ACC:0:3}${PORTA_ACC:4} 1 -p ${PORTA_ATU:0:3} --dport ${PORTA_ATU:4} -m recent --rcheck --seconds $[${TIME_INIT}+($i*${TIME_INC})] --reap --name FASE-${PORTA_ACC:0:3}${PORTA_ACC:4}-$[$i-1] -j KNOCK-${PORTA_ACC:0:3}${PORTA_ACC:4}-${i} #--rttl fora e ordem proposital
            fi
            i=$[$i+1]
        done
    	$IPTABLES -w -t filter -A KNOCK-${PORTA_ACC:0:3}${PORTA_ACC:4} -m conntrack --ctstate NEW         -p ${PORTA_FIRST:0:3} --dport ${PORTA_FIRST:4} -m recent --rcheck --seconds ${TIME_EXPIRE} --reap  --name FASE-${PORTA_ACC:0:3}${PORTA_ACC:4}-$[$i-1] -j ACCEPT
    	$IPTABLES -w -t filter -A KNOCK-${PORTA_ACC:0:3}${PORTA_ACC:4} -m conntrack --ctstate ESTABLISHED -p ${PORTA_FIRST:0:3} --dport ${PORTA_FIRST:4} -j ACCEPT
    	#$IPTABLES -w -t filter -A KNOCK-${PORTA_ACC:0:3}${PORTA_ACC:4} -p icmp --icmp-type echo-request -m recent --name FASE-${PORTA_ACC:0:3}${PORTA_ACC:4}-$[$i-1] --remove
        #Associacao de Update
        for KNOCK_ASSOC in $3; do
    	    $IPTABLES -w -t filter -A $KNOCK_ASSOC -j KNOCK-${PORTA_ACC:0:3}${PORTA_ACC:4}
	done
    done
}

#################################################################################
  # $ROUTE -n route | $EGREP -E -v "(^0[.]|^127[.]|Destino|Tabela)"              | while read destA gwA maskA opA1 metA refA usoA devA; do      #Rotas Locais e remotas
  # $PIP route list | $EGREP -E "(^.* dev .* proto kernel  scope link  src .*$)" | while read destA opA1 devA opA2 opA3 opA4 opA5 opA6 srcA; do #Rotas Locais
  # $PIP route list | $EGREP -E "(^.* via .* dev .*$)"                           | while read destA opA1 srcA opA2 devA; do		     #Rotas Remotas
  # $PIP addr list  | $EGREP -E  "^(.* inet .* peer .* scope global .*)$"        | while read opA1 srcA opA2 netA opA3 opA4 devA; do 	     #Redes Ponto a Ponto
  # $PIP addr list  | $EGREP -E  "^(.* inet .* brd .* scope global .*)$"         | while read opA1 srcA opA2 netA opA3 opA4 devA; do 	     #Redes Locais
