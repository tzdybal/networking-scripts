#!/usr/bin/env bash

add_server() {
	declare -a INPUT
	read -e -a INPUT
	if [ ${#INPUT[@]} -eq 2 ]; then
		SERVER=${INPUT[0]}
		IP=${INPUT[1]}
		echo "=> $SERVER ($IP)"
		sudo ufw allow out on wlp2s0 to $IP comment "$SERVER.nordvpn.com" > /dev/null 2>&1
	fi
}

COUNTRIES="ch no"
COUNTRIES="ch"

echo "===> Removing all nordvpn.com related firewall rules"
RULES=`sudo ufw status numbered | grep nordvpn.com | sed -e 's/\[\(.*\)\].*/\1/'`
for RULE in $RULES; do
	sudo ufw --force delete $RULE > /dev/null 2>&1
done

echo "===> Turning on firewall and disabling all traffic"
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default deny outgoing

echo "===> Setting up DNS"
echo nameserver 1.1.1.1 | cat - /etc/resolv.conf > /tmp/resolv.conf
sudo mv /tmp/resolv.conf /etc/resolv.conf
for NS in `cat /etc/resolv.conf | awk '/nameserver/{print $2}'`; do
	sudo ufw allow out on wlp2s0 to $NS comment 'DNS from /etc/resolv.conf (rule for nordvpn.com killswitch)'
	sudo ufw allow out on tun0 to $NS comment 'DNS from /etc/resolv.conf (rule for nordvpn.com killswitch)'
done

echo "===> Enabling NordVPN servers from: $COUNTRIES"
PIDS=()
PIDN=0
for COUNTRY in $COUNTRIES; do
	echo "==> $COUNTRY"
	SERVERS=`sudo nordvpn list $COUNTRY* | sort | uniq`
	for SERVER in $SERVERS; do
		host $SERVER.nordvpn.com | grep has | cut -d" " -f1,4 | add_server &
		PIDS[$PIDN]=$!
		PIDN=$((PIDN+1))
	done
done

for PID in ${PIDS[*]}; do
	wait $PID
done

echo "===> Enabling traffic on tun0"
sudo ufw allow out on tun0

if [ "$1" = "local" ]; then
	echo "===> Enabling traffic on local network"
	# TODO: get localhost address/mask
	LAN=`ip -f inet -br addr show | awk '/UP/{print $3}'`
	sudo ufw allow out on wlp2s0 to $LAN comment "Home network access (rule for nordvpn.com killswitch)"
fi
