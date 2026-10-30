<?php
//https://technet.microsoft.com/en-us/library/cc511507.aspx#AutodiscoverXMLSchema
//get raw POST data so we can extract the email address
$data = file_get_contents("php://input");
//if (empty($data)) { header($_SERVER["SERVER_PROTOCOL"]." 404 Not Found"); echo $_SERVER["REMOTE_ADDR"]; die; }

if (! empty($data) ) {
    //Variaveis iniciais
    preg_match("/\<EMailAddress\>(.*?)\<\/EMailAddress\>/", $data, $matches);

    //Separacao da configuracao
    $email = $matches[1];
    $user = substr(strrchr($email, "@"), 0);
    $domain = substr(strrchr($email, "@"), 1);
    $srvaddr = $domain;
}

if (empty($domain)) {
    $domain = "monital.com.br";
    $email = "email@monital.com.br";
    $user = "email";
    //Fixar dominio devido ao certificado SSL
    $srvaddr = "monital.com.br";
}

//file_put_contents("/tmp/autodiscover-" . $email . "-" . $_SERVER['REMOTE_ADDR'], $data);

//set Content-Type
header("Content-Type: application/xml");
?>
<?php echo '<?xml version="1.0" encoding="utf-8" ?'; ?>>
    <Autodiscover xmlns="http://schemas.microsoft.com/exchange/autodiscover/responseschema/2006">
    <Response xmlns="http://schemas.microsoft.com/exchange/autodiscover/outlook/responseschema/2006a">
    <User>
        <DisplayName><?php echo $email; ?></DisplayName>
    </User>
    <Account>
	<AccountType>email</AccountType>
	<Action>settings</Action>
	<!-- SMTP SEGURO AUTH -->
	<Protocol>
	    <Type>SMTP</Type>
	    <Server>smtp.<?php echo $srvaddr; ?></Server>
	    <Port>465</Port>
	    <LoginName><?php echo $email; ?></LoginName>
	    <DomainRequired>off</DomainRequired>
            <DomainName><?php echo $domain; ?></DomainName>
	    <SPA>off</SPA>
	    <SSL>on</SSL>
	    <AuthRequired>on</AuthRequired>
	    <UsePOPAuth>on</UsePOPAuth>
	    <UseIMAPAuth>on</UseIMAPAuth>
	    <SMTPLast>off</SMTPLast>
	</Protocol>
	<!-- SMTP COMUM AUTH -->
	<Protocol>
	    <Type>SMTP</Type>
	    <Server>smtp.<?php echo $srvaddr; ?></Server>
	    <Port>587</Port>
	    <LoginName><?php echo $email; ?></LoginName>
	    <DomainRequired>off</DomainRequired>
            <DomainName><?php echo $domain; ?></DomainName>
	    <SPA>off</SPA>
	    <SSL>off</SSL>
	    <AuthRequired>on</AuthRequired>
	    <UsePOPAuth>on</UsePOPAuth>
	    <UseIMAPAuth>on</UseIMAPAuth>
	    <SMTPLast>off</SMTPLast>
	</Protocol>
	<!-- IMAP SEGURO -->
	<Protocol>
	    <Type>IMAP</Type>
	    <Server>imap.<?php echo $srvaddr; ?></Server>
	    <Port>993</Port>
	    <LoginName><?php echo $email; ?></LoginName>
	    <DomainRequired>off</DomainRequired>
            <DomainName><?php echo $domain; ?></DomainName>
	    <SPA>off</SPA>
	    <SSL>on</SSL>
	    <AuthRequired>on</AuthRequired>
	</Protocol>
	<!-- IMAP COMUM -->
	<Protocol>
	    <Type>IMAP</Type>
	    <Server>imap.<?php echo $srvaddr; ?></Server>
	    <Port>143</Port>
	    <LoginName><?php echo $email; ?></LoginName>
	    <DomainRequired>off</DomainRequired>
            <DomainName><?php echo $domain; ?></DomainName>
	    <SPA>off</SPA>
	    <SSL>off</SSL>
	    <AuthRequired>on</AuthRequired>
	</Protocol>
	<!-- POP3 SEGURO -->
	<Protocol>
	    <Type>POP3</Type>
	    <Server>pop3.<?php echo $srvaddr; ?></Server>
	    <Port>995</Port>
	    <LoginName><?php echo $email; ?></LoginName>
	    <DomainRequired>off</DomainRequired>
            <DomainName><?php echo $domain; ?></DomainName>
	    <SPA>off</SPA>
	    <SSL>on</SSL>
	    <AuthRequired>on</AuthRequired>
	    <DomainRequired>off</DomainRequired>
	</Protocol>
	<!-- POP3 INSEGURO -->
	<Protocol>
	    <Type>POP3</Type>
	    <Server>pop3.<?php echo $srvaddr; ?></Server>
	    <Port>110</Port>
	    <LoginName><?php echo $email; ?></LoginName>
	    <DomainRequired>off</DomainRequired>
            <DomainName><?php echo $domain; ?></DomainName>
	    <SPA>off</SPA>
	    <SSL>off</SSL>
	    <AuthRequired>on</AuthRequired>
	    <DomainRequired>off</DomainRequired>
	</Protocol>
    </Account>
    </Response>
</Autodiscover>
