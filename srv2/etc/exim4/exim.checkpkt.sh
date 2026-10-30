#!/bin/sh
##########################################################################
#     Feito por Silmar A. Marca      smarca@gmail.com                    #
###########################################################################
#  *  A remocao destas linhas implica na nao observacao da licenca GNU *  #
#  *  Informe ao autor sobre falhas ou incremento de funcoes           *  #
#  *  Respeite a propriedade intelectual, http://www.gnu.org/          *  #
###########################################################################
#                  Runtime configuration file for Exim                    #
###########################################################################
#Definicoes

# dtrx? 
# 7z?

EXTENS='(ad[ep]|asd|ba[st]|chm|cmd|com|cpl|crt|dll|exe|hlp|hta|in[fs]|isp|jse?|jar|lib|lnk|md[bez]|ms[cipt]|ole|ocx|pcd|pif|reg|sc[rt]|sh[sb]|sys|url|vb[es]?|vxd|ws[cfh]|cab|nsh|html?)'
#Extensoes atualmente reconhecidas
COMPAC='(zip|rar|arj|tgz|tar|gz|bz2)'		

#Previne arquivos compactados dentro de compactados
EXTENS='[.]('${EXTENS}'|'${COMPAC}')'	

#Testa se esta entre as extensoec conhecidas
if [ "`echo .$1 | egrep -i "[.]${COMPAC}$"`" = "" ]; then
    echo -n 'File Extension <.'$1'> is unknow compact type!\n' 
    exit 0
fi

#Mudar diretorios	
if [ ! -z "$2" ]; then
    if [ -d /var/spool/exim4/scan/$2 ]; then
	cd /var/spool/exim4/scan/$2
    else
	echo -n 'Diretorio desconhecido em /var/spool/exim4/scan/'$2'\n' 
	exit 1
    fi
fi

#Todos arquivos do arquivo compactado
for i in `ls | egrep -i ".${COMPAC}$"`; do
   EXTFILE="`basename $i | sed -e 's/.*\.//' | tr [A-Z] [a-z]`"
   case "${EXTFILE}" in
     zip)
        CMD_TST="unzip -t $i"
        CMD_VRF="zipinfo -1 $i"
        ;;
     rar)
        CMD_TST="rar t $i"
        CMD_VRF="rar vt $i"
        ;;
     arj)
        CMD_TST="unarj t $i"
        CMD_VRF="arj l $i"
        ;;
     tar)
        CMD_VRF="tar --list -f $i"
        ;;
     tgz|gz)
        CMD_VRF="tar --list -zf $i"
        ;;
     bz2)
        CMD_VRF="tar --list -jf $i"
        ;;
     *)
        echo -n '* Extension of File <'$i'> is unknow archive compact!\n'
   esac

   #Testar pra ver se o arquivo esta OK
   if [ ! -z "${CMD_VRF}" ]; then
	${CMD_TST} 2> /dev/null > /dev/null 
	if [ ! $? -eq 0 -o ]; then									
	    echo -n '* The file <'$i'> is not '${EXTFILE}' archive!\n' 									
	    FOUND=1
	fi 
   fi

   #Ver se existe executaveis no conteudo do mesmo
    ARQS="`${CMD_VRF} 2> /dev/null | gawk '{ print $1 }' | egrep -i "${EXTENS}$"`"
    if [ ! -z "$ARQS" ]; then
        echo -n '* File(s) in <'$i'>: '$ARQS'\n'
	FOUND=1
    fi
done

if [ ! -z "${FOUND}" ]; then
    exit 1
else
    exit 0
fi
