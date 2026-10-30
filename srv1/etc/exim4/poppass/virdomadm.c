/*
 * Silmar A. Marca <smarca@gmail.com>
 * Based on Cetil popasswd
 *
 * apt-get install libpam0g-dev
 * apt-get install libmysqlclient-dev
 *
 */

/*
 * poppassd.c
 *
 * A Eudora and NUPOP change password server.
 *
 * Pawel Krawczyk <kravietz@echelon.pl>
 *
 * Based on poppassd by John Norstad <j-norstad@nwu.edu>,
 * Roy Smith <roy@nyu.edu> and Daniel L. Leavitt <dll.mitre.org>.
 * Shadow file update code taken from shadow-960810 by John F. Haugh
 * II <jfh@rpp386.cactus.org> and Marek Michalkiewicz
 * <marekm@i17linuxb.ists.pwr.wroc.pl>
 *
 * See README for more information.
 */

/* Steve Dorner's description of the simple protocol:
 *
 * The server's responses should be like an FTP server's responses;
 * 1xx for in progress, 2xx for success, 3xx for more information
 * needed, 4xx for temporary failure, and 5xx for permanent failure.
 * Putting it all together, here's a sample conversation:
 *
 *   S: 200 hello\r\n
 *   E: user yourloginname\r\n
 *   S: 300 please send your password now\r\n
 *   E: pass yourcurrentpassword\r\n
 *   S: 200 My, that was tasty\r\n
 *   E: newpass yournewpassword\r\n
 *   S: 200 Happy to oblige\r\n
 *   E: quit\r\n
 *   S: 200 Bye-bye\r\n
 *   S: <closes connection>
 *   E: <closes connection>
 */


#define VERSION 		"2.0"	/* version */
#define _GNU_SOURCE			/* Macros */
#define BAD_PASS_DELAY 		5 	/* delay in seconds after bad 'Old password' */
#define POP_MIN_UID		100   	/* minimum UID which is allowed to change password via poppassd */
#define POP_MAX_UID		65000 	/* maximum UID which is allowed to change password via poppassd */
#define POP_MIN_GID		100   	/* minimum GID which is allowed to change password via poppassd */
#define POP_MAX_GID		65000 	/* maximum GID which is allowed to change password via poppassd */

#define MAX_LEN_COMMAND   	"128"	/* maximum length of command in domain mode */
#define BUFSIZE 		1000
#define SUCCESS 		1
#define FAILURE 		0

#define DB_HOST 		"localhost" 		/* mysql host */
#define SERVICE 		"virdomadm" 		/* nome do servico */

#include <sys/types.h>
#include <fcntl.h>
#include <syslog.h>
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <strings.h>
#include <errno.h>
#include <stdarg.h>
#include <pwd.h>
#include <string.h>
#include <dirent.h>
#include <shadow.h>
#include <signal.h>
#include <sys/time.h>
#include <sys/wait.h>
#if !__GLIBC__ >= 2
#include <ulimit.h>
#endif
#include <security/pam_appl.h>
#include <security/pam_misc.h>
#include <mysql/mysql.h>
#include <unistd.h>

#define LOCK_TRIES 30

#ifndef UL_SETFSIZE
#ifdef UL_SFILLIM
#define UL_SETFSIZE UL_SFILLIM
#else
#define UL_SETFSIZE 2
#endif
#endif


/* mysql dom virtual */
 MYSQL      dbase;
 MYSQL_RES  *result;
 MYSQL_ROW  row;
 char 	sqlbuff[1024];
 int 	nrows;

/* need to be global for poppassd_conv */
char oldpass[BUFSIZE];
char newpass[BUFSIZE];
#define POP_OLDPASS 0
#define POP_NEWPASS 1
#define POP_SKIPASS 2
short int pop_state = POP_OLDPASS;

//Exit em caso de erros
void xexit(const int status) {
      	    mysql_free_result(result);
            mysql_close (&dbase);
            closelog();
            if (status)
               sleep(BAD_PASS_DELAY);
            exit(status);
}

//Escreve ao cliente
void WriteToClient (char *fmt, ...)
{
        va_list ap;

        va_start (ap, fmt);
        vfprintf (stdout, fmt, ap);
        fputs ("\r\n", stdout );
        fflush (stdout);
        va_end (ap);
}

//Le do cliente
void ReadFromClient (char *line)
{
        char *sp;
        int i;
	char *ret;

        bzero(line, BUFSIZE);
        ret=fgets (line, BUFSIZE-1, stdin);
        if ((sp = strchr(line, '\n')) != NULL) *sp = '\0';
        if ((sp = strchr(line, '\r')) != NULL) *sp = '\0';

        /* convert initial keyword on line to lower case. */

        for (sp = line; isalpha(*sp); sp++) *sp = tolower(*sp);
        line[BUFSIZE-1] = '\0';
}

//Converte pra pam
int poppassd_conv(num_msg, msg, resp, appdata_ptr)
    int         num_msg;
    const struct pam_message **msg;
    struct pam_response **resp;
    void        *appdata_ptr;
{
        int i;
        struct pam_response *r = malloc(sizeof(struct pam_response) * num_msg);

        if(num_msg <= 0)
                return(PAM_CONV_ERR);

        if(r == NULL)
                return(PAM_CONV_ERR);

        for(i=0; i<num_msg; i++) {
                if(msg[i]->msg_style == PAM_ERROR_MSG) {
                       WriteToClient ("500 PAM error: %s", msg[i]->msg);
                       syslog(LOG_ERR, "PAM error: %s", msg[i]->msg);
                       /*
                        * If there is an error, we don't want to be sending in
                        * anything more, so set pop_state to invalid
                        */
                       pop_state = POP_SKIPASS;
                }

        r[i].resp_retcode = 0;
        if(msg[i]->msg_style == PAM_PROMPT_ECHO_OFF ||
                        msg[i]->msg_style == PAM_PROMPT_ECHO_ON)
        {
                switch(pop_state) {
                        case POP_OLDPASS: r[i].resp = strdup(oldpass);
                                          break;
                        case POP_NEWPASS: r[i].resp = strdup(newpass);
                                          break;
                        case POP_SKIPASS: r[i].resp = NULL;
                                          break;
                        default: syslog(LOG_ERR, "PAM error: too many switches (state=%d)", pop_state);
                }
        } else
        {
                r[i].resp = strdup("");
        }
        }

        *resp = r;
        return PAM_SUCCESS;
}

const struct pam_conv pam_conv = {
        poppassd_conv,
        NULL
};
	

//Remove diretorio
int deltree(char *diretorio) {
    int pid, status, retorno;
    if (!(!strncmp(diretorio,"/var/spool/virtual/",19) || !strncmp(diretorio,"/var/www/home/",14) || !strncmp(diretorio,"/srv/www/home/",14) || !strncmp(diretorio,"/srv/mail/",10))) {
        WriteToClient ("500 Diretorio %s proibido para delecao! O mesmo deve estar abaixo de /var/spool/virtual/, /var/www/home/, /srv/www/home/ ou /srv/mail/",diretorio);  
        syslog(LOG_ERR, "Diretorio bloqueado pra delecao: %s", diretorio);
        xexit(1);
    }     
    if ((pid = fork()) < 0) {  //Evita looping
        WriteToClient ("500 Muitas chamadas!");
        syslog(LOG_ERR, "Muitas chamadas: deltree: %i",pid);
        perror("fork");
        xexit(1);
    }
    if (pid == 0) {
    	retorno = execl("/bin/rm", "rm", "-rf", diretorio, (char *)0);
    }   
    //Aguardar execucao a fim de evitar loopings
    while (wait(&status) != pid);
    return retorno;
}

int main (int argc, char *argv[])
{
     char line[BUFSIZE];
     char nodb[BUFSIZE], user[BUFSIZE];
     char dbbd[BUFSIZE], dbuser[BUFSIZE], dbpass[BUFSIZE], domain[BUFSIZE], domainpass[BUFSIZE], domainact[BUFSIZE], domainobj[BUFSIZE];
     struct passwd *pw, *getpwnam();
     int flag, enabledb;
     pam_handle_t *pamh=NULL;
     
//Inicializacao de Variaveis
     *line = 0;
     enabledb = 1;
     *nodb = *user = *oldpass = *newpass = 0;				/* normal vars*/
     *dbbd = *dbuser = *dbpass = *domain = *domainpass = *domainact = *domainobj = 0; 	/* mysql vars*/

//Verificacao dos argumentos
    if (argc == 2) {
	sscanf (argv[1], "nodb=%" MAX_LEN_COMMAND "s", nodb) ; 
	if (strlen (nodb) == 0 ) {
	    WriteToClient ("500 Daemon mau configurado [nodb=yes | dbbd=bancodb dbuser=usuriodb dbpass=senhadb]!"); xexit(1); 
	} else {
	    enabledb = 0;
	}
    } else {
	if (argc <= 3) {
	    WriteToClient ("500 Daemon mau configurado [nodb=yes | dbbd=bancodb dbuser=usuriodb dbpass=senhadb]!"); xexit(1); }
	sscanf (argv[1], "dbbd=%" MAX_LEN_COMMAND "s", dbbd) ; 
	if (strlen (dbbd) == 0 ) {
	    WriteToClient ("500 Banco bd requerido: dbbd=bancodb"); xexit(1); }
	sscanf (argv[2], "dbuser=%" MAX_LEN_COMMAND "s", dbuser) ; 
	if (strlen (dbuser) == 0 ) {
	    WriteToClient ("500 Usuario bd requerido: dbuser=usuariodb"); xexit(1); }
	sscanf (argv[3], "dbpass=%" MAX_LEN_COMMAND "s", dbpass) ; 
	if (strlen (dbpass) == 0 ) {
	    WriteToClient ("500 Senha bd requerida: dbpass=senhadb"); xexit(1); }
    }

//Log
     openlog(SERVICE, LOG_PID, LOG_LOCAL4);
    //Fase 1 - Dominio ou Usuario
     WriteToClient ("200 Qual usuario ou dominio? [user|domain]");
     ReadFromClient (line);
     flag = 0;
     //Verifica Clausula User ou dominio
     if (!strncmp(line,"user ",5)) {
        flag = 1; 
     } else if (!strncmp(line,"domain",6)) {
        flag = 2; }
     switch (flag) {
        case 1: 
	    sscanf (line, "user %" MAX_LEN_COMMAND "s", user) ; 
	    WriteToClient ("200 Informe a senha antiga [pass]:");
	    ReadFromClient (line);
	    sscanf (line, "pass %" MAX_LEN_COMMAND "c", oldpass);
	    if(strlen(oldpass) == 0) { 
		WriteToClient("500 Senha esperada [pass]!"); xexit(1); }
	    WriteToClient ("200 Informe a nova senha [newpass]:");
		ReadFromClient (line);
	    sscanf (line, "newpass %" MAX_LEN_COMMAND "c", newpass);
	    if (strlen (newpass) == 0) {
	        WriteToClient ("500 Nova senha esperada [newpass]!"); xexit(1); }

	    //Caso seja um nome simples, sem arroba
	    if (strchr(user,'@') == 0) {
        	    if (!strcmp(user,"root")) {
    			WriteToClient("500 Usuario bloqueado!"); syslog(LOG_ERR, "usuario bloqueado %s", user); xexit(1); }
    		    if(pam_start(SERVICE, user, &pam_conv, &pamh) != PAM_SUCCESS) { 
			WriteToClient("500 Usuario invalido!"); syslog(LOG_ERR, "usuario invalido %s", user); xexit(1); }
		    if(pam_authenticate(pamh, 0) != PAM_SUCCESS) {
			WriteToClient ("500 Senha antiga incorreta!"); syslog(LOG_ERR, "senha antiga incorreta de %s", user); xexit(1); }
		    pw=getpwnam(user);
		    if(pw->pw_uid<POP_MIN_UID || pw->pw_uid>POP_MAX_UID || pw->pw_gid<POP_MIN_GID || pw->pw_gid>POP_MAX_GID || pw == NULL) {
			WriteToClient("500 Proibido trocar senha!"); syslog(LOG_ERR, "proibido trocar senha de %s", user); xexit(1); }
		    pop_state = POP_NEWPASS;
		    if(pam_chauthtok(pamh, 0) != PAM_SUCCESS) {
		        WriteToClient("500 Erro no servidor, senha inalterada!"); xexit(1);
		    } else {
		        syslog(LOG_ERR, "trocado senha de %s", user);
		        WriteToClient("200 Senha alterarda, obrigado.");
    		    }
		    pam_end(pamh, 0);
	    } else {
		    //Caso seja um domonio completo, logo sql
		    //Conexao com banco de dados
		    if(mysql_init(&dbase) == NULL) {
			WriteToClient ("500 Erro ao abrir o banco de dados!"); xexit(1); }
		    if(mysql_real_connect(&dbase,DB_HOST,dbuser,dbpass,dbbd,0,NULL,0) == NULL) {
			WriteToClient ("500 Erro ao autenticar-se na base de dados!"); xexit(1); }
		    //Selecao da Tabela, verificando se a senha do dominio esta correta
		    sprintf(sqlbuff,"SELECT concat(popbox.local_part, '@', domain.domain_name) as user, popbox.password_md5 as oldpass1,  md5(\'%s\') as oldpass2 FROM `popbox` LEFT JOIN `domain` ON ( popbox.domain_name = domain.domain_name ) WHERE (domain.ativo = '1' AND popbox.ativo = '1') AND (concat( popbox.local_part, '@', domain.domain_name ) = \'%s\')",oldpass,user);
		    if(mysql_real_query(&dbase,sqlbuff,strlen(sqlbuff))) {
			WriteToClient ("500 Erro ao executar a consultar o BD!"); xexit(1);
		    } else {
			result = mysql_store_result(&dbase);
			nrows = mysql_num_rows(result);
			if(nrows == 0){
			    WriteToClient ("500 Usuario de dominio '%s' inexistente ou desativado!",user);  syslog(LOG_ERR, "usuario %s inexistente ou desativado!", user);  xexit(1); 
			} else {
			    row = mysql_fetch_row(result);
			    if (strcmp (row[0],user) != 0) {
				WriteToClient ("500 Usuario de dominio '%s' inexistente ou desativado!",user); xexit(1); syslog(LOG_ERR, "usuario %s inexistente ou desativado!", user); xexit(1); }
			    if (strcmp (row[1],row[2]) != 0) {
				WriteToClient ("500 Senha antiga do usuario de dominio '%s' invalida!",user); xexit(1); syslog(LOG_ERR, "senha antiga incorreta de %s", user); xexit(1); 
			    } else {
				//Selecao da Tabela, verificando se a senha do dominio esta correta
				//sprintf(sqlbuff,"UPDATE `popbox` SET popbox.timepassch = now(), popbox.password_md5 = md5(\'%s\'), popbox.password_hash = encrypt(\'%s\',concat(sha1(rand()),md5(rand()))) WHERE (concat( popbox.local_part, '@', popbox.domain_name ) = \'%s\')",newpass,newpass,user);
				sprintf(sqlbuff,"UPDATE `popbox` SET popbox.timepassch = now(), popbox.password_md5 = md5(\'%s\'), popbox.password_hash = encrypt(\'%s\') WHERE (concat( popbox.local_part, '@', popbox.domain_name ) = \'%s\')",newpass,newpass,user);
				if(mysql_real_query(&dbase,sqlbuff,strlen(sqlbuff))) {
				    WriteToClient ("500 Erro ao atualizar BD durante a troca de senha!"); xexit(1); }
			    }
			}
		    }
		    syslog(LOG_ERR, "trocado senha de %s", user);
		    WriteToClient("200 Senha alterarda, obrigado.");
    		}

		    //sscanf(user, "%64[^@]",  usrpart);	//Maximo tamanho 64 para usuario
		    //syslog(LOG_ERR, "OK %s", usrpart);

		    /* Exemplo de Substring:
		    char *uri_field = "mail:username@example.com";
		    char username[64];
		    sscanf(uri_field, "mail:%63[^@]", username);
		    syslog(LOG_ERR, "Substr1: %s",username);
		    sscanf(uri_field, "%*[^:]:%63[^@]", username);
		    syslog(LOG_ERR, "Substr2: %s",username);
		    */
		//strncpy(usrpart, user, (unsigned)strchr(user,'@')-1);
		//strncpy(dompart, user+(unsigned)strchr(user,'@')+1,(unsigned)strlen(user));
		//WriteToClient("500 Senha alterarda, obrigado.");
		//WriteToClient("500 Usr: %s Domain: %s",usrpart,dompart);  xexit(1);
		//syslog(LOG_ERR, "Dominio: %s", dompart); 
	    	//syslog(LOG_ERR, "Usuario: %s", usrpart);
    	    break;
	case 2:
	    if (!enabledb) {
		WriteToClient ("500 Banco de dados desabilitado!"); xexit(1); }
	    //Leitura do dominio
	    sscanf (line, "domain %" MAX_LEN_COMMAND "s", domain) ;
    	    WriteToClient ("226 Dominio OK");
	    //Leitura da senha do dominio
	    WriteToClient ("331 Qual a senha md5 do dominio '%s'? [domainpass]", domain);
	    ReadFromClient (line);
	    sscanf (line, "domainpass %" MAX_LEN_COMMAND "s", domainpass);
	    if (strlen (domainpass) == 0 ) {
		WriteToClient ("500 Senha md5 requerida [domainpass]!"); xexit(1); }
	    WriteToClient ("226 Senha do Dominio OK");
	    //Conexao com banco de dados
	    if(mysql_init(&dbase) == NULL) {
		WriteToClient ("500 Erro ao abrir o banco de dados!"); xexit(1); }
	    if(mysql_real_connect(&dbase,DB_HOST,dbuser,dbpass,dbbd,0,NULL,0) == NULL) {
		WriteToClient ("500 Erro ao autenticar-se na base de dados!"); xexit(1); }
	    //Selecao da Tabela, verificando se a senha do dominio está correta
	    sprintf(sqlbuff,"Select domain.password_md5 from domain where domain.domain_name = \'%s\'",domain);
	    if(mysql_real_query(&dbase,sqlbuff,strlen(sqlbuff))) {
		WriteToClient ("500 Erro ao executar a QUERY!"); xexit(1);
	    } else {
		result = mysql_store_result(&dbase);
		nrows = mysql_num_rows(result);
		if(nrows == 0){
		    WriteToClient ("500 Dominio '%s' inexistente!",domain); xexit(1); 
		} else {
		    row = mysql_fetch_row(result);
		    if (strcmp (row[0],domainpass) != 0) {
			WriteToClient ("500 Senha do dominio '%s' invalida!",domain); xexit(1); }
		}
	    }
	    //Leitura da acao sobre o dominio
	    WriteToClient ("331 Qual a acao que deseja fazer para o dominio '%s'? [domainact]", domain);
	    ReadFromClient (line);
	    sscanf (line, "domainact %" MAX_LEN_COMMAND "s", domainact);
	    if (strlen (domainact) == 0 ) {
		WriteToClient ("500 Acao requerida [domainact]!"); xexit(1); 
	    } else WriteToClient ("226 Acao desejada: %s",domainact);
	    flag = 0; 
	    if (!strcmp(domainact,"userdel")) { //Verifica usuario
    		flag = 1; } 
	    switch (flag) {
    		case 1: 
		    WriteToClient ("331 Qual usuario a deletar de '%s'? [user]", domain);
		    ReadFromClient (line);
		    sscanf (line, "user %" MAX_LEN_COMMAND "s", domainobj);
		    if (strlen (domainobj) == 0 ) {
			WriteToClient ("500 Usuario requerido [user]!"); xexit(1); }
		    //Selecionar Home do usuario
		    sprintf(sqlbuff,"SELECT CONCAT(domain.home,'/mails/',popbox.local_part) FROM domain, popbox WHERE popbox.local_part=\'%s\' AND popbox.domain_name=\'%s\' AND popbox.domain_name = domain.domain_name",domainobj,domain);
		    if(mysql_real_query(&dbase,sqlbuff,strlen(sqlbuff))) {
			WriteToClient ("500 Erro ao executar a QUERY!"); xexit(1);
		    } else {
        		result = mysql_store_result(&dbase);
        		nrows = mysql_num_rows(result);
			if(nrows == 0){
			    WriteToClient ("500 Usuario do dominio '%s' inexistente:'%s'!",domain,domainobj); xexit(1);
			} else {
			    row = mysql_fetch_row(result);
			    if (deltree(row[0])) {
				WriteToClient ("250 Usuario deletado: %s",domainobj); syslog(LOG_INFO, "Usuario removido: %s@%s", domainobj,domain);
			    } else {
                		WriteToClient ("500 problemas com a delecao do usuario: %s!",domainobj); syslog(LOG_ERR, "Problemas ao remover o diretorio do usuario %s: %s", domainobj,row[0]);  
            		    }
        		}
		    break;
    		case 2: 
		    WriteToClient ("500 Nao disponivel no momento [domaindel]!"); xexit(1);
		    break;
		default:
		    WriteToClient ("500 [userdel|domaindel] required!"); xexit(1);
		    break;
		}
            }
	    WriteToClient ("331 Quit necessario [quit]");
    	    break;
	default:  
	    WriteToClient ("500 Dominio ou usuario esperado [domain|user]!"); 
	    xexit(1); 
        break;
     }

    //Leitura do quit
    ReadFromClient (line);
    if (strncmp(line, "quit", 4) != 0) { 
	WriteToClient("500 Quit esperado [quit]!"); xexit (1); }
    //Exit
     WriteToClient ("200 %s v%s [thanks]", SERVICE, VERSION);
     closelog();
     xexit(0);
}

