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

if (!isset($_SESSION["domain"]))
 {
 	include("index.php");
 	exit;
 }
/*
menu.php
top menu bar include
*/
$pop_stats = get_rem_popboxes();                        
?> 
<p>&nbsp;</p><p><br>
</p><table width="90%" border="0">
  <tr> 
    <td width="100%" colspan="2"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="3"><b><font size="2">
    <?php echo $_SESSION["domain"];?> (<?php echo $_SESSION["hstdomain"];?>):</font></b></font></td>
  </tr>
  <tr> 
    <td width="40%"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="3"><b><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="1">Limite cx:</font></b></font></td>
    <td width="60%><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="3"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="2"><?=round($pop_stats['quotas'],2);?> MB</font><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="2"> 
      </font></font></td>
  </tr>
  <tr>
    <td width="40%"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="3"><b><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="1">Limite msg:</font></b></font></td>
    <td width="60%><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="3"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="2"><?=$pop_stats['quotac']?></font><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="2"> 
      </font></font></td>
  </tr>
</table>
<br>
<table width="90%" border="0">

  <tr> 
    <td width="100%" colspan="2"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="3"><b><font size="2">Caixas 
      Postais:</font></b></font></td>
  </tr>
  <tr> 
    <td width="19%"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="3"><b><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="1">Total:</font></b></font></td>
    <td width="81%"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="3"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="2"><?=$pop_stats['total'];?></font><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="2"> 
      </font></font></td>
  </tr>
  <tr> 
    <td width="19%"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="3"><b><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="1">Usadas:</font></b></font></td>
    <td width="81%"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="3"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="2"><?=$pop_stats['used'];?> 
      </font></font></td>
  </tr>
  <tr> 
    <td width="19%"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="3"><b><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="3"><b><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="1">Dispon&iacute;veis:</font></b></font><font size="2"></font></b></font></td>
    <td width="81%"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="3"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="2"><?=$pop_stats['available'];?> 
      </font></font></td>
  </tr>
</table>
<br>
<table width="90%" border="0">
  <tr> 
    <td width="100%" colspan="2"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="3"><b><font size="2">Apelidos 
      Postais:</font></b></font></td>
  </tr>
  <tr> 
    <td width="19%"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="3"><b><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="1">Total:</font></b></font></td>
    <td width="81%"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="3"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="2"><?=$pop_stats['atotal'];?></font><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="2"> 
      </font></font></td>
  </tr>
  <tr> 
    <td width="19%"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="3"><b><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="1">Usados:</font></b></font></td>
    <td width="81%"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="3"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="2"><?=$pop_stats['aused'];?> 
      </font></font></td>
  </tr>
  <tr> 
    <td width="19%"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="3"><b><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="3"><b><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="1">Dispon&iacute;veis:</font></b></font><font size="2"></font></b></font></td>
    <td width="81%"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="3"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="2"><?=$pop_stats['aavailable'];?> 
      </font></font></td>
  </tr>
</table>
<p align="center"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="3"><b><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="1"><a href="index.php?action=logout">Efetuar 
  Logout</a></font></b> <br>
  </font><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="3"><font face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular" color="black" size="1"><bInfo:><br>
  <?php echo $actioninfo;?> </font></font></p>
