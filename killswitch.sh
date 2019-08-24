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
sudo ufw allow out on wlp2s0 to 1.1.1.1 comment 'Cloud Flare DNS'
sudo ufw allow out on tun0 to 1.1.1.1 comment 'Cloud Flare DNS'

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
