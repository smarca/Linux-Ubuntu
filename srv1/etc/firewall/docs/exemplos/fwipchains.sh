#!/bin/bash
#Definicao de Portas
CLI_TCPPORTS="ftp ftp-data ssh telnet"
CLI_UDPPORTS="domain ntp"
SRV_TCPPORTS="ssh"
SRV_UDPPORTS="domain"
HIGHPORT="1024:65535"

##################################################################################
#Modulos do Kernel
insmod ipchains 2> /dev/null > /dev/null

#Lipar regras e bloqueio genérico
ipchains -F
ipchains -P input DENY
ipchains -P output DENY
#ipchains -P forward DENY

#--------------------------------------------------------------------------
#Como Cliente ICMP
ipchains -A output -p icmp --icmp-type echo-request -j ACCEPT
ipchains -A input  -p icmp --icmp-type echo-reply   -j ACCEPT 

#Como Cliente TCP
for i in $CLI_TCPPORTS; do
    ipchains -A output -p tcp --dport $i --sport $HIGHPORT -j ACCEPT
    ipchains -A input  -p tcp --sport $i --dport $HIGHPORT -j ACCEPT
done
#Como Cliente UDP
for i in $CLI_UDPPORTS; do
    ipchains -A output -p udp --dport $i --sport $HIGHPORT -j ACCEPT
    ipchains -A input  -p udp --sport $i --dport $HIGHPORT -j ACCEPT
done

#--------------------------------------------------------------------------
#Como Servidor ICMP
ipchains -A input  -p icmp --icmp-type echo-request -j ACCEPT 
ipchains -A output -p icmp --icmp-type echo-reply   -j ACCEPT

#Como Servidor TCP
for i in $SRV_TCPPORTS; do
    ipchains -A input  -p tcp --dport $i -j ACCEPT
    ipchains -A output -p tcp --sport $i -j ACCEPT
done

#Como Servidor UDP
for i in $SRV_UDPPORTS; do
    ipchains -A input  -p udp --dport $i -j ACCEPT
    ipchains -A output -p udp --sport $i -j ACCEPT
done
#--------------------------------------------------------------------------
#Regras de Forward
# Para "negar tudo" no forward deve se prestar atenção ao input e output,
#    pois a sequencia de passagem é: input -> forward -> output e não apenas
#    forward como ocorre no iptables.
echo 1 > /proc/sys/net/ipv4/ip_forward	

#--------------------------------------------------------------------------
# Regras personlalizadas aqui...

#--------------------------------------------------------------------------
#Logger Geral (Sempre por ultimo)
ipchains -A input  --log
ipchains -A output --log
