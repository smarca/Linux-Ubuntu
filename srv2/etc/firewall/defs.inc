#!/bin/bash
###########################################################################
#     Feito por Silmar A. Marca      smarca@gmail.com                     #
###########################################################################
#  *  A remocao destas linhas implica na nao observacao da licenca GNU *  #
#  *  Informe o autor sobre falhas ou incremento de funcoes            *  #
#  *  Respeite a propriedade intelectual, http://www.gnu.org/          *  #
###########################################################################

IPTABLES="/sbin/iptables"			#Arquivo Executavel do IPTABLES
PIP="/bin/ip"                                   #Executavel Bandwidth
TC="/sbin/tc"                                   #Executavel Bandwidth
ROUTE="/sbin/route"                             #Executavel Route
MODPROB="/sbin/modprobe"			#Executavel Insmod
CAT="/bin/cat"					#Executavel CAT
TAC="/usr/bin/tac"				#Executavel TAC
TAIL="/usr/bin/tail"				#Executavel para TAIL
HEAD="/usr/bin/head"				#Executavel para HEAD
GAWK="/usr/bin/gawk"	  			#Executavel AWK Gnu
EGREP="/bin/grep"				#Executavel Egrep
SORT="/usr/bin/sort"				#Executavel Sort
UNIQ="/usr/bin/uniq"				#Executavel UNIQ
CUT="/usr/bin/cut"				#Executavel CUT
LS="/bin/ls"					#Executavel LS
BASENAME="/usr/bin/basename"			#Executavel BASENAME
FIND="/usr/bin/find"				#Executavel FIND

LOGMART="/var/log/syslog"			#Arquivo de log do MARTIANS
LOGFW="/var/log/firewall/firewall.log"		#Arquivo de log do IPTABLES
LOGSSQUID="/var/log/squid/access.log"		#Arquivo de log do SQUID
LOGSNAMED="/var/log/named/query.log"		#Arquivo de log do NAMED
CONFSSHD="/etc/ssh/sshd_config"			#Arquivo de conf sshd 
DSHIELDFILE_BLK="/tmp/block.dshield"            #Arquivo Dshield para efetuar bloqueio
DSHIELDFILE_LOG="/tmp/log.dshield"              #Arquivo Dshield para efetuar log

D_FW="/etc/firewall/"		       		#path do firewall
D_LST=$D_FW"lst/"				#path lista de bloqueios
F_MAC=$D_FW"mac.ini"       			#Lista de Mac Address para FORWARD
F_QOS=$D_FW"qos.ini"				#Qos e bandas
F_QOS_HST=$D_LST"qos_hst.ini"			#Velocidade full sem qos
F_ACESSOS=$D_LST"acc_port.ini" 			#Acessos gerais
F_UPNPHST=$D_LST"acc_upnp.ini" 			#Acessos gerais UPNP
F_INTERF=$D_FW"interfaces.ini"   		#Interfaces e parametros de Velocidade
F_REDIR1=$D_LST"rdr_hst.local.ini"		#Redirecionamentos locais e DMZ
F_REDIR2=$D_LST"rdr_hst.ini"   			#Redirecionamentos e DMZ
F_ACCHST1=$D_LST"acc_hst.local.ini" 	 	#Acessos locais especificos
F_ACCHST2=$D_LST"acc_hst.ini" 			#Acessos especificos
F_ACCDYN=$D_LST"acc_dyn.ini" 			#Acessos especificos e hosts dinamicas relidas de tempo em tempo
F_BLKHST=$D_LST"blk_hst.ini"	   		#Hosts ou redes a serem bloqueadas em Input

#F_BLKSQUID1="/etc/squid3/lst/blk/anonsurf/ip"	#Bloqueio squid 1
#L_BLKSQUID1="squid"				#Flag s de squid!, de bloqueio total incluive por proxy

if [ -z "$TERM" ]; then
    COLUMNS=`tput -T xterm cols`                #Numero de Colunas
    LINES=`tput -T xterm lines`                 #Numero de Linhas
else
    COLUMNS=`tput cols`                         #Numero de Colunas
    LINES=`tput   lines`                        #Numero de Linhas
fi
export COLUMNS LINES

