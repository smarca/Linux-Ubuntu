#!/bin/bash

#SSH1 protocol
# For the SSH1 protocol you only require an RSA1 key:
ssh-keygen -f /etc/ssh/ssh_host_key -N '' -t rsa

#SSH2 protocol
#For the SSH2 protocol you need two keys, for rsa and dsa:
ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa