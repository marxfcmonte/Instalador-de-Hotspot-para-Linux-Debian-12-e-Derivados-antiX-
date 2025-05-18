#!/bin/bash
# wlan0 - Depende como é identificado o dispositivo WiFi pelo Linux.
# eth0 - Depende como é identificado o dispositivo Ethernet pelo Linux.
# Para saber digite no terminal o comando: ifconfig
# Caso sejam diferentes: altere.

service hostapd stop
service dnsmasq stop
sed -i 's#^DAEMON_CONF=.*#DAEMON_CONF=/etc/hostapd/hostapd.conf#' /etc/init.d/hostapd
ifconfig wlan0 up
ifconfig wlan0 192.168.137.1/24
iptables -t nat -F
iptables -F 
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT
echo '1' > /proc/sys/net/ipv4/ip_forward
service hostapd start
service dnsmasq start
exit 0
