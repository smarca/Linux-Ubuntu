#!/bin/sh
###########################################################################
#     Feito por Silmar A. Marca      smarca@gmail.com                     #
###########################################################################
#  *  A remocao destas linhas implica na nao observacao da licenca GNU *  #
#  *  Informe o autor sobre falhas ou incremento de funcoes            *  #
#  *  Respeite a propriedade intelectual, http://www.gnu.org/          *  #
###########################################################################

#Variaveis
IPTABLES="/usr/sbin/iptables"   
EXT="ppp0"
echo 1 > /proc/sys/net/ipv4/ip_forward
#ZERAR
    $IPTABLES -F -t filter # Nao defaults
    $IPTABLES -X -t filter # Zerar todas
    $IPTABLES -Z -t filter # Estatistica
    $IPTABLES -F -t mangle # Nao defaults
    $IPTABLES -X -t mangle # Zerar todas
    $IPTABLES -Z -t mangle # Estatistica
    $IPTABLES -F -t nat    # Nao defaults
    $IPTABLES -X -t nat    # Zerar todas
    $IPTABLES -Z -t nat    # Estatistica

#ABRIR 
    $IPTABLES -t filter -P INPUT ACCEPT
    $IPTABLES -t filter -P FORWARD ACCEPT
    $IPTABLES -t filter -P OUTPUT ACCEPT
    $IPTABLES -t nat -P PREROUTING ACCEPT
    $IPTABLES -t nat -P POSTROUTING ACCEPT
    $IPTABLES -t nat -P OUTPUT ACCEPT
    $IPTABLES -t mangle -P PREROUTING ACCEPT
    $IPTABLES -t mangle -P OUTPUT ACCEPT
  
#MASQ REDE INT
/usr/sbin/iptables -t nat -A POSTROUTING -o $EXT -j MASQUERADE
# $IPTABLES -t nat -A POSTROUTING -o $EXT -j SNAT --to-source 10.0.0.137



