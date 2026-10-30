###########################################################################
#     Feito por Silmar A. Marca      smarca@gmail.com                     #
###########################################################################
#  *  A remocao destas linhas implica na nao observacao da licenca GNU *  #
#  *  Informe o autor sobre falhas ou incremento de funcoes            *  #
#  *  Respeite a propriedade intelectual, http://www.gnu.org/          *  #
###########################################################################
# SOMENTE PARA MYSQL - mysql -p < estescript.sql
# Ver: select @@hostname;

CONNECT mysql;

REPLACE INTO user (host, user, password)
    VALUES (
        'localhost',
        'virtualmailmgr',
  -- IMPORTANT: Change this password!
        password('marcaisowner')
    );

REPLACE INTO db (host, db, user, select_priv, insert_priv, update_priv,
                 delete_priv, create_priv, drop_priv)
    VALUES (
        'localhost',
        'maildb',
        'virtualmailmgr',
        'Y', 'Y', 'Y', 'Y',
        'Y', 'Y'
    );

FLUSH PRIVILEGES;
#    password('virtualmailpass')
# --------------------------------------------------------
# 
# Banco de Dados : `maildb`
# 
CREATE DATABASE IF NOT EXISTS maildb;
CONNECT maildb;

# --------------------------------------------------------
# Permissões
#
#REVOKE ALL PRIVILEGES ON `maildb` . * FROM "virtualmailmgr"@"localhost";
#REVOKE GRANT OPTION ON `maildb` . * FROM "virtualmailmgr"@"localhost";
GRANT SELECT, INSERT, UPDATE, DELETE ON `maildb` . * TO "virtualmailmgr"@"localhost";

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Base de Dados: `maildb`
--
CREATE DATABASE IF NOT EXISTS `maildb` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
USE `maildb`;

-- --------------------------------------------------------

--
-- Estrutura da tabela `autorespond`
--

CREATE TABLE IF NOT EXISTS `autorespond` (
  `lastchange` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `hst` varchar(25) NOT NULL,
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `local_part` varchar(64) NOT NULL,
  `domain_name` varchar(253) NOT NULL,
  `target` mediumtext NOT NULL,
  `subject` varchar(255) NOT NULL DEFAULT '',
  `text` longtext NOT NULL,
  `autorespond` enum('no','yes') NOT NULL DEFAULT 'no',
  `beginDate` datetime DEFAULT NULL,
  `endDate` datetime DEFAULT NULL,
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estrutura da tabela `domain`
--

CREATE TABLE IF NOT EXISTS `domain` (
  `lastchange` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `hst` varchar(10) NOT NULL,
  `domain_name` varchar(128) NOT NULL DEFAULT '',
  `alias` varchar(64) DEFAULT NULL,
  `home` varchar(128) NOT NULL DEFAULT '/srv/mail/default/',
  `homewww` varchar(128) NOT NULL DEFAULT '/srv/www/home/metropol.com.br/',
  `uid` smallint(5) unsigned NOT NULL DEFAULT '8',
  `gid` smallint(5) unsigned NOT NULL DEFAULT '8',
  `password_hash` varchar(128) NOT NULL DEFAULT '',
  `password_md5` varchar(128) NOT NULL DEFAULT '',
  `password_clear` varchar(128) DEFAULT NULL,
  `max_popbox` int(11) NOT NULL DEFAULT '10',
  `max_alias` int(11) NOT NULL DEFAULT '10',
  `quotas` int(12) unsigned NOT NULL DEFAULT '10',
  `quotac` int(12) unsigned NOT NULL DEFAULT '500',
  `ativo` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `timepassch` timestamp NULL DEFAULT NULL,
  `mailadmin` varchar(64) DEFAULT NULL,
  `mailwebmaster` varchar(64) DEFAULT NULL,
  `comentario` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`domain_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 CHECKSUM=1 COMMENT='Dominios Virtuais';

-- --------------------------------------------------------

--
-- Estrutura da tabela `domainalias`
--

CREATE TABLE IF NOT EXISTS `domainalias` (
  `lastchange` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `hst` varchar(25) NOT NULL,
  `domain_name` varchar(128) NOT NULL DEFAULT '',
  `domain_alias` varchar(128) NOT NULL DEFAULT '',
  `ativo` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `comentario` varchar(64) DEFAULT NULL,
  UNIQUE KEY `domain_alias` (`domain_alias`),
  KEY `domain_name` (`domain_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 CHECKSUM=1 COMMENT='Apelidos de Dominios Virtuais';

-- --------------------------------------------------------

--
-- Estrutura da tabela `domainmx`
--

CREATE TABLE IF NOT EXISTS `domainmx` (
  `lastchange` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `hst` varchar(25) NOT NULL,
  `domain_name` varchar(128) NOT NULL DEFAULT '',
  `ativo` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `comentario` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`domain_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 CHECKSUM=1 COMMENT='Dominios permitidos para Relay';

-- --------------------------------------------------------

--
-- Estrutura da tabela `forwarder`
--

CREATE TABLE IF NOT EXISTS `forwarder` (
  `lastchange` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `hst` varchar(25) NOT NULL,
  `domain_name` varchar(128) NOT NULL DEFAULT '',
  `local_part` varchar(64) NOT NULL DEFAULT '',
  `remote_name` varchar(192) NOT NULL DEFAULT '',
  `copia` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `ativo` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `comentario` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`domain_name`,`local_part`,`remote_name`),
  UNIQUE KEY `email` (`local_part`,`domain_name`),
  UNIQUE KEY `local_part` (`local_part`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 CHECKSUM=1 COMMENT='Apelidos de Caixas Postais';

-- --------------------------------------------------------

--
-- Estrutura da tabela `gateway`
--

CREATE TABLE IF NOT EXISTS `gateway` (
  `lastchange` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `hst` varchar(25) NOT NULL,
  `domain_name` varchar(128) NOT NULL DEFAULT '',
  `domain_host` varchar(128) NOT NULL DEFAULT '',
  `ativo` tinyint(3) NOT NULL DEFAULT '1',
  `comentario` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`domain_name`,`domain_host`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 PACK_KEYS=0 CHECKSUM=1 COMMENT='Gateways de Transporte';

-- --------------------------------------------------------

--
-- Estrutura da tabela `greylist`
--

CREATE TABLE IF NOT EXISTS `greylist` (
  `lastchange` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `hst` varchar(25) NOT NULL,
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `relay_ip` varchar(20) DEFAULT NULL,
  `sender_type` enum('NORMAL','BOUNCE','MACHINE') NOT NULL DEFAULT 'NORMAL',
  `helo` varchar(150) DEFAULT NULL,
  `sender` varchar(150) DEFAULT NULL,
  `recipient` varchar(150) DEFAULT NULL,
  `block_expires` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `record_expires` datetime NOT NULL DEFAULT '9999-12-31 23:59:59',
  `create_time` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `TYPE` enum('AUTO','MANUAL') NOT NULL DEFAULT 'MANUAL',
  `passcount` bigint(20) NOT NULL DEFAULT '0',
  `last_pass` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `blockcount` bigint(20) NOT NULL DEFAULT '0',
  `last_block` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`id`),
  UNIQUE KEY `relay_graylist` (`relay_ip`,`sender`,`recipient`,`sender_type`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='GrayList ';

-- --------------------------------------------------------

--
-- Estrutura da tabela `popbox`
--

CREATE TABLE IF NOT EXISTS `popbox` (
  `lastchange` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `hst` varchar(25) NOT NULL,
  `local_part` varchar(64) NOT NULL DEFAULT '',
  `domain_name` varchar(128) NOT NULL DEFAULT '',
  `ativo` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `password_hash` varchar(128) NOT NULL DEFAULT '',
  `password_md5` varchar(128) NOT NULL DEFAULT '',
  `password_clean` varchar(128) DEFAULT NULL,
  `timepassch` timestamp NULL DEFAULT NULL,
  `quotas` int(12) unsigned NOT NULL DEFAULT '0',
  `quotac` int(12) unsigned NOT NULL DEFAULT '0',
  `comentario` varchar(64) DEFAULT NULL,
  UNIQUE KEY `email` (`local_part`,`domain_name`),
  KEY `local_part` (`local_part`),
  KEY `domain_name` (`domain_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 CHECKSUM=1 COMMENT='Caixas Postais dos Usuarios';

-- --------------------------------------------------------

--
-- Estrutura da tabela `whitelist`
--

CREATE TABLE IF NOT EXISTS `whitelist` (
  `lastchange` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `hst` varchar(25) NOT NULL,
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `int_type` enum('NORMAL','BOUNCE','MACHINE') NOT NULL DEFAULT 'NORMAL',
  `dom_int` varchar(150) DEFAULT NULL,
  `dom_ext` varchar(150) DEFAULT NULL,
  `int_expires` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `ext_expires` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `create_time` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `TYPE` enum('AUTO','MANUAL') NOT NULL DEFAULT 'MANUAL',
  `int_passcount` bigint(20) NOT NULL DEFAULT '0',
  `int_last_pass` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `ext_passcount` bigint(20) DEFAULT '0',
  `ext_last_pass` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`id`),
  UNIQUE KEY `relay_graylist` (`dom_int`,`dom_ext`,`int_type`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 COMMENT='WhiteList';

--
-- Constraints for dumped tables
--

--
-- Limitadores para a tabela `domainalias`
--
ALTER TABLE `domainalias`
  ADD CONSTRAINT `domainalias_ibfk_1` FOREIGN KEY (`domain_name`) REFERENCES `domain` (`domain_name`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limitadores para a tabela `forwarder`
--
ALTER TABLE `forwarder`
  ADD CONSTRAINT `forwarder_ibfk_1` FOREIGN KEY (`domain_name`) REFERENCES `domain` (`domain_name`) ON DELETE CASCADE ON UPDATE CASCADE;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
