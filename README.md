# Linux-Ubuntu — Configurações de Servidores (`srv1` & `srv2`)

Repositório de versionamento e backup das configurações, scripts de automação, regras de firewall e serviços de rede dos servidores Linux/Ubuntu (`srv1` e `srv2`).

---

## Estrutura do Repositório

```text
├── bkp/                  # Arquivos compactados de backup histórico (.rar)
├── srv1/                 # Configurações do Servidor 1 (Primário)
│   ├── etc/              # Configurações de sistema, rede, segurança e serviços
│   ├── srv/              # Dados de serviços (FTP, Samba, Web/Painel/Webmail)
│   └── usr/              # Módulos e arquivos compartilhados (Apache2, Perl/SPF)
└── srv2/                 # Configurações do Servidor 2 (Secundário / Redundância)
    ├── etc/              # Configurações de sistema, rede, segurança e serviços
    ├── srv/              # Dados de serviços (FTP, Samba, Web/Painel/Webmail)
    └── usr/              # Módulos e arquivos compartilhados (Apache2, Perl/SPF)
```

---

## Principais Serviços e Componentes

### 1. Rede, Firewall e Alta Disponibilidade
- **Firewall & QoS (`etc/firewall/`)**: Script avançado em Bash (`iptables.sh`) com controle de rotas, NAT, redirecionamentos, controle de banda (QoS/HTB), amarração IP/MAC (`mac.ini`), múltiplas interfaces (`interfaces.ini`) e listas de controle de acesso (`lst/`).
- **Alta Disponibilidade (`etc/keepalived/`)**: Configuração de failover via VRRP (`keepalived.conf`) e scripts de monitoramento de conectividade (`ping.sh`) entre `srv1` e `srv2`.
- **DNS (`etc/bind/`)**: Servidor BIND9 configurado com visões/zonas internas e externas (`zones/master/`, `zones/localnet/`) e bloqueio de domínios (`zones/block/`).
- **DHCP (`etc/dhcp/`)**: Servidor ISC DHCP (`dhcpd.conf`) integrado ao controle de rede local.
- **Proxy Web (`etc/squid/`)**: Squid Proxy com autenticação, controle de acesso por listas (`lst/blk/`, `lst/fre/`, `lst/clt/`) e descoberta automática de proxy via WPAD (`srv/www/default/proxy/wpad.dat`).

### 2. E-mail e Mensageria
- **MTA (`etc/exim4/`)**: Servidor SMTP Exim4 com verificação SPF, listas brancas/negras (`lst/`), integração antivírus/antispam e roteamento customizado.
- **IMAP/POP3 (`etc/dovecot/`)**: Servidor Dovecot com suporte a quotas, ACLs e autenticação SQL/sistema.
- **Webmail (`srv/www/default/webmail/`)**: Suite Horde Groupware (IMP, Turba, Kronolith, Ingo, Gollem, Passwd).

### 3. Automação e Manutenção (`etc/jobmarca/` e `etc/cron.d/jobmarca`)
Conjunto de scripts administrativos automatizados para manutenção e sincronização:
- `run.bkpsys`, `run.bkpbd`, `run.bkpweb`, `run.bkpprog`, `run.bkpboot`: Rotinas de backup de sistema, banco de dados MySQL, páginas web e configurações.
- `run.rsync1`: Sincronização entre os servidores (`srv1` ↔ `srv2`).
- `run.vrfarp`, `run.vrfsys`, `run.vrfreboot`: Monitoramento de tabelas ARP, integridade de serviços e verificação de reinicialização.
- `run.dhcpfix`, `run.deltemp`, `run.avirus`: Limpeza de temporários, ajuste de concessões DHCP e varredura de segurança.

### 4. Outros Serviços Configurados
- **Web & Banco de Dados**: Apache 2 (`etc/apache2/`, VirtualHosts para painel administrativo, estatísticas, webmail, proxy/WPAD), MySQL (`etc/mysql/`) e phpMyAdmin (`etc/phpmyadmin/`).
- **Arquivos**: Samba/SMB (`etc/samba/`, `srv/smb/`), ProFTPD (`etc/proftpd/`, `srv/ftp/`) e Rsync (`etc/rsync/`).
- **Segurança & Auditoria**: Fail2Ban (`etc/fail2ban/`), AppArmor (`etc/apparmor.d/`), DShield (`etc/dshield/`), Rsyslog (`etc/rsyslog.d/`) e RAID via MDADM (`etc/mdadm/`).

---

## Autor

**Silmar A. Marca**  
- E-mail: [smarca@gmail.com](mailto:smarca@gmail.com)
- GitHub: [@smarca](https://github.com/smarca)
