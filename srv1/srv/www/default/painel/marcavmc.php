<?php
/*
 * Main Logic/Functions etc..
 *
 */
//Iniciar sessao
session_start();

//Incluir default.
include_once("lib/config.inc.php");
if (!isset($_SESSION["domain"]))
 {
    header("Location: index.php");
    exit;
 }

if(!isset($_REQUEST["action"])) {
    show_menu($actioninfo);
} else
    switch ($_REQUEST["action"]) {
     	case "changedomainpw": //change the domain password
     	changedomainpw($_POST);
        break;

        case "changepoppw": //change a pop box password
        changepoppw($_POST);
        break;

        case "addforwarder": //add a forwarder
        addforwarder($_POST);
        break;

        case "deleteforwarder": //delete a forwarder
        deleteforwarder($_POST);
        break;
        
        case "addpop": //add a popbox
        addpop($_POST);
        break;

        case "deletepop": //delete a popbox
        deletepop($_POST);
        break;
        
        case "adddomainalias": //add a domain alias
        adddomainalias($_POST);
        break;
        
        default: //display the menu page
        show_menu($actioninfo);
        break;
     }
/*
 * Changes the password for the domain
 *
 */
function changedomainpw($fdata) {
    global  $tam_min_pass;
    $password = $fdata['password'];
    $password2 = $fdata['password2'];
    $password_hash = crypt($fdata['password'],"");
    $password_md5 = md5($fdata['password']);
    $domain_name = $_SESSION["domain"];
    	if (empty($password) || (strlen($password) < $tam_min_pass)) {
	      show_menu("Senha não alterada. <br> É necessário que a senha tenha $tam_min_pass ou mais caracteres!");
	      exit;
         } 
	 if (preg_match("/" . $domain_name . "/i", $password)) {
	      show_menu("Senha não alterada. <br> Não use o dominio como parte da senha!");
	      exit;
         }
        if (preg_match("/" . $password . "/i", $domain_name)) {
             	show_menu("Senha não alterada. A senha não pode estar contida em sua integra no dominio!");
             	exit;
         }  

	 if (!(( (preg_match("/[a-z]/i", $password)) or (preg_match("/[A-Z]/i", $password)) ) && ( (strlen($password) >= 15) or (preg_match("/[0-9]/i", $password)) or (preg_match("/[!@#$%^&*()_-]/i", $password)) or (preg_match("/[+=;:\"'<>,.?/\\|~`{}]/i", $password)) ))) {
	      show_menu("Senha não alterada. <br> A senha é muito fácil, use a combinação de letras mais números ou pontos na senha administrativa!");
	      exit;
          }
       if ($password != $password2)
             {
             	show_menu("Senha não alterada. A senha e sua verificação não são iguais!");
             	exit;
             }
       $result = db_query("UPDATE domain SET hst='".$_SESSION["hstdomain"]."', password_hash = '$password_hash', password_md5 = '$password_md5', password_clear = '$password', timepassch='" . date("Y-m-d H:i:s") . "' " .
                      "WHERE hst = '".$_SESSION["hstdomain"]."' and domain_name = '$domain_name'");
       show_menu("Senha do domínio alterada");
}

/*
 * Changes the password for a popbox
 *
 */
function changepoppw($fdata) {
    global  $tam_min_pass;
    $password = $fdata['password'];
    $password2 = $fdata['password2'];
    $password_hash = crypt($fdata['password'],"");
    $password_md5 = md5($fdata['password']);
    $domain_name = $_SESSION["domain"];
    $local_part = trim($fdata['local_part']);
    if (empty($local_part)) {
        show_menu("Não há o que alterar...");
    } else {
    	if (empty($password) || (strlen($password) < $tam_min_pass)) {
	      show_menu("Senha não alterada. <br> É necessário que a senha tenha $tam_min_pass ou mais caracteres!");
            } else {
            if ($password != $password2)
                 {
                 	show_menu("Senha não alterada. <br> A senha e sua verificação não são iguais!");
                 	exit;
                 }  
	    if (preg_match("/" . $password . "/i", $local_part . "@" . $domain_name))
                 {
                 	show_menu("Senha não alterada. <br> A senha não pode estar contida em sua integra no email!");
                 	exit;
                 }  

            $result = db_query("UPDATE popbox SET hst = '".$_SESSION["hstdomain"]."', password_hash = '$password_hash', password_md5 = '$password_md5', timepassch='" . date("Y-m-d H:i:s") . "' " .
                   "WHERE hst = '".$_SESSION["hstdomain"]."' and local_part = '$local_part' and domain_name = '$domain_name'");
            show_menu("Senha da caixa postal alterada");
          } 
	}
      
}
/*
 * Adds a forwarder
 *
 */
function addforwarder($fdata) {
	global $_SESSION;
        global $tam_min_pass, $tam_min_mail, $tam_max_mail;

        $domain_name = $_SESSION["domain"];
        $local_part = trim($fdata['local_part']);
        $remote_name = $fdata['remote_name'];

        $pop_stats = get_rem_popboxes();   
		if($pop_stats['aavailable'] <= 0)
                 {
                         show_menu("Apelido não adicionado! <br> Não há apelidos postais disponíveis!");
                         exit;
                 }
		if (empty($local_part)) {
		      show_menu("Apelido não adicionado. <br> É necessário informar ao menos uma letra no apelido!");
		      exit;
                }
		if (empty($remote_name) || (strlen($remote_name) > $tam_max_mail) || (strlen($remote_name) < $tam_min_mail)) {
		      show_menu("Apelido não adicionado. <br> É necessário informar entre $tam_min_mail e $tam_max_mail letras no destino!");
		      exit;
                }
		if (preg_match("/" . $domain_name . "/i", $remote_name)) {
		      show_menu("Apelido não adicionado. <br> Para dominios locais, não adicione @dominio.com!");
		      exit;
                }
		

                if (preg_match ("/^.+\@.+$/", $local_part))
                 {
                 	show_menu("Apelido não adicionado! <br> Por favor, entre somente com o apelido de email. <br> Não inclua o @dominio.com!");
                 	exit;
                 }
		 if (!preg_match ("/^.+\@(\[?)[a-zA-Z0-9\-\.]+\.([a-zA-Z]{2,3}|[0-9]{1,3})(\]?)$/", $remote_name))
                 {
		     $result = db_query("SELECT local_part FROM popbox WHERE hst = '".$_SESSION["hstdomain"]."' and local_part = '$remote_name'");
                     if (!($myrow = db_fetch_object($result))) {  
		         show_menu("Caixa postal inexistente. <br> Adicione uma conta com este nome e tente novamente!");
                 	 exit;
		      }	else {
		         $remote_name .= '@'.$domain_name; 		      
		      }
                 }
                 $result = db_query("SELECT local_part FROM forwarder WHERE hst = '".$_SESSION["hstdomain"]."' and local_part = '$local_part' ".
                                       "AND domain_name = '$domain_name'");
                 if ($myrow = db_fetch_object($result))
                 {
                	show_menu("Apelido não adicionado! <br> Já existente!");
                	exit;
                 }
                 $result = db_query("SELECT local_part FROM popbox WHERE hst = '".$_SESSION["hstdomain"]."' and local_part = '$local_part' ".
                                    "AND domain_name = '$domain_name'");
                 if ($myrow = db_fetch_object($result))
                 {
                 	show_menu("Apelido não adicionado! <br> Caixa postal existe com mesmo nome.");
                 	exit;
                 }
		 
    $result = db_query("INSERT INTO forwarder (hst,domain_name, local_part, remote_name) VALUES ".
                      "('".$_SESSION["hstdomain"]."','$domain_name', '$local_part', '$remote_name')");
    show_menu("Apelido adicionado");
}

/*
 * Deletes a forwarder
 *
 */
function deleteforwarder($fdata) {
    $local_part = trim($fdata['local_part']);
    $domain_name = $_SESSION["domain"];
    if (empty($local_part)) {
        show_menu("Não há o que excluir...");
    } else {
      $result = db_query("DELETE FROM forwarder WHERE hst = '".$_SESSION["hstdomain"]."' and local_part = '$local_part' ".
                       "AND domain_name = '$domain_name'");
      show_menu("Apelido removido");
    }
}

/*
 * Adds a popbox
 *
 */
function addpop($fdata) {
	global $pop_stats;
	global  $tam_min_pass, $tam_min_mail, $tam_max_mail;
	$password = $fdata['password'];
        $password2 = $fdata['password2'];
	$password_hash = crypt($fdata['password'],"");
	$password_md5 = md5($fdata['password']);
        $domain_name = $_SESSION["domain"];
        $local_part = $fdata['local_part'];
        $pop_stats = get_rem_popboxes();

                if($pop_stats['available'] <= 0)
                 {
                         show_menu("Caixa não adicionada! <br> Não há caixas postais disponíveis!");
                         exit;
                 }            
                //do be do be do some input checking

		if (empty($local_part) || (strlen($local_part) > $tam_max_mail) || (strlen($local_part) < $tam_min_mail)) {
		      show_menu("Caixa não adicionada. <br> É necessário informar entre $tam_min_mail e $tam_max_mail letras no nome!");
		      exit;
                }
		if (empty($password) || (strlen($password) < $tam_min_pass)) {
		      show_menu("Caixa não adicionada. <br> É necessário que a senha tenha $tam_min_pass ou mais caracteres!");
		      exit;
                }
	        if (preg_match("/" . $password . "/i", $local_part . "@" . $domain_name)) {
    	         	show_menu("Caixa não adicionada. <br> A senha não pode estar contida em sua integra no email!");
        	 	exit;
        	}  
                if ($password != $password2)
                 {
                 	show_menu("Caixa não adicionada! <br> Senhas da caixa postal não são iguais!");
                 	exit;
                 }
                if (preg_match ("/^.+\@(\[?)[a-zA-Z0-9\-\.]+\.([a-zA-Z]{2,3}|[0-9]{1,3})(\]?)$/", $local_part))
                 {
                 	show_menu("Caixa não adicionada! <br> Por favor, entre somente com um usuário de email. <br> Não inclua o @dominio.com!");
                 	exit;
                 }       
                $result = db_query("SELECT local_part FROM popbox WHERE hst = '".$_SESSION["hstdomain"]."' and local_part = '$local_part' ".
                                    "AND domain_name = '$domain_name'");
                if ($myrow = db_fetch_object($result))
                 {
                 	show_menu("Caixa não adicionada! <br> Já existente!");
                 	exit;
                 }
                $result = db_query("SELECT local_part FROM forwarder WHERE hst = '".$_SESSION["hstdomain"]."' and local_part = '$local_part' ".
                                       "AND domain_name = '$domain_name'");
                if ($myrow = db_fetch_object($result))
                 {
                 	show_menu("Caixa não adicionado! <br> Apelido postal existe com mesmo nome.");
                 	exit;
                 }           
    $result = db_query("INSERT INTO popbox (hst,domain_name, local_part, password_hash, password_md5, timepassch) ".
                       "VALUES ('".$_SESSION["hstdomain"]."','$domain_name', '$local_part', '$password_hash', '$password_md5', '" . date("Y-m-d H:i:s") . "')");
    
    //---------------------Mensagem de boas vindas------------------------
    $mailto    = "$local_part"."@"."$domain_name";
    $subject   = "Seja bem vindo ("."$domain_name".")!";
    $headers   = "From: $mailto\n";
    $headers  .= "X-Priority: 1\n";
    $headers  .= "Importance: High\n";
    $headers  .= "X-MSMail-Priority: High\n";
    $mensagem  = "Seja bem vindo ao domínio $domain_name!\n"; 
    $mensagem .= "---------------------------------------\n";
    $mensagem .= "Leia os emails e troque sua senha via página: http://webmail."."$domain_name"."/\n";
    $mensagem .= "---------------------------------------\n";
    $mensagem .= "Servidor pop3:  pop."."$domain_name\n";
    $mensagem .= "Servidor smtp: smtp."."$domain_name"." (Requer Autenticação)\n"; 
    mail($mailto, $subject , $mensagem, $headers);
    //---------------------Fim mensagem boas vindas-----------------------
    show_menu("Caixa postal adicionada");
}

/*
 * Deletes a popBox
 *
 */
function deletepop($fdata) {
    global $wwwuser, $wwwpass, $wwwdbname, $wwwdbhost;
    global $dbhost, $dbpwport;
    $domain_name = $_SESSION["domain"];
    $local_part = trim($fdata['local_part']);
    if (empty($local_part)) {
        show_menu("Não há o que excluir...");
    } else {
      $result = db_query("SELECT alias FROM domain WHERE hst = '".$_SESSION["hstdomain"]."' and alias = '$local_part' AND domain_name = '$domain_name'");
      if ($myrow = db_fetch_object($result))
          show_menu("Esta conta é a conta padrão do domínio. <br> Exclua a conta padrão e tente novamente!");
      else {		           
            $result = db_query("SELECT remote_name FROM forwarder WHERE hst = '".$_SESSION["hstdomain"]."' and remote_name = '$local_part@$domain_name'");
            if ($myrow = db_fetch_object($result))
                show_menu("Uma apelido usa esta conta. <br> Exclua o apelido e tente novamente!");
            else {
               $result = db_query("select * from domain where hst = '".$_SESSION["hstdomain"]."' and domain_name = '".$domain_name."'");
               $row = db_fetch_array($result);
            //PoppassConexao, IMP, maildb
               include "popcmd.php";
               $daemon = new poppassd($dbhost,$dbpwport,$domain_name,$row["password_md5"]);
	       if ($daemon->deluser($local_part)) {
                   $result = db_query("DELETE FROM popbox WHERE hst = '".$_SESSION["hstdomain"]."' and local_part = '$local_part'" .
                                      "AND domain_name = '$domain_name'");
	           // require("lib/imp.inc.php");
                   show_menu("Caixa postal removida");
               }  else {
                   show_menu("Caixa postal inalterada:<br>" . $daemon->gets);
               }
               unset($daemon);
             //FimPoppassConexao, IMP, maildb
            }
	}
      }
    }
/*
 * Adds a Domain Alias
 */
function adddomainalias($fdata) {
    $domain_name = $_SESSION["domain"];
    $alias = trim($fdata['alias']);
    $result = db_query("SELECT local_part FROM popbox WHERE hst = '".$_SESSION["hstdomain"]."' and local_part = '$alias'");
                if (($myrow = db_fetch_object($result)) || (empty($alias))) 
                 {
		    $result = db_query("UPDATE domain SET hst='".$_SESSION["hstdomain"]."', alias = '$alias' ".
                       "WHERE hst = '".$_SESSION["hstdomain"]."' and domain_name = '$domain_name'");
		    if (empty($alias))   
		        show_menu("Apelido padrão removido!");
		    else
		        show_menu("Apelido padrão modificado");  
		 
                 } else {	 
                	show_menu("Caixa postal padrão inexistente. <br> Adicione uma conta com este nome e tente novamente!");
                	exit;
		 }
}

function show_menu($actioninfo = "") {
include("menu.php");
}

/*
 * Gets popbox stats like how many are available etc..
 *
 */
function get_rem_popboxes() {
global $pop_stats;
$domain_name = $_SESSION["domain"];
                        $result = db_query("SELECT COUNT(*) AS used FROM popbox WHERE hst = '".$_SESSION["hstdomain"]."' and domain_name = '$domain_name'");
                        $row = db_fetch_array($result);
                        $result = db_query("SELECT COUNT(*) AS used FROM forwarder WHERE hst = '".$_SESSION["hstdomain"]."' and domain_name = '$domain_name'");
                        $row1 = db_fetch_array($result);
                        $result = db_query ("SELECT quotas, quotac, max_popbox, max_alias FROM domain WHERE hst = '".$_SESSION["hstdomain"]."' and domain_name = '$domain_name'");
                        $row2 = db_fetch_array($result);
                        $pop_stats['total'] = $row2["max_popbox"];
                        $pop_stats['atotal'] = $row2["max_alias"];
                        $pop_stats['used'] = $row["used"]; 
                        $pop_stats['aused'] = $row1["used"]; 
                        $pop_stats['available'] = $pop_stats['total'] - $pop_stats['used'];
                        $pop_stats['aavailable'] = $pop_stats['atotal'] - $pop_stats['aused'];
                        $pop_stats['quotas'] = $row2["quotas"];
                        $pop_stats['quotac'] = $row2["quotac"];
                        return $pop_stats;
}
?>

