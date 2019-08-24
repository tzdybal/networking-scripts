#!/usr/bin/env bash

REFRESH=0
LOCAL=""
if [ "$1" = "refresh" ]; then
	REFRESH=1
fi

if [ $REFRESH -eq 0 ]; then
	echo "===> Stopping VPN and applying killswitch"
	sudo nordvpn stop
	killswitch.sh $LOCAL
fi

echo "===> Looking for best VPN server..."
BEST=`sudo nordvpn rank ch* | head -n 1 | cut -f1`

echo "===> Connecting to $BEST"
sudo nordvpn start $BEST

echo "===> Addind 1.1.1.1 to /etc/resolv.conf"
echo nameserver 1.1.1.1 | cat - /etc/resolv.conf > /tmp/resolv.conf
sudo mv /tmp/resolv.conf /etc/resolv.conf

echo "===> Ping and DNS test..."
ping -c 4 1.1.1.1
ping -c 4 google.com
