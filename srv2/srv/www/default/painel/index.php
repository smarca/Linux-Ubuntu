<?php
/*
###########################################################################
#     Feito por Silmar A. Marca      smarca@gmail.com                     #
###########################################################################
#  *  A remocao destas linhas implica na nao observacao da licenca GNU *  #
#  *  Informe ao autor sobre falhas ou incremento de funcoes           *  #
#  *  Respeite a propriedade intelectual, http://www.gnu.org/          *  #
###########################################################################
# Tomando base o padrão exemplo do gerenciador VMC
*/
//Iniciar sessao
session_start();

//Incluir default 
include_once("lib/config.inc.php");

//Caso ja logado, continua
if (isset($_SESSION["domain"]))
 {
    unset($_SESSION["domain"]);
    header("Location: index.php?action=logout");
    exit;
 }
//caso nao, efetua  login
if (isset($_REQUEST['action'])) {
    switch ($_REQUEST['action']) {
    case 'login': {
			$_SESSION["domain"] = $_POST['domain'];
                       	$result = db_query("select * from domain where domain_name = '".$_POST['domain']."'");
                       	$row = db_fetch_array($result);
			$tmpcrypt = crypt($_POST['password'],"");
                         if ( (($tmpcrypt == crypt($_POST['password'],$tmpcrypt)) and (md5($_POST['password']) == $row["password_md5"])) or (($row["password_clear"] != "") and ($row["password_clear"] == $_POST['password'])) )
                         {
                              if ($row["ativo"] == "1") 
                              {
                         	$_SESSION["domain"] = $_POST['domain'];
			        $_SESSION["hstdomain"] = $row["hst"];
				if ($row["password_clear"] != "") {
                       		    $result = db_query("UPDATE domain SET `password_clear` = '' where domain_name = '".$_POST['domain']."'");
                       		    $row = db_fetch_array($result);
				}
                          	header("Location: marcavmc.php");
                         	exit;
                               } else {
                         	    sleep(3); //a nice little delay to piss script kiddies off
                          	    $message = "Dominio Inativo ou Desabilitado";
				}

                         }
                         else
                         {  
                         	sleep(3); //a nice little delay to piss script kiddies off
                          	$message = "Dominio Inexistente <br>ou Senha Inválida";
                         }
        }
        break;
    case 'logout': {
 	$message = "Logout efetuado";
        unset($_SESSION["domain"]);
	header("Location: index.php");
	}
   }
}

?>
<!-- Alterado e empacotado por Silmar A. Marca (smarca@gmail.com)  -->

<html>
        <head>
                <meta http-equiv="content-type" content="text/html;charset=iso-8859-1">
                <title>Administração de domínios </title>
                <style media="screen" type="text/css">
                    html { 
			transform: scale(1);
			transform-origin: top right;
			-moz-transform: scale(1);
			-moz-transform-origin: top right;
			zoom: 100%; 
		    }
		    a { color: black; text-decoration: none }
		    a:hover { color: gray; text-decoration: line-through }
		</style>
        </head>

        <body bgcolor="#ffffff" background="images/gbg.jpg">
<p align="center"><b><img src="images/titla.gif" width="294" height="32" align="absmiddle"></b></p>
<table border="0" cellpadding="2" cellspacing="0" width="280" align="center" height="150">
  <tr> 
    <td background="images/b.gif" width="276"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="2"><b>Identifique-se:</b></font></td>
  </tr>
  <tr height="131"> 
    <td bgcolor="#61705b" width="276" height="132" valign="top"> 
      <form name="FormName" action="index.php" method="post">
        <p align="center"><br>
          <font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="1"><b>Dominio: 
          &nbsp; 
          <input type="text" autocomplete="on" name="domain" size="35" style="FONT-SIZE: 10px; COLOR: white; FONT-FAMILY: geneva, arial; BACKGROUND-COLOR: #61705B" maxlength="128">
          <br>
          Senha: &nbsp;&nbsp; &nbsp; 
          <input type="password" autocomplete="off" name="password" size="35" style="FONT-SIZE: 10px; COLOR: white; FONT-FAMILY: geneva, arial; BACKGROUND-COLOR: #61705B">
          <br>
          &nbsp; 
          <input type="hidden" value="login" name="action">
          <input type="image" src="images/entrar.gif" name="image" align="right">
          </b> </font><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="1"><br>
          </font><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="2"><?=$message;?></font> 
        </p>
      </form>
    </td>
  </tr>
</table>
<table align="right" border="1" width="100">
<tr>
  <td align="center" colspan="2" class="menuitem" style="border-style: ridge">
   <a class="menuitem" target="_top" href="/" onmouseout="window.status='';" onmouseover="window.status='Servidor desenvolvido e mantido por: suporte@A'; return true;">Suporte</a>
  </td>
</tr>

</body>

</html>
