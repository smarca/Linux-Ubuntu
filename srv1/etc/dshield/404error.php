<?php
/*
 * SANS ISC 404Project v2
 *
 * http://isc.sans.edu/tools/404project.html
 *
 * Purpose: Collect 404 Page Not Found to compile
 *          list for potential crawler trends
 *
 * Instructions: Enter the following from https://isc.sans.edu/myinfo.html
 *                for the variables below
 *     $sMyUserID - in right-column under "Logged in as:"
 *     $sMyKey - in section https://isc.sans.edu/myinfo.html#report 
 *               labeled "Your Authentication Key:"
 *
 * Updates: 
 *   v1 - Initial Release
 *   v2 - add IP Mask (2012-07-26)
 */


# you shouldset thetime zone in php.ini. but if not, use this linefor php5
# date_default_timezone_set('UCT');  
 
$showError=0; #1=show, 0=hide
# the user id is usually a number, like 1234567
$sMyUserID='73366232';
$sMyKey='c7nsQ9dl2fQlWFh/O/+o4w==';

/*
 * Privacy note: REQUEST_URI will incldue the query string. If you do not
 *  feel comfortable with this, replace it with REDIRECT_URL
 */

$sURL=$_SERVER['REQUEST_URI']; # for more privacy, replace this with 'REDIRECT_URL' 



$sIP=$_SERVER['REMOTE_ADDR'];
$sUA=$_SERVER['HTTP_USER_AGENT'];

/* RECOMMENDED: Change the URL to HTTPS. But first test if curl deals 
 *               with https correctly
 */
$sSubmitSite='http://isc.sans.edu/';

/* Set IP Mask
 *   Default = 0xffffffff/32
 *   Can be set to any level combination 
 *    such as 0xffffff00/24 or 0xffff0000/16 or 0xff000000/8 
 *    or mix it up a little with 0x00ffffff
 */
$sIPMask = "0xffffffff";


/*
 * Applies IP Mask
 */
$sIP = long2ip(ip2long($sIP) & hexdec($sIPMask));

/*
 *  This code will limit submissions to one per minute. 
 *  It can prevent some DoS conditions. (thx Swa for pointing this out)
 *  requires a temporary file to use for locking.
 *  Feel free to change the file name.
 *  (yup. I could use shared memory / semaophores but they are not always
 *   enabled)
 */

$sLockFile=sys_get_temp_dir().'/404project.lock';
if ( file_exists($sLockFile )) {
  if ( time()-filemtime($sLockFile)<60 ) { 
     exit();
  } 
}
$fp=fopen($sLockFile,'w');
fwrite($fp,time()."\n");
fclose($fp);

$sSubmitURL="weblogs/404project.html?id=$sMyUserID&version=2";
$sData=$sMyUserID.chr(0).$sMyKey.chr(0).$sURL.chr(0).$sIP.chr(0).$sUA.chr(0).date('Y-m-d').chr(0).date('H:i:s').chr(0).$sIPMask;
$sData='DATA='.base64_encode($sData);

if( $sURL != "" ){
  $ch=curl_init($sSubmitSite.$sSubmitURL);
  curl_setopt($ch,CURLOPT_RETURNTRANSFER,1);
  curl_setopt($ch,CURLOPT_POST,1);
  curl_setopt($ch,CURLOPT_POSTFIELDS,$sData);
  $output=curl_exec($ch);
  if ( curl_errno($ch)!=0 ) {
    error_log("404 Project CURL Error ".curl_errno($ch)." ".curl_error($ch));
  }
  curl_close($ch);
}
?>
