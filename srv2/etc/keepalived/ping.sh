#!/bin/bash

PINGLIST=(
     '8.8.8.8'
     '8.8.4.4'
     '4.2.2.1'
     '4.2.2.2'
     '4.2.2.3'
     '4.2.2.4'
     '4.2.2.5'
     '4.2.2.6'
     'www.msftncsi.com'
     '208.67.222.222'
     '208.67.220.220'
   )

NRAND=`shuf -i 0-$(expr ${#PINGLIST[@]} - 1) -n 1`
HOST=$1
INTERFACE=$2                    #eth0, eth1
TYPE=$3                         #fail opcional
[ "$HOST" == "rand" ] && HOST=${PINGLIST[$NRAND]}
[ ! -z $INTERFACE ] && INTERFACE="-I $INTERFACE"

/bin/ping -q -W 2 -c 1 $INTERFACE $HOST > /dev/null 2> /dev/null
RETORNO=$?

#Inverter resultado se for o caso
if [ "$TYPE" == "fail" ]; then
    if [ "$RETORNO" == "0" ]; then
        RETORNO=1
    else
        RETORNO=0
    fi
else
    if [ "$RETORNO" == "0" ]; then
        RETORNO=0
    else
        RETORNO=1
    fi
fi

exit $RETORNO
