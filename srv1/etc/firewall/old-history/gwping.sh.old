#!/bin/bash
###########################################################################
#     Feito por Silmar A. Marca      smarca@gmail.com                     #
###########################################################################
#  *  A remocao destas linhas implica na nao observacao da licenca GNU *  #
#  *  Informe o autor sobre falhas ou incremento de funcoes            *  #
#  *  Respeite a propriedade intelectual, http://www.gnu.org/          *  #
###########################################################################
#Modificado a gosto por smarca@gmail.com
#Adicionar em rc.local : nohup /etc/firewall/gwping.sh & > /dev/null 2> /dev/null

# Interfaces Externas a serem checadas e seus respectivos gateways
EXTIF1=ppp0			#Interface 1 - Nome
GW1=				#Interface 1 - IP (Sem ip caso PPP)
EXTIF2=eth0			#Interface 2 - Nome
GW2=10.0.0.1			#Interface 2 - IP (Sem ip caso PPP)

# Interfaces a serem pingadas para ver se estao online. Normalmente o mesmo ip dos Gateways, mas nao necessariamente
EXTIP1=189.58.102.96		#Ip deste servidor via PPP0
EXTIP2=10.0.0.1			#Ip servidor secundario

# Nome dos provedores de internet. Default e Backup
NAME1=GVT.def
NAME2=BRT.bkp

#Numero de repeticoes de sucesso ou falha para mudar o gateway da conexao
MAX_ERR_PING1=1	#Interface local com falha de ping
MAX_ERR_PING2=1 #Interface remota com falha de ping

# PINGTIMEOUT do Ping em Segundos
PINGTIMEOUT=2

# Tempo entre as checagens
SLEEPTIME=15

# A cada quantas falhas o PPPOE deve ser desligado e ligado novamente. Qual o tempo entre desligar e ligar novamente.
CNT_RESTART_PPPOE=20		#A cada quantas falhas apos a interface estar down ou sem pings. Numero grande pois geralmente o proprio pppoe redisca. 
				#Tempo Aproximado = (SLEEPTIME segundos x CNT_RESTART_PPPOE)
SLEEP_RESTART_PPPOE=15		#Numero de segundos entre desativar o discador pppoe e ativar novamente

# Nome do arquivo de log para as quedas dos links (opcional)
# LOGLINK=/srv/www/default/stat/link #Log de quedas ou nao

# Dual default gateway ou nao
BALANCELINK=0
# Rotas relativas. Deixar valor pequeno, calculando proporcao entre as rotas. Quanto maior mais prioridade. Apenas se BALANCELINK=1
W1=1		# 1mbit, prioridade 1x
W2=15		#15mbit, prioridade 10x

















#-------------------------------------------------------------------------------------------------------------------
# Nao mude nada daqui para baixo

#Encontra comando correto caso a interface tenha ou nao gateway ou diretamente na interace (ppp0)
#ip route delete default gw 10.0.0.1
#ip route delete default dev ppp0
if [ "$GW1" != "" ]; then
    CRTR1="via ${GW1} dev ${EXTIF1}"
else 
    CRTR1="dev ${EXTIF1}"
fi

if [ "$GW2" != "" ]; then
    CRTR2="via ${GW2} dev ${EXTIF2}"
else 
    CRTR2="dev ${EXTIF2}"
fi

#Flag de Status da interface. Se levantada e com rotas ativas. Se com erro=1. Se tudo ok=0
aERR_INTF1=0	#Atual status interface 1
aERR_INTF2=0	#Atual status interface 2
uERR_INTF1=0	#Ultimo status interface 1
uERR_INTF2=0	#Ultimo status interface 2

#Flag de Status do ping. Se com erro=1. Se tudo ok=0
aERR_PING1=0	#Atual ping interface 1
aERR_PING2=0	#Atual ping interface 2
uERR_PING1=0	#Ultimo ping interface 1
uERR_PING2=0	#Ultimo ping interface 2

#Contagem de Erros ou acertos Soft-Hard
CNT_PING1=0	#Contagem de Resultados bons ou ruins dos ultimos pings para interface 1
CNT_PING2=0	#Contagem de Resultados bons ou ruins dos ultimos pings para interface 2
CNT_INTF1=0	#Contagem de Resultados bons ou ruins dos ultimos pings para interface 1
CNT_INTF2=0	#Contagem de Resultados bons ou ruins dos ultimos pings para interface 2
oCNT_PING1=0	#Contagem de Resultados bons ou ruins dos ultimos pings para interface 1
oCNT_PING2=0	#Contagem de Resultados bons ou ruins dos ultimos pings para interface 2
oCNT_INTF1=0	#Contagem de Resultados bons ou ruins dos ultimos pings para interface 1
oCNT_INTF2=0	#Contagem de Resultados bons ou ruins dos ultimos pings para interface 2

#Rota default como padrao existente. Se com erro=1. Se tudo ok=0
aDEFAULTGW=1	#Apenas para inicializacao como se nao tivesse rota default

#Ver se teste
if [[ "$1" == "debug" ]]; then
    DEBUG=1
else
    DEBUG=0
fi

while : ; do
	uERR_PING1=$aERR_PING1 ; uERR_PING2=$aERR_PING2	#Salva ultimo erro de ping
	uERR_INTF1=$aERR_INTF1 ; uERR_INTF2=$aERR_INTF2	#Salva ultimo erro de interface


	#Verificar se existe rota default
	route -n | grep -q -E "^0[.]0[.]0[.]0.*0[.]0[.]0[.]0.*U"
        aDEFAULTGW=$? 								#Salva o status da rota default, se inexistente ou nao

	#Verificar ping e rotas. Atualizar status atual da interface 1
	route -n | grep -q -E U.*${EXTIF1}					#Verifica se a interface esta ativa
        aERR_INTF1=$? ; aERR_PING1=1						#Salva o status atual da interface. Inicializa ping.
        if [ $aERR_INTF1 -eq 0 ]; then
    	    ping -q -W $PINGTIMEOUT -I $EXTIF1 -c 1 $EXTIP1 > /dev/null  2>&1	#Se a interface estativa, verfica se o ping esta ativo
            aERR_PING1=$?
	fi

	#Verificar ping e rotas. Atualizar status atual da interface 2
	route -n | grep -q -E U.*${EXTIF2}					#Verifica se a interface esta ativa
        aERR_INTF2=$? ; aERR_PING2=1						#Salva o status atual da interface. Inicializa ping.
        if [ $aERR_INTF2 -eq 0 ]; then
    	    ping -q -W $PINGTIMEOUT -I $EXTIF2 -c 1 $EXTIP2 > /dev/null  2>&1	#Se a interface estativa, verfica se o ping esta ativo
            aERR_PING2=$?
	fi

	#Verificar se ocorreu variacao de status. Zerar contador caso sim. Se algo mudou, os contadores certamente estarao zerados aqui.
	if [[ $aERR_INTF1 -ne $uERR_INTF1 ]]; then oCNT_INTF1=$CNT_INTF1 ; CNT_INTF1=0 ; fi		#Caso o status da interface atual tenha sido diferente do penultimo status, zera contador
	if [[ $aERR_INTF2 -ne $uERR_INTF2 ]]; then oCNT_INTF2=$CNT_INTF2 ; CNT_INTF2=0 ; fi		#Caso o status da interface atual tenha sido diferente do penultimo status, zera contador
	if [[ $aERR_PING1 -ne $uERR_PING1 ]]; then oCNT_PING1=$CNT_PING1 ; CNT_PING1=0 ; fi		#Caso o status do ping atual tenha sido diferente do penultimo ping, zera contador
	if [[ $aERR_PING2 -ne $uERR_PING2 ]]; then oCNT_PING2=$CNT_PING2 ; CNT_PING2=0 ; fi		#Caso o status do ping atual tenha sido diferente do penultimo ping, zera contador

	#Verificar se variaveis muito grandes. Inicia com 1 em caso de sim.
	if [[ $CNT_INTF1 -ge 1000000000 ]]; then CNT_INTF1=1 ; fi			#Caso o status da interface atual tenha sido diferente do penultimo status, zera contador
	if [[ $CNT_INTF2 -ge 1000000000 ]]; then CNT_INTF2=1 ; fi			#Caso o status da interface atual tenha sido diferente do penultimo status, zera contador
	if [[ $CNT_PING1 -ge 1000000000 ]]; then CNT_PING1=1 ; fi			#Caso o status do ping atual tenha sido diferente do penultimo ping, zera contador
	if [[ $CNT_PING2 -ge 1000000000 ]]; then CNT_PING2=1 ; fi			#Caso o status do ping atual tenha sido diferente do penultimo ping, zera contador

	#Verifica se esta ocorrendo falha no ping e o contador eh muito alto
	if [[ $aERR_PING1 -ne 0 && $CNT_PING1 -ge $MAX_ERR_PING1 ]]; then aERR_INTF1=1 ; fi  #Muita falha de pings na interface 1
	if [[ $aERR_PING2 -ne 0 && $CNT_PING2 -ge $MAX_ERR_PING2 ]]; then aERR_INTF2=1 ; fi  #Muita falha de pings na interface 2

	#Ajuste de rotas
	if [[ ( $aDEFAULTGW -eq 1 ) || ( $CNT_INTF1 -eq 0 || $CNT_INTF2 -eq 0 ) || ( $aERR_INTF1 -ne $uERR_INTF1 || $aERR_INTF2 -ne $uERR_INTF2 ) ]]; then #Caso alguma interface tenha mudado... tanto a 1 quanto a 2
		if [[ ( ($aDEFAULTGW -eq 1 || $aERR_INTF1 -ne $uERR_INTF1) && ($aERR_INTF1 -eq 1) ) && ($aERR_INTF2 -eq 0) ]]; then 	#Caso exista um erro na interface 1 e este status tenha mudado agora, mas nao haja erro na saida 2...
                        ip route replace default scope global $CRTR2
			logger -p daemon.info -t Rotas: Link $NAME1\(${CNT_INTF1}x\) inativo e Link $NAME2\(${CNT_INTF2}x\) ativo: Mudando para link da operadora secundaria $NAME2
			if [[ $DEBUG -eq 1 ]]; then echo Rotas: Link $NAME1\(${CNT_INTF1}x\) inativo e Link $NAME2\(${CNT_INTF2}x\) ativo: Mudando para link da operadora secundaria $NAME2 ;fi
		elif [[ ( ( $aDEFAULTGW -eq 1 || $aERR_INTF2 -ne $uERR_INTF2) && ($aERR_INTF2 -eq 1) ) && ($aERR_INTF1 -eq 0) ]]; then #Caso exista um erro na interface 2 e este status tenha mudado agora, mas nao haja erro na saida 1...
                        ip route replace default scope global $CRTR1
			logger -p daemon.info -t Rotas: Link $NAME1\(${CNT_INTF1}x\) ativo e Link $NAME2\(${CNT_PING2}x\) inativo: Usando o link da operadora principal $NAME1
			if [[ $DEBUG -eq 1 ]]; then echo Rotas: Link $NAME1\(${CNT_INTF1}x\) ativo e Link $NAME2\(${CNT_PING2}x\) inativo: Usando o link da operadora principal $NAME1 ;fi
		elif [[ ( $aDEFAULTGW -eq 1 ) || ( ( ($aERR_INTF1 -eq 0) && ($aERR_INTF1 -ne $uERR_INTF1) ) || ( ($aERR_INTF2 -eq 0) && ($aERR_INTF2 -ne $uERR_INTF2) ) ) ]]; then  #Caso todas interfaces estejam ok, mas tenha existido alguma mudanca recente...
			if [ $BALANCELINK -eq 1 ]; then
                    	    ip route replace default scope global nexthop $CRTR1 weight $W1 nexthop $CRTR2 weight $W2
			    logger -p daemon.info -t Rotas: Ativos links $NAME1\(${CNT_INTF1}x\) e $NAME2\(${CNT_INTF2}x\) - Usando links das operadoras $NAME1 e $NAME2 balanceados \(taxa $W1 para $W2\)
			    if [[ $DEBUG -eq 1 ]]; then echo Rotas: Ativos links $NAME1\(${CNT_INTF1}x\) e $NAME2\(${CNT_INTF2}x\) - Usando links das operadoras $NAME1 e $NAME2 balanceados \(taxa $W1 para $W2\) ;fi
			else
                    	    ip route replace default scope global $CRTR1
    			    logger -p daemon.info -t Rotas: Ativos links $NAME1\(${CNT_INTF1}x\) e $NAME2\(${CNT_INTF2}x\) - Usando apenas o link da operadora principal $NAME1
			    if [[ $DEBUG -eq 1 ]]; then echo Rotas: Ativos links $NAME1\(${CNT_INTF1}x\) e $NAME2\(${CNT_INTF2}x\) - Usando apenas o link da operadora principal $NAME1 ;fi
			fi
		elif [[ ( ($aERR_INTF1 -ne 0) && ($aERR_INTF1 -ne $uERR_INTF1) ) || ( ($aERR_INTF2 -ne 0) && ($aERR_INTF2 -ne $uERR_INTF2) ) ]]; then
		    logger -p daemon.info -t Rotas: Inativos $NAME1\(${CNT_INTF1}x\) e $NAME2\(${CNT_PING2}x\) - sem link a usar!
		    if [[ $DEBUG -eq 1 ]]; then echo Rotas: Inativos $NAME1\(${CNT_INTF1}x\) e $NAME2\(${CNT_PING2}x\) - sem link a usar! ; fi
		fi
		#Caso algo tenha mudado para down.. flush no cache! Para up nao precisa, sendo bom que haja timeout nos direcionamentos...
		ip route flush cached
	fi

	#Mensagens de Debug
	if [[ $DEBUG -eq 1 ]]; then echo Debug: $NAME1 - AtualINTF:$aERR_INTF1 PenultimaINTF:$uERR_INTF1 - AtualPing:$aERR_PING1 PenultimoPing:$uERR_PING1 - CntINTF:$CNT_INTF1 CntPing:$CNT_PING1 ;fi
	if [[ $DEBUG -eq 1 ]]; then echo Debug: $NAME2 - AtualINTF:$aERR_INTF2 PenultimaINTF:$uERR_INTF2 - AtualPing:$aERR_PING2 PenultimoPing:$uERR_PING2 - CntINTF:$CNT_INTF2 CntPing:$CNT_PING2 ;fi
	if [[ $DEBUG -eq 1 ]]; then echo Debug: ... ;fi

	#Sempre incrementa contadores
	CNT_INTF1=`expr $CNT_INTF1 + 1` ; CNT_INTF2=`expr $CNT_INTF2 + 1`  #Incrementa status atual dos erros ou acertos de interface; Minimo 1 para divisoes numericas futuras
	CNT_PING1=`expr $CNT_PING1 + 1` ; CNT_PING2=`expr $CNT_PING2 + 1`  #Incrementa status atual dos erros ou acertos de ping;      Minimo 1 para divisoes numericas futuras

	#Aqui, colocar condicao para cada N falhas da interface, desligar e religar PPPOE
	if [[ $CNT_RESTART_PPPOE -gt 0 && ($aERR_INTF1 -ne 0) && ($(($CNT_INTF1 % $CNT_RESTART_PPPOE)) -eq 0) ]]; then 
	    logger -p daemon.info -t Pppoe: Reiniciando link $NAME1 apos $CNT_INTF1 falhas
	    if [[ $DEBUG -eq 1 ]]; then echo Pppoe: Reiniciando link $NAME1 apos $CNT_INTF1 falhas ;fi
	    poff dsl-provider > /dev/null 2> /dev/null
	    sleep $SLEEP_RESTART_PPPOE
	    pon dsl-provider > /dev/null 2> /dev/null
	fi

	#Aguarda no loop
        sleep $SLEEPTIME
done
