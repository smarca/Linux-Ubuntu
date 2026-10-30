# Linux-Ubuntu — Suíte Completa para Servidor Corporativo Ubuntu (`srv1` & `srv2`)

> **Arquivo Completo para Implantação em Servidor Ubuntu**: Este repositório contém uma arquitetura corporativa completa, pronta para produção em servidores Linux/Ubuntu, integrando **Alta Disponibilidade (Redundância Ativa/Passiva)**, **Backup Automatizado Cruzado entre Servidores**, **Segurança de Perímetro Avançada**, **Firewall Empresarial com Controle de Aplicativos e Páginas Web**, e **Servidor de E-mail Gerenciável via Banco de Dados com Forte Proteção Anti-Spam e Imunidade a Vírus**.

---

## Destaques e Funcionalidades Avançadas

### 1. Redundância Total e Backup Cruzado entre Servidores (`srv1` ↔ `srv2`)
- **Alta Disponibilidade e Failover Automático (`etc/keepalived/`)**:
  - Monitoramento contínuo de links e rotas via VRRP (`keepalived.conf`) com scripts inteligentes de verificação de conectividade (`ping.sh`).
  - **IP Virtual (VIP) sempre online** e comutação automática de gateway padrão em segundos em caso de queda de link ou falha de hardware entre `srv1` e `srv2`.
- **Sincronização e Espelhamento Automatizado (`etc/jobmarca/`, `etc/rsync/`)**:
  - Rotinas de replicação contínua via `rsync` (`run.rsync1`) entre os servidores para caixas de e-mail (`/srv/mail/`), sistemas, programas e backups.
  - Verificação de integridade completa com *checksum* semanal e sincronismo incremental diário/noturno.
  - Backups automatizados de bancos de dados MySQL (`run.bkpbd`), páginas web (`run.bkpweb`), configurações de sistema (`run.bkpsys`), arquivos de boot (`run.bkpboot`) e sistemas (`run.bkpprog`), além de pacotes históricos em `bkp/`.
- **Redundância de Armazenamento (`etc/mdadm/`)**: Configuração de RAID via software para tolerância a falhas de disco.

---

### 2. Firewall Empresarial, Controle de Aplicativos, Páginas e QoS
- **Motor de Firewall Corporativo (`etc/firewall/iptables.sh`)**:
  - Script robusto (+2.400 linhas) com suporte a múltiplos links de Internet, balanceamento/failover de rotas, NAT dinâmico/estático e VPN (`ppp+`).
  - **Controle de Banda e Tráfego (QoS / HTB)**: Priorização inteligente de tráfego crítico (`qos.ini`) garantindo baixa latência para serviços essenciais.
  - **Controle de Acesso Granular (`etc/firewall/lst/`)**: Regras separadas por host, IPs dinâmicos, redirecionamentos de portas e controle por endereço físico (**Amarração IP × MAC** em `mac.ini` e `run.dhcpfix`), impedindo dispositivos não autorizados ou *IP spoofing* na rede local.
- **Filtro Web Empresarial e Controle de Aplicativos (`etc/squid/`)**:
  - **Proxy Squid Corporativo** integrado a descoberta automática de proxy via **WPAD** (`srv/www/default/proxy/wpad.dat`) e DNS.
  - **Bloqueio e Controle por Categorias (`etc/squid/lst/blk/` e `fre/`)**: Controle rigoroso de acesso a páginas e aplicativos de **Chat, Mensageiros, Jogos, Downloads, Arquivos Grandes, Webmails externos, Proxies Anônimos/Redirecionadores, Pornografia e Spyware**, além de controle por horário de expediente (`nowork`).

---

### 3. Forte Segurança e Blindagem de Sistema
- **Proteção Ativa Contra Ataques de Rede (`etc/firewall/configs.ini`)**:
  - Mitigação em tempo real contra **DDoS / SYN Flood / New Connection Flood / Smurf RST Flood** utilizando `hashlimit` dinâmico por IP de origem/destino.
  - **Port Knocking para SSH (`SSH_KNOCK`)**: Ocultação e proteção do acesso administrativo SSH exigindo sequência específica de portas antes da liberação.
  - **Filtro de Pacotes Forjados**: Proteção *Reverse Path Filtering*, bloqueio de pacotes *Martians*, validação de TTL mínimo e tratamento faseado de rejeições ICMP.
  - **Monitoramento ARP (`run.vrfarp`)**: Detecção de alterações indevidas de MAC/ARP na rede interna.
- **Prevenção de Intrusão e Auditoria**:
  - **Fail2Ban (`etc/fail2ban/`)**: Banimento automático de IPs com tentativas de força bruta em SSH, e-mail e web.
  - **AppArmor (`etc/apparmor.d/`)**: Confinamento de segurança para serviços críticos (`named`, `mysqld`, `dhcpd`).
  - **DShield (`etc/dshield/`)** e **Rsyslog (`etc/rsyslog.d/`)**: Auditoria centralizada de logs de segurança.

---

### 4. Servidor de E-mail Gerenciável via Banco de Dados, Anti-Spam e Imune a Vírus
- **Gerenciamento Completo via MySQL e Painel Web (`etc/exim4/exim4.conf`, `srv/www/default/painel/`)**:
  - Domínios, aliases de domínio, contas de usuários (`popbox`), redirecionamentos (`forwarder`), cópias ocultas automáticas, gateways de saída, UID/GID e **quotas de disco individuais** totalmente gerenciados em tempo real via banco de dados **MySQL**.
  - Interface administrativa web integrada (`srv/www/default/painel/`) para gerenciamento simplificado de contas e permissões, acompanhada de **Webmail Horde Groupware** completo (`srv/www/default/webmail/`) com filtros de regras (Ingo), agenda (Kronolith), contatos (Turba) e troca de senha (Passwd).
  - Servidor IMAP/POP3 **Dovecot (`etc/dovecot/`)** autenticado diretamente na base SQL com suporte a SSL/TLS e controle de quotas.
- **Forte Proteção Anti-Spam Multicamadas (`etc/exim4/`)**:
  - Validação estrita de **SPF (Sender Policy Framework)** nativa e via bibliotecas Perl (`usr/share/perl5/Mail/SPF/`).
  - Verificação de **DNSBL / RBL**, checagem de reverso (rDNS), validação de HELO/EHLO, *Callout Verification* de remetentes e *Greylisting* / atrasos táticos (SMTP Teergrube) contra *spambots*.
  - Listas brancas e negras granulares por IP, domínio, remetente e destinatário (`etc/exim4/lst/`).
  - Classificação de nível de spam (`X-Spam-Level`) integrada ao roteamento de entrega.
- **Imunidade a Vírus por E-mail**:
  - Bloqueio direto em nível de SMTP/MIME de anexos executáveis, scripts maliciosos e extensões perigosas antes mesmo da entrega na caixa postal.
  - Integração com varredura antivírus automatizada (`run.avirus`) garantindo caixas de entrada limpas e seguras para os usuários.

---

## Estrutura do Repositório

```text
├── bkp/                  # Backups históricos compactados (.rar) de srv1 e srv2
├── srv1/                 # Configuração completa do Servidor 1 (Primário)
│   ├── etc/              # Configurações de sistema, firewall, email, DNS, proxy e automação
│   ├── srv/              # Dados de serviços (Painel Web, Webmail Horde, Proxy WPAD, FTP, Samba)
│   └── usr/              # Módulos e bibliotecas compartilhadas (Apache2, Perl Mail::SPF)
└── srv2/                 # Configuração completa do Servidor 2 (Secundário / Failover)
    ├── etc/              # Configurações espelhadas e ajustadas para redundância
    ├── srv/              # Dados de serviços (Painel Web, Webmail Horde, Proxy WPAD, FTP, Samba)
    └── usr/              # Módulos e bibliotecas compartilhadas (Apache2, Perl Mail::SPF)
```

---

## Resumo dos Serviços Incluídos

| Categoria | Serviços / Tecnologias | Diretórios Principais |
| :--- | :--- | :--- |
| **Firewall & QoS** | IPTables, HTB/QoS, Port Knocking, Anti-DDoS, IP×MAC | `etc/firewall/` |
| **Alta Disponibilidade** | Keepalived (VRRP, VIP, Monitoramento de Links) | `etc/keepalived/` |
| **Proxy & Filtro Web** | Squid 3, WPAD Auto-Proxy, Listas de Bloqueio por Categoria | `etc/squid/`, `srv/www/default/proxy/` |
| **E-mail & Anti-Spam** | Exim4 + MySQL, Dovecot IMAP/POP3, SPF, Anti-Vírus | `etc/exim4/`, `etc/dovecot/` |
| **Webmail & Painel** | Horde Groupware, Painel Administrativo PHP/MySQL | `srv/www/default/webmail/`, `srv/www/default/painel/` |
| **DNS & DHCP** | BIND9 (Views Interna/Externa + DNS Block), ISC DHCP | `etc/bind/`, `etc/dhcp/` |
| **Backup & Sync** | Rsync Daemon, Scripts `jobmarca`, MDADM RAID | `etc/jobmarca/`, `etc/rsync/`, `etc/mdadm/` |
| **Arquivos & Rede** | Samba (SMB), ProFTPD, Apache 2, MySQL, phpMyAdmin | `etc/samba/`, `etc/proftpd/`, `etc/apache2/`, `etc/mysql/` |
| **Segurança & Logs** | Fail2Ban, AppArmor, DShield, Rsyslog, NTP | `etc/fail2ban/`, `etc/apparmor.d/`, `etc/rsyslog.d/` |

---

## Autor

**Silmar A. Marca**  
- E-mail: [smarca@gmail.com](mailto:smarca@gmail.com)
- GitHub: [@smarca](https://github.com/smarca)
