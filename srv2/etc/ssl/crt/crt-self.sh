#!/bin/bash

###########################################################################
#     Feito por Silmar A. Marca      smarca@gmail.com                     #
###########################################################################
#  *  A remocao destas linhas implica na nao observacao da licenca GNU *  #
#  *  Informe o autor sobre falhas ou incremento de funcoes            *  #
#  *  Respeite a propriedade intelectual, http://www.gnu.org/          *  #
###########################################################################

#Para testar Envio e recebimento de email
#openssl s_client -connect localhost:465 -crlf
#openssl s_client -connect localhost:995 -crlf


#Base Dir
BASEDIR=/etc/ssl/crt
KEYLEN=4096
DIASCRT=1825

# Read domain
# echo -n "Apelido do dominio [Ex: dominiox]:" ; read DOMINIO
DOMINIO="monital"
mkdir -p ${BASEDIR}/db ;mkdir -p ${BASEDIR}/server ; mkdir -p ${BASEDIR}/user ; cd ${BASEDIR}
chmod o=x ${BASEDIR}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#CA Server SELFSIGN server_cert
[[ ! -f ${BASEDIR}/db/serial ]]     		&& echo "00" > ${BASEDIR}/db/serial
[[ ! -f ${BASEDIR}/db/index ]]     		&& touch ${BASEDIR}/db/index
[[ ! -f ${BASEDIR}/server/${DOMINIO}.rsa.key ]] && openssl genrsa -out ${BASEDIR}/server/${DOMINIO}.rsa.key ${KEYLEN}
[[ ! -f ${BASEDIR}/server/${DOMINIO}.csr ]]     && openssl req -new -key ${BASEDIR}/server/${DOMINIO}.rsa.key -out ${BASEDIR}/server/${DOMINIO}.csr -config ${BASEDIR}/crt-self.cnf
[[ ! -f ${BASEDIR}/server/${DOMINIO}.ca ]] 	&& openssl x509 -req -signkey ${BASEDIR}/server/${DOMINIO}.rsa.key -in ${BASEDIR}/server/${DOMINIO}.csr -out ${BASEDIR}/server/${DOMINIO}.ca -days ${DIASCRT} -CAcreateserial -CAserial ${BASEDIR}/db/serial -extensions server_ca -extfile ${BASEDIR}/crt-self.cnf 
[[ ! -f ${BASEDIR}/server/${DOMINIO}.crt ]] 	&& openssl x509 -req -signkey ${BASEDIR}/server/${DOMINIO}.rsa.key -in ${BASEDIR}/server/${DOMINIO}.csr -out ${BASEDIR}/server/${DOMINIO}.crt -days ${DIASCRT} -CAcreateserial -CAserial ${BASEDIR}/db/serial -extensions server_cert -extfile ${BASEDIR}/crt-self.cnf 
[[ ! -f ${BASEDIR}/server/${DOMINIO}.cer ]] 	&& openssl ca -selfsign -create_serial -keyfile ${BASEDIR}/server/${DOMINIO}.rsa.key -cert ${BASEDIR}/server/${DOMINIO}.ca -in ${BASEDIR}/server/${DOMINIO}.csr -out ${BASEDIR}/server/${DOMINIO}.cer -outdir ${BASEDIR}/server -days ${DIASCRT} -extensions server_cert -extfile ${BASEDIR}/crt-self.cnf -config ${BASEDIR}/crt-self.cnf 
[[ ! -f ${BASEDIR}/server/${DOMINIO}.p12 ]] 	&& openssl pkcs12 -nodes -export -inkey ${BASEDIR}/server/${DOMINIO}.rsa.key -in ${BASEDIR}/server/${DOMINIO}.crt -certfile ${BASEDIR}/server/${DOMINIO}.cer -out ${BASEDIR}/server/${DOMINIO}.p12 -name "DOM:${DOMINIO}" 
[[ ! -f ${BASEDIR}/server/${DOMINIO}.pem ]] 	&& openssl pkcs12 -nodes -in ${BASEDIR}/server/${DOMINIO}.p12 -out ${BASEDIR}/server/${DOMINIO}.pem -name "DOM:${DOMINIO}" 
#Verificar se IGUAIS .pem, .crt e .cer
[[ ! -z `diff <(ipsec pki --print --in ${BASEDIR}/server/${DOMINIO}.pem | grep -v "serial") <(ipsec pki --print --in ${BASEDIR}/server/${DOMINIO}.crt | grep -v "serial")` ]] && echo "*** ERRO server_cert: diferenca entre .pem e .crt !"
[[ ! -z `diff <(ipsec pki --print --in ${BASEDIR}/server/${DOMINIO}.pem | grep -v "serial") <(ipsec pki --print --in ${BASEDIR}/server/${DOMINIO}.cer | grep -v "serial")` ]] && echo "*** ERRO server_cert: diferenca entre .pem e .cer !"
[[ ! -z `diff <(ipsec pki --print --in ${BASEDIR}/server/${DOMINIO}.crt | grep -v "serial") <(ipsec pki --print --in ${BASEDIR}/server/${DOMINIO}.cer | grep -v "serial")` ]] && echo "*** ERRO server_cert: diferenca entre .crt e .cer !"
#Exibir Informacao
ipsec pki --print --in ${BASEDIR}/server/${DOMINIO}.crt
echo "-------------------------------------------------"
#Servidor DH
[[ ! -f ${BASEDIR}/server/${DOMINIO}.dh ]] 	&& certtool --generate-dh-params --bits 2236 >> ${BASEDIR}/server/${DOMINIO}.dh # openssl gendh -out ${BASEDIR}/${DOMINIO}.dh 

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Usuario user_cert
echo " "
echo -n "Username comum do usuario [Ex: usuriox]:" ; read USUARIO
[[ ! -f ${BASEDIR}/user/${DOMINIO}-${USUARIO}.rsa.key ]] && openssl genrsa -out ${BASEDIR}/user/${DOMINIO}-${USUARIO}.rsa.key ${KEYLEN}
[[ ! -f ${BASEDIR}/user/${DOMINIO}-${USUARIO}.csr ]]     && openssl req -new -key ${BASEDIR}/user/${DOMINIO}-${USUARIO}.rsa.key -out ${BASEDIR}/user/${DOMINIO}-${USUARIO}.csr -config ${BASEDIR}/crt-self.cnf
[[ ! -f ${BASEDIR}/user/${DOMINIO}-${USUARIO}.crt ]]     && openssl x509 -req -in ${BASEDIR}/user/${DOMINIO}-${USUARIO}.csr -CAkey ${BASEDIR}/server/${DOMINIO}.rsa.key -CA ${BASEDIR}/server/${DOMINIO}.ca -days ${DIASCRT} -CAcreateserial -CAserial ${BASEDIR}/db/serial -out ${BASEDIR}/user/${DOMINIO}-${USUARIO}.crt -extensions user_cert -extfile ${BASEDIR}/crt-self.cnf
[[ ! -f ${BASEDIR}/user/${DOMINIO}-${USUARIO}.cer ]]     && openssl ca -keyfile ${BASEDIR}/server/${DOMINIO}.rsa.key -cert ${BASEDIR}/server/${DOMINIO}.ca -in ${BASEDIR}/user/${DOMINIO}-${USUARIO}.csr -outdir ${BASEDIR}/user -out ${BASEDIR}/user/${DOMINIO}-${USUARIO}.cer -days ${DIASCRT} -extensions user_cert -extfile ${BASEDIR}/crt-self.cnf -config ${BASEDIR}/crt-self.cnf 
[[ ! -f ${BASEDIR}/user/${DOMINIO}-${USUARIO}.p12 ]]     && openssl pkcs12 -nodes -export -inkey ${BASEDIR}/user/${DOMINIO}-${USUARIO}.rsa.key -in ${BASEDIR}/user/${DOMINIO}-${USUARIO}.crt -certfile ${BASEDIR}/user/${DOMINIO}-${USUARIO}.cer -out ${BASEDIR}/user/${DOMINIO}-${USUARIO}.p12 -name "DOM:${DOMINIO} USR:${USUARIO}" 
[[ ! -f ${BASEDIR}/user/${DOMINIO}-${USUARIO}.pem ]]     && openssl pkcs12 -nodes -in ${BASEDIR}/user/${DOMINIO}-${USUARIO}.p12 -out ${BASEDIR}/user/${DOMINIO}-${USUARIO}.pem -name "DOM:${DOMINIO} USR:${USUARIO}" 



openssl pkcs12 -nodes -export -inkey ${BASEDIR}/user/${DOMINIO}-${USUARIO}.rsa.key -in ${BASEDIR}/user/${DOMINIO}-${USUARIO}.crt -certfile ${BASEDIR}/user/${DOMINIO}-${USUARIO}.cer -out ${BASEDIR}/user/${DOMINIO}-${USUARIO}.p12 -name "DOM:${DOMINIO} USR:${USUARIO}" 
openssl pkcs12 -nodes -in ${BASEDIR}/user/${DOMINIO}-${USUARIO}.p12 -out ${BASEDIR}/user/${DOMINIO}-${USUARIO}.pem -name "DOM:${DOMINIO} USR:${USUARIO}" 

##Verificar se IGUAIS .pem, .crt e .cer
[[ ! -z `diff <(ipsec pki --print --in ${BASEDIR}/user/${DOMINIO}-${USUARIO}.pem | grep -v "serial") <(ipsec pki --print --in ${BASEDIR}/user/${DOMINIO}-${USUARIO}.crt | grep -v "serial")` ]] && echo "*** ERRO user_cert: diferenca entre .pem e .crt !"
[[ ! -z `diff <(ipsec pki --print --in ${BASEDIR}/user/${DOMINIO}-${USUARIO}.pem | grep -v "serial") <(ipsec pki --print --in ${BASEDIR}/user/${DOMINIO}-${USUARIO}.cer | grep -v "serial")` ]] && echo "*** ERRO user_cert: diferenca entre .pem e .cer !"
[[ ! -z `diff <(ipsec pki --print --in ${BASEDIR}/user/${DOMINIO}-${USUARIO}.crt | grep -v "serial") <(ipsec pki --print --in ${BASEDIR}/user/${DOMINIO}-${USUARIO}.cer | grep -v "serial")` ]] && echo "*** ERRO user_cert: diferenca entre .crt e .cer !"
##Exibir Informacao
ipsec pki --print --in ${BASEDIR}/user/${DOMINIO}-${USUARIO}.crt

#    #openssl -in ${BASEDIR}/${DOMINIO}.crt -noout  -subject -issuer -alias -fingerprint -email -serial -dates -purpose
#    #openssl x509 -in ${BASEDIR}/${DOMINIO}.crt -noout -text
#    #openssl req -in ${BASEDIR}/${DOMINIO}.csr -noout -text



