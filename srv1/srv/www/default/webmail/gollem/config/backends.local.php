<?

$backends['ftp']['disabled'] = true;

$backends['srv1'] = array();
$backends['srv1'] = $backends['smb'];
$backends['srv1']['disabled'] = false;
$backends['srv1']['name'] = 'TEMP - Servidor 1';
$backends['srv1']['params']['hostspec'] = '10.0.0.1';
$backends['srv1']['params']['share'] = 'temp';

$backends['srv2'] = array();
$backends['srv2'] = $backends['smb'];
$backends['srv2']['preferred'] = true;
$backends['srv2']['disabled'] = false;
$backends['srv2']['name'] = 'TEMP - Servidor 2';
$backends['srv2']['params']['hostspec'] = '10.0.0.2';
$backends['srv2']['params']['share'] = 'temp';
