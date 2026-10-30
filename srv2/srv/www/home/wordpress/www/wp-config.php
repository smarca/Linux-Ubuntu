<?php
/** 
 * As configurações básicas do WordPress.
 *
 * Esse arquivo contém as seguintes configurações: configurações de MySQL, Prefixo de Tabelas,
 * Chaves secretas, Idioma do WordPress, e ABSPATH. Você pode encontrar mais informações
 * visitando {@link http://codex.wordpress.org/Editing_wp-config.php Editing
 * wp-config.php} Codex page. Você pode obter as configurações de MySQL de seu servidor de hospedagem.
 *
 * Esse arquivo é usado pelo script ed criação wp-config.php durante a
 * instalação. Você não precisa usar o site, você pode apenas salvar esse arquivo
 * como "wp-config.php" e preencher os valores.
 *
 * @package WordPress
 */

// ** Configurações do MySQL - Você pode pegar essas informações com o serviço de hospedagem ** //
/** O nome do banco de dados do WordPress */
define('WP_ALLOW_MULTISITE', true );
define('WP_SITEURL', 'http://' . $_SERVER['HTTP_HOST']);
define('WP_HOME', 'http://' . $_SERVER['HTTP_HOST']); 
define('MULTISITE', true);
define('SUBDOMAIN_INSTALL', true);
define('DOMAIN_CURRENT_SITE',  $_SERVER['HTTP_HOST']);
define('PATH_CURRENT_SITE', '/');
define('SITE_ID_CURRENT_SITE', 1); 
define('BLOG_ID_CURRENT_SITE', 1); 

define('DB_NAME', 'wordpress');

/** Usuário do banco de dados MySQL */
define('DB_USER', 'wordpress');

/** Senha do banco de dados MySQL */
define('DB_PASSWORD', 'v8eRRujPtsEqN3Pq');

/** nome do host do MySQL */
define('DB_HOST', 'localhost');

/** Conjunto de caracteres do banco de dados a ser usado na criação das tabelas. */
define('DB_CHARSET', 'utf8');

/** O tipo de collate do banco de dados. Não altere isso se tiver dúvidas. */
define('DB_COLLATE', '');

/**#@+
 * Chaves únicas de autenticação e salts.
 *
 * Altere cada chave para um frase única!
 * Você pode gerá-las usando o {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * Você pode alterá-las a qualquer momento para desvalidar quaisquer cookies existentes. Isto irá forçar todos os usuários a fazerem login novamente.
 *
 * @since 2.6.0
 */
define('AUTH_KEY',         '~3|Zi#2OX2kM1e!Fr187,8[!uX@=%4Rrs?EGE^P?~r+d +zUD-)Q_`PB`&L{5*KS');
define('SECURE_AUTH_KEY',  'z`+;8^Wj#u)s!FBw8ajHm#l^D]Ej``<eaUo9?Z! Jmo`L~^rm]M3<F2s-Io=$oWe');
define('LOGGED_IN_KEY',    '~f1KNpFr*9%pn]A1(]I<B)asa-5M-~.dEA4[o[UjC|9+ujQ#wG|QJSb<ei|P1@1 ');
define('NONCE_KEY',        'I*#u$@A53TYN(a]-D)8#y$IEGIY uJ>FF=pTh2NrnB4o5$VgQ}Vk{A%gsBCwJu_Z');
define('AUTH_SALT',        'r@mdp[XN*~ws9 &ZJ`lTE5-e%9P,_!DeN?K& YV,`eZafZb;||;hOTFe;8d|4m=c');
define('SECURE_AUTH_SALT', 'ICYx$1|+#{L=.-yJJGXfl BZK|qK|K~R.czu)ca7-X^ESeb6@MV}.<CZwRxYi/7]');
define('LOGGED_IN_SALT',   '`pvMB16deht7:kz{z~<8dKNk-BU;hUw~wb4zqn#Cok$e8^m3.vN1(-a)a2f[Bq>f');
define('NONCE_SALT',       '2P.Jcsn:7]zRcxc aH$(/Tkw-UjKBElt*. ,P(013n~0)V7.Y8g_k|7|Ah0_se !');

/**#@-*/

/**
 * Prefixo da tabela do banco de dados do WordPress.
 *
 * Você pode ter várias instalações em um único banco de dados se você der para cada um um único
 * prefixo. Somente números, letras e sublinhados!
 */
$table_prefix  = 'wp_';

/**
 * O idioma localizado do WordPress é o inglês por padrão.
 *
 * Altere esta definição para localizar o WordPress. Um arquivo MO correspondente ao
 * idioma escolhido deve ser instalado em wp-content/languages. Por exemplo, instale
 * pt_BR.mo em wp-content/languages e altere WPLANG para 'pt_BR' para habilitar o suporte
 * ao português do Brasil.
 */
define('WPLANG', 'pt_BR');

/**
 * Para desenvolvedores: Modo debugging WordPress.
 *
 * altere isto para true para ativar a exibição de avisos durante o desenvolvimento.
 * é altamente recomendável que os desenvolvedores de plugins e temas usem o WP_DEBUG
 * em seus ambientes de desenvolvimento.
 */
define('WP_DEBUG', true);

/* Isto é tudo, pode parar de editar! :) */

/** Caminho absoluto para o diretório WordPress. */
if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) . '/');
	
/** Configura as variáveis do WordPress e arquivos inclusos. */
require_once(ABSPATH . 'wp-settings.php');
