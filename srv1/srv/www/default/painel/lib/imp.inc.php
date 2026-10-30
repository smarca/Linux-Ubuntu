<?php
         //-------------Parte IMP
         $mysqli_xconnect = @mysqli_connect($wwwdbhost, $wwwuser, $wwwpass) or die (mysqli_error());
         mysqli_select_db($wwwdbname,$mysqli_xconnect) or die (mysqli_error());
         if (empty($domain_name)) {
	    $uuid = $local_part;
	 } else {
             $uuid = $local_part."@".$domain_name;
	 }
         $result = mysqli_query("DELETE FROM horde_prefs where pref_uid = '".$uuid."'");
         $result = mysqli_query("DELETE FROM kronolith_events where calendar_id = '".$uuid."'");
         $result = mysqli_query("DELETE FROM mnemo_memos where memo_owner = '".$uuid."'");
         $result = mysqli_query("DELETE FROM nag_tasks where task_owner = '".$uuid."'");
         $result = mysqli_query("DELETE FROM turba_objects where owner_id = '".$uuid."'");
         //Fim IMP
?>
