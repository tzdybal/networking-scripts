#!/usr/bin/env bash

COUNTRIES="ch no"

echo "===> Resetting firewall"
sudo ufw reset
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default deny outgoing

echo "===> Setting up DNS"
echo nameserver 1.1.1.1 | cat - /etc/resolv.conf > /tmp/resolv.conf
sudo mv /tmp/resolv.conf /etc/resolv.conf
sudo ufw allow out on wlp2s0 to 1.1.1.1 comment 'Cloud Flare DNS'

echo "===> Enabling NordVPN servers from: $COUNTRIES"
for COUNTRY in $COUNTRIES; do
	echo "==> $COUNTRY"
	SERVERS=`sudo nordvpn list $COUNTRY* | sort | uniq`
	for SERVER in $SERVERS; do
		IP=`host $SERVER.nordvpn.com | grep has | cut -d" " -f4`
		if [ -n "$IP" ]; then
			echo "=> $SERVER ($IP)"
			sudo ufw allow out on wlp2s0 to $IP comment "$SERVER.nordvpn.com" > /dev/null 2>&1
		fi
	done
done

echo "===> Enabling traffic on tun0"
sudo ufw allow out on tun0
