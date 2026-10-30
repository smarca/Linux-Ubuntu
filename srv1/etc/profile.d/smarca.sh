#!/bin/bash

rm -f ~/.bashrc
rm -f ~/.profile
rm -f ~/send

if [ -z "$TERM" ]; then
    COLUMNS=`tput -T xterm cols`                #Numero de Colunas
    LINES=`tput -T xterm lines`                 #Numero de Linhas
else
    COLUMNS=`tput cols`                         #Numero de Colunas
    LINES=`tput   lines`                        #Numero de Linhas
fi
export COLUMNS LINES

alias mutt='mutt -f ~/Maildir/'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias grep='grep --color=auto'
alias l='ls -laF -h --color=auto'
alias la='ls -A'
alias ll='ls -alF'
alias ls='ls --color=auto'
alias t="less -S +GF $*"
alias tl="less +GF $*"
alias p="ps -eo pid,user,group,%mem,%cpu,args --sort user $*"
alias i='iptables -n -v -L'
alias a='ip -s -s neigh flush all > /dev/null ; sleep 5; arp | grep ether'
alias arp='arp | grep "incomplet" -i -v'
alias e='journalctl -xe'
alias s='echo systemctl'
# complete -F _systemctl s

#alias lext="find . -type f | perl -ne 'print $1 if m/\.([^.\/]+)$/' | sort | uniq -c | sort -n"

#alias mc='mc --nomouse -x'
#alias mcedit='mcedit --nomouse -x'

if [ $USER = "root" ]; then
    alias tm='less -S +GF /var/log/syslog'
    alias tmm='less -S +GF /var/log/exim4/mainlog'
    alias tmr='less -S +GF /var/log/exim4/rejectlog'
    alias tms='less -S +GF /var/log/secure'
    alias tmo='less -S +GF /var/log/mail.log'
    HISTCONTROL='ignorespace:ignoredups'
else
    PROMPT_COMMAND='RETRN_VAL=$?;logger -p local6.debug "$(id -un) [$$] ($RETRN_VAL) bashcmd: $(history 1)"'
    TMOUT=900
    HISTCONTROL='ignoredups'
fi

if [ -d ~/Maildir/ ]; then
   unset MAIL
   MAILDIR=~/Maildir/
fi

# update-alternatives --config editor
EDITOR=/usr/bin/mcedit


#-----------------------------------------------------------
# Byobu sessao UNICA
#export BYOBU_BACKEND="tmux"
#if [ "`whoami`" == "root" ]; then export LC_BYOBU=1; fi
#-----------------------------------------------------------
# Byobu sessao MULTIPLA
#if [ ! -z $PS1 -a "$-" == "himBH" -a -z "$TMUX" -a "`whoami`" == "root" ]; then
#    tmux new -s `whoami` 
#    tmux attach-session -t `whoami` 2> /dev/null 
#fi
