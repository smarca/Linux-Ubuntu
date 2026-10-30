#!/bin/bash
#Definicao de Portas
CLI_TCPPORTS="ftp ftp-data ssh telnet 60171"
CLI_UDPPORTS="domain ntp"
SRV_TCPPORTS="ssh"
SRV_UDPPORTS="domain"
FWCLI_TCPPORTS="ftp ftp-data ssh telnet 60171"
FWCLI_UDPPORTS="domain ntp"

DEVINT="eth0"
DEVEXT="eth1"

##################################################################################
#Modulos do Kernel
modprobe -a ip_conntrack_*           #Conntrack
modprobe -a ip_nat_*                 #NAT
      
#Lipar regras e bloqueio genérico
iptables -F
iptables -t filter -P INPUT   DROP
iptables -t filter -P OUTPUT  DROP
iptables -t filter -P FORWARD DROP

#--------------------------------------------------------------------------
# Relatados e Estabelecidos
iptables -t filter -A INPUT   -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -t filter -A OUTPUT  -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -t filter -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

#--------------------------------------------------------------------------
#Eu mesmo, meu servidor....................................................
#Como Cliente ICMP
iptables -t filter -A OUTPUT -p icmp --icmp-type echo-request -m state --state NEW -j ACCEPT
iptables -t filter -A INPUT  -p icmp --icmp-type echo-reply   -m state --state NEW -j ACCEPT 

#Como Cliente TCP
for i in $CLI_TCPPORTS; do
    iptables -t filter -A OUTPUT -p tcp --dport $i -m state --state NEW -j ACCEPT
    iptables -t filter -A INPUT  -p tcp --sport $i -m state --state NEW -j ACCEPT
done
#Como Cliente UDP
for i in $CLI_UDPPORTS; do
    iptables -t filter -A OUTPUT -p udp --dport $i -m state --state NEW -j ACCEPT
    iptables -t filter -A INPUT  -p udp --sport $i -m state --state NEW -j ACCEPT
done

#--------------------------------------------------------------------------
#Eu mesmo, meu servidor....................................................
#Como Servidor ICMP
iptables -t filter -A INPUT  -p icmp --icmp-type echo-request -m state --state NEW -j ACCEPT 
iptables -t filter -A OUTPUT -p icmp --icmp-type echo-reply   -m state --state NEW -j ACCEPT

#Como Servidor TCP
for i in $SRV_TCPPORTS; do
    iptables -t filter -A INPUT  -p tcp --dport $i -m state --state NEW -j ACCEPT
    iptables -t filter -A OUTPUT -p tcp --sport $i -m state --state NEW -j ACCEPT
done

#Como Servidor UDP
for i in $SRV_UDPPORTS; do
    iptables -t filter -A INPUT  -p udp --dport $i -m state --state NEW -j ACCEPT
    iptables -t filter -A OUTPUT -p udp --sport $i -m state --state NEW -j ACCEPT
done

#--------------------------------------------------------------------------
#Meus clientes.............................................................
#Como Cliente ICMP
iptables -t filter -A FORWARD -i $DEVINT -o $DEVEXT -p icmp --icmp-type echo-request -m state --state NEW -j ACCEPT
iptables -t filter -A FORWARD -o $DEVINT -i $DEVEXT -p icmp --icmp-type echo-reply   -m state --state NEW -j ACCEPT 

#Como Cliente TCP
for i in $FWCLI_TCPPORTS; do
    iptables -t filter -A FORWARD -i $DEVINT -o $DEVEXT -p tcp --dport $i -m state --state NEW -j ACCEPT
    iptables -t filter -A FORWARD -o $DEVINT -i $DEVEXT -p tcp --sport $i -m state --state NEW -j ACCEPT
done
#Como Cliente UDP
for i in $FWCLI_UDPPORTS; do
    iptables -t filter -A FORWARD -i $DEVINT -o $DEVEXT  -p udp --dport $i -m state --state NEW -j ACCEPT
    iptables -t filter -A FORWARD -o $DEVINT -i $DEVEXT  -p udp --sport $i -m state --state NEW -j ACCEPT
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
iptables -A INPUT   -j LOG --log-prefix "Packet log: " --log-tcp-options --log-tcp-sequence --log-ip-options
iptables -A OUTPUT  -j LOG --log-prefix "Packet log: " --log-tcp-options --log-tcp-sequence --log-ip-options
iptables -A FORWARD -j LOG --log-prefix "Packet log: " --log-tcp-options --log-tcp-sequence --log-ip-options
