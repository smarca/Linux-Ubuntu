<?php
if ( !class_exists( 'popcmd' ) ) {
 class popcmd {
    //Variaveis
    var $host;		 //Host a conectar
    var $port;		 //Porta a conectar
    var $ptrc;           //Ponteiro da conexao
    var $gets;     	 //Ultimo resultado apos comando
    var $puts;    	 //Ultimo comando enviado
    var $retr;	 	 //Ultimo retorno obtido (Falso ou verdadeiro)

    //Constructor, inicializando host e porta
    function popcmd($host,$port) {          
        $this->host	= $host;
	$this->port	= $port;
    }

    //Conexao, retorna false se nao for possivel conectar
    function connect() {          
        $this->retr 	= false;
        $this->ptrc 	= fsockopen($this->host, $this->port, $err_no, $err_str);
        $this->gets 	= $err_no . " " . $err_str;
        if ($this->ptrc) 
            $this->retr = true;
	return $this->retr;
    }

    //Desconexao, retorna false se nao estava conectado
    function disconnect() {
	$this->retr      = false;
        if ($this->ptrc) {
            fclose($this->ptrc);
            $this->retr  = true;
        } 
        return $this->retr;
    }

    //Pega um prompt contendo inicialmente um numero 3 digitos, retorna false se nao tiver este
    //Ex: 200 OK, conectado ou 500 Falha, comando invalido...    
    function get1($idexperado) {
        $this->retr = false;
        $this->gets = fgets($this->ptrc, 4096);
        if (preg_match("/^[1-5][0-9][0-9]/",$this->gets)) {
            $this->retr = (substr($this->gets, 0, 3) == "$idexperado");
        }
        if ((!$this->retr) && (trim($this->gets) == "")) 
	    $this->gets = "503 Conexão negada ou indisponivel!";
        return $this->retr;      
    }

    //Envia comando, com o protocolo "id inicio, id fim comando.
    //O comando eh composto de comando e parametros
    function put2($idini,$idfim,$cmdm,$params="") {
        $this->retr = false;
        $this->puts = "$cmdm $params";			//Armazena ultimo comando
        if ($this->get1($idini)) {       		//Mensagem solicitando dados
    	    fputs($this->ptrc, $this->puts . "\n");	//Envio de dados iniciais
        	$this->retr = ($this->get1($idfim));  	//Mensagem confirmando termino do comando
        }
        return $this->retr;
    }
 }
}
//-------------------------------------------------------------------------------------------
class poppassd extends popcmd {
    var $domain;	//Dominio a executar
    var	$passwd;	//Senha do dominio

    //Constructor, inicializando host, porta, nome dominio e senha
    function poppassd($host,$port,$domain,$passwd) {          
        $this->domain	= $domain;	//Dominio
	$this->passwd 	= $passwd;	//Senha em MD5
	parent::popcmd($host,$port);
    }

    function deluser($user_name) {
        $this->retr = false;
        if ($this->connect()) 				  		//Conexao Inicial (Open Sock)
               if ($this->put2(200,226,"domain",$this->domain)) 	  //200 Qual dominio ou usuario? - 226 Dominio OK
            	    if ($this->put2(331,226,"domainpass",$this->passwd))  //331 Qual a senha do dominio? - 226 Senha do Dominio OK
            		if ($this->put2(331,226,"domainact","userdel"))   //331 Qual acao requerida? - 226 Acao desejada: xxx OK
            		    if ($this->put2(331,250,"user",$user_name))   //331 331 Qual usuario a deletar? - 250 Usuario deletado: xxx OK
            	    		if ($this->put2(331,200,"quit")) {   	  //331 Quit necessario - 200 Quit OK..
    					$this->disconnect();        	  //Desconectar
				    }
        return $this->retr;
    }
}
?>
