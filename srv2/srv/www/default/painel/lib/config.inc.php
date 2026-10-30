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

//Startup Session
if (!isset($_SESSION['domain_test_count'])) {
    $_SESSION['domain_test_count'] = 0;
}
$_SESSION['domain_test_count']++;

////************************************************************///////

	//Definicao de Variaveis
	global $message, $actioninfo;

        //tabela usuarios
	global $dbuser, $dbpass, $dbname, $dbhost, $dbpwport, $dbselect;
        $dbuser = "virtualmailmgr";
	$dbpass = "marcaisowner";
	define ("DBNAME","maildb");
	$dbhost = "localhost";
        $dbpwport = "106";

        //tabela horde
        global $wwwuser, $wwwpass, $wwwdbname, $wwwdbhost; 
        $wwwuser = "horde5";
	$wwwpass = "Awp0Kr##.Hanq";
	$wwwdbname = "horde";
	$wwwdbhost = "localhost";

        global  $tam_min_pass, $tam_min_mail, $tam_max_mail;
        $tam_min_pass = 4;
        $tam_min_mail = 2;
        $tam_max_mail = 30;
			
////************************************************************///////

   $link = @mysqli_connect( $dbhost, $dbuser, $dbpass );
   if ( ! $link )
    {
	if (DEV == 0)
	  echo "<p><font color=\"#ff0000\"><b>Erro ao efetuar conexão com o banco de dados!</b></font><br>Please contact ORGNAME support</p>";
	else
		echo mysqli_error();
     return false;
     }
     $dbselect = mysqli_select_db( $link, DBNAME );
     if ( ! $dbselect )
     {
     $dberror = mysqli_error();
     return false;
     }

	
/* mysqli_query wrapper that supports error handling*/	
function db_query($sqlstring)
{      global $link, $dbhost, $dbuser, $dbpass, $dbname;
       $link = @mysqli_connect( $dbhost, $dbuser, $dbpass );
        mysqli_select_db( $link, DBNAME );
	if(!($result = mysqli_query($link, $sqlstring)))
	{
		echo '<p><font color="#FF0000"><b>Um erro foi encontrado: </font>'.mysqli_error()."</b>";
		if (DEV == 1) //only display the query string when in 'dev' mode
			echo "<br>Query: $sqlstring";
		echo "<br>Favor contacte o administrador de rede para maiores detalhes.</p>";
		die;
	}
	else
		return $result;
}	
function db_fetch_object($result)
{
	/*
	if(!($object = mysqli_fetch_object($result)))
	{
		echo '<p><font color="#FF0000"><b>Um erro foi encontrado: </font>'.mysqli_error()."</b>";
		if (DEV == 1) //only display the query string when in 'dev' mode
			echo "<br>Query: $result";
		echo "<br>Favor contacte o administrador de rede para maiores detalhes.</p>";
		die;
	}
	else
	*/
	    $object = mysqli_fetch_object($result);
		return $object;
}	
function db_fetch_array($result)
{
	/*
	if(!($array = mysqli_fetch_array($result)))
	{
		echo '<p><font color="#FF0000"><b>Um erro foi encontrado: </font>'.mysqli_error()."</b>";
		if (DEV == 1) //only display the query string when in 'dev' mode
			echo "<br>Query: $result";
		echo "<br>Favor contacte o administrador de rede para maiores detalhes.</p>";
		die;
	}
	else
	*/
	     $array = mysqli_fetch_array($result);
		return $array;
}
function db_insert_id($result)
{
	     $id = mysqli_insert_id();
		return $id;
}

function db_num_rows($result)
{
	     $rows = mysqli_num_rows($result);
		return $rows;
}			
?>
