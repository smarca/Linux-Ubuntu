<?php
/*
###########################################################################
#     Feito por Silmar A. Marca     smarca@gmail.com                      #
###########################################################################
#  *  A remocao destas linhas implica na nao observacao da licenca GNU *  #
#  *  Informe ao autor sobre falhas ou incremento de funcoes           *  #
#  *  Respeite a propriedade intelectual, http://www.gnu.org/          *  #
###########################################################################
# Tomando base o padrão exemplo do gerenciador VMC
*/
if (!isset($_SESSION["domain"]))
 {
 	include("index.php");
 	exit;
 }
?>
<html>
        <head>
                <meta http-equiv="content-type" content="text/html;charset=iso-8859-1">
                <title>Administração de domínios (<? echo $_SESSION["domain"]; ?>)</title>
                <META NAME="MailAutoria" content="Silmar A. Marca (smarca@gmail.com)">
<script>
<!--
function areYouSure()
{
	return confirm("Confirma operação?");
}
//-->
</script>
                <style media="screen" type="text/css">
		<!--
                     a { color: black; text-decoration: none }
                     a:hover { color: gray; text-decoration: line-through }
                --></style>
        </head>

<?php
  $result = db_query("select local_part,lastchange, DATEDIFF(now(),lastchange) AS diffdate from popbox where hst = '".$_SESSION["hstdomain"]."' and domain_name = '".$_SESSION["domain"]."' order by local_part ASC");
  $popuserlst_pwd = '<select name="local_part" size="1" style="FONT-SIZE: 10px; COLOR: white; FONT-FAMILY: geneva, arial; BACKGROUND-COLOR: #61705B">';
    $popuserlst_pwd .= '<option value="">-&nbsp;-&nbsp;-&nbsp;-&nbsp;-&nbsp;-&nbsp;-&nbsp;-&nbsp;-</option>';
    while($row = db_fetch_array($result))
    {
	if ($row["diffdate"] > 1000) {
	    $popuserlst_pwd .= '<option value="'.$row["local_part"].'" title="'.$row["lastchange"] .'" style="background-color:#E60000">'.$row["local_part"].'</option>';
	} else if ($row["diffdate"] >= 365) {
	    $popuserlst_pwd .= '<option value="'.$row["local_part"].'" title="'.$row["lastchange"] .'" style="background-color:#CCCC00">'.$row["local_part"].'</option>';
	} else {
	    $popuserlst_pwd .= '<option value="'.$row["local_part"].'" title="'.$row["lastchange"] .'" style="background-color:#008000">'.$row["local_part"].'</option>';
	}
    }
    
    $popuserlst_pwd .= '</select>';

  $result = db_query("select local_part from popbox where hst = '".$_SESSION["hstdomain"]."' and domain_name = '".$_SESSION["domain"]."' order by local_part ASC");
  $popuserlst = '<select name="local_part" size="1" style="FONT-SIZE: 10px; COLOR: white; FONT-FAMILY: geneva, arial; BACKGROUND-COLOR: #61705B">';
    $popuserlst .= '<option value="">-&nbsp;-&nbsp;-&nbsp;-&nbsp;-&nbsp;-&nbsp;-&nbsp;-&nbsp;-</option>';
    while($row = db_fetch_array($result))
    {
        $popuserlst .= '<option value="'.$row["local_part"].'">'.$row["local_part"].'</option>';
    }
    
    $popuserlst .= '</select>';

    $result = db_query("select * from forwarder where hst = '".$_SESSION["hstdomain"]."' and domain_name = '".$_SESSION["domain"]."'  order by local_part ASC");
    $fwuserlst = '<select name="local_part" size="1" style="FONT-SIZE: 10px; COLOR: white; FONT-FAMILY: geneva, arial; BACKGROUND-COLOR: #61705B">';
    $fwuserlst .= '<option value="">-&nbsp;-&nbsp;-&nbsp;-&nbsp;-&nbsp;-&nbsp;-&nbsp;-&nbsp;-</option>';
    while($row = db_fetch_array($result))
    {
        $fwuserlst .= '<option value="'.$row['local_part'].'">'.$row['local_part'].' -> '.$row['remote_name'].'</option>';
    }
    $fwuserlst .= '</select>';
    $result = db_query("select * from domain where hst = '".$_SESSION["hstdomain"]."' and domain_name = '".$_SESSION["domain"]."'");
    $row = db_fetch_array($result);
    $domainaliaslst = '<input type="text" value="'.$row['alias'].'" name="alias" size="28" style="FONT-SIZE: 10px; COLOR: white; FONT-FAMILY: geneva, arial; BACKGROUND-COLOR: #61705B">';
?>

        <body bgcolor="#ffffff" background="images/gbg.jpg">
<table border="0" cellpadding="0" cellspacing="0" align="center">
  <tr height="40"> 
    <td valign="top" width="200" rowspan="2"> <?php include("bar.php");?> 
      <p>&nbsp;</p>
    </td>
    <td valign="top" height="26" colspan="2"><img src="images/titla.gif" border="0"> 
    </td>
  </tr>
  <tr> 
    <td valign="top" width="300" > 
      <table border="0" cellpadding="2" cellspacing="0" width="210">
        <tr> 
          <td background="images/b.gif"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="2"><b>&nbsp;Dom&iacute;nio:</b></font></td>
        </tr>
        <tr> 
          <td bgcolor="#61705b" valign="top"> 
            <form name="FormName" autocomplete="off" action="marcavmc.php" method="post">
              <p><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="1"><b>

	      <br>Trocar senha administrativa:<br>
                Senha &nbsp;&nbsp;&nbsp; 
                <input type="password" autocomplete="off" name="password" size="28" style="FONT-SIZE: 10px; COLOR: white; FONT-FAMILY: geneva, arial; BACKGROUND-COLOR: #61705B">
                <br>
                Repita &nbsp;&nbsp;&nbsp; 
                <input type="password" autocomplete="off" name="password2" size="28" style="FONT-SIZE: 10px; COLOR: white; FONT-FAMILY: geneva, arial; BACKGROUND-COLOR: #61705B">
                </b></font><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="1"><b> 
                <input type="image" src="images/alterar.gif" align="absbottom">
                <input type="hidden" value="changedomainpw" name="action">
                </b></font> 
		<br>
              <hr noshade size="2" color="black">
            </form>
            <form name="FormName" action="marcavmc.php" method="post" onSubmit="return areYouSure()">
              <font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="1"><b>
	      Email de domínio (padr&atilde;o) : <br>
	      Usu&aacute;rio&nbsp;&nbsp;&nbsp;</b></font><?php echo $domainaliaslst;?>
	      <br>
              <b>
                 <input type="image" src="images/alterar.gif" align="absbottom" name="image2">
              </b> 
              <input type="hidden" value="adddomainalias" name="action">
              <font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="1"><b> 
              </b></font> 
            </form>
          </td>
        </tr>
      </table>
      <br>
      <table border="0" cellpadding="2" cellspacing="0" width="210">
        <tr> 
          <td background="images/b.gif"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="2"><b>&nbsp;
	  Apelidos postais:</b></font></td>
        </tr>
        <tr height="131"> 
          <td bgcolor="#61705b" valign="top"> 
            <form autocomplete="off" name="FormName" action="marcavmc.php" method="post">
              <font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="1"><b><br>
	      Redirecionamentos de email: 
              <br>
              Apelido &nbsp;&nbsp;&nbsp;</b></font><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="1"><b> 
              </b></font> 
              <input autocomplete="off" type="text" name="local_part" size="28" style="FONT-SIZE: 10px; COLOR: white; FONT-FAMILY: geneva, arial; BACKGROUND-COLOR: #61705B">
              <br>
              <font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="1"><b>
	      Destino &nbsp;&nbsp;&nbsp;</b></font><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="1"><b>
	      <input autocomplete="off" type="text" name="remote_name" size="28" style="FONT-SIZE: 10px; COLOR: white; FONT-FAMILY: geneva, arial; BACKGROUND-COLOR: #61705B">
              </b>
	      <br> 
              <input type="image" src="images/adicionar.gif" align="absbottom" name="image4">
              <input type="hidden" value="addforwarder" name="action">
              </b></font> <font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="1"><b> 
              <hr noshade size="2" color="black">
              </b></font> 
            </form>
            <form name="FormName" action="marcavmc.php" method="post" onSubmit="return areYouSure()">
	      <font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="1"><b>
	      Exclusão de Redirecionamentos: <br>
              <font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="1"> 
              </font><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="1"><b>
	      <?php echo $fwuserlst;?><br>
              <input type="image" src="images/remover.gif" align="absbottom" name="image4">
              <input type="hidden" value="deleteforwarder" name="action" style="FONT-SIZE: 10px; COLOR: white; FONT-FAMILY: geneva, arial; BACKGROUND-COLOR: #61705B" checked>
              </b></font> 
            </form>
          </td>
        </tr>
      </table>
    </td>
    <td valign="top" width="300"> 
      <table border="0" cellpadding="2" cellspacing="0" width="210">
        <tr> 
          <td background="images/b.gif"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="2"><b>Caixas 
            postais:</b></font></td>
        </tr>
        <tr height="131"> 
          <td bgcolor="#61705b" valign="top"> 
            <form autocomplete="off" name="FormName" action="marcavmc.php" method="post">
              <div align="left"> 
                <p><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="1"><b>
		<br>Adicionar caixa postal:<br>
                  Usu&aacute;rio&nbsp;&nbsp; </b></font> 
                  <input type="text" autocomplete="off" name="local_part" size="28" style="FONT-SIZE: 10px; COLOR: white; FONT-FAMILY: geneva, arial; BACKGROUND-COLOR: #61705B">
                  <br>
                  <font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="1"><b>Senha&nbsp;&nbsp; 
                  &nbsp; 
                  <input type="password" autocomplete="off" name="password" size="28" style="FONT-SIZE: 10px; COLOR: white; FONT-FAMILY: geneva, arial; BACKGROUND-COLOR: #61705B">
                  <br>
                  <font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="1"><b>Repita 
                  &nbsp;&nbsp;&nbsp; 
                  <input type="password" autocomplete="off" name="password2" size="28" style="FONT-SIZE: 10px; COLOR: white; FONT-FAMILY: geneva, arial; BACKGROUND-COLOR: #61705B">
                  </b></font></b></font>
		  <font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="1"><b><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="1"><b> 
                  <input type="image" src="images/adicionar.gif" align="absbottom" name="image">
                  </b></font> 
                  <input type="hidden" value="addpop" name="action">
                  </b></font> 
                <hr noshade size="2" color="black">
              </div>
            </form>
            <form name="FormName" autocomplete="off" action="marcavmc.php" method="post">
              <font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="1"><b>
	      Trocar senha da caixa postal:<br>
              <?php echo $popuserlst_pwd;?><br>
              Senha:&nbsp;&nbsp; &nbsp; 
              <input type="password" autocomplete="off" name="password" size="28" style="FONT-SIZE: 10px; COLOR: white; FONT-FAMILY: geneva, arial; BACKGROUND-COLOR: #61705B">
              <br>
              Repita:&nbsp;&nbsp; &nbsp; 
              <input type="password" autocomplete="off" name="password2" size="28" style="FONT-SIZE: 10px; COLOR: white; FONT-FAMILY: geneva, arial; BACKGROUND-COLOR: #61705B">
              &nbsp; 
              <br><input type="image" src="images/alterar.gif" align="absbottom" name="image3">
              </b></font> 
              <input type="hidden" value="changepoppw" name="action">
              <font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="1"><b> 
              <hr noshade size="2" color="black">
              </b></font> 
            </form>
            <font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="1"><b></b></font><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="1"><b> 
            <form name="FormName" action="marcavmc.php" method="post" OnSubmit="return areYouSure()">
              <p><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="1"><b> 
	        Exclusão de caixa postal: <br>	    
                <?php echo $popuserlst;?><br>
                </b></font><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="1"><b> 
                <input type="image" src="images/remover.gif" align="absbottom">
                <font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="white" size="1"><b> 
                <input type="hidden" value="deletepop" name="action">
                </b></font></b></font></p>
            </form>
            </b></font></td>
        </tr>
      </table>
    </td>
  </tr>
</table>
        </body>
</html>
