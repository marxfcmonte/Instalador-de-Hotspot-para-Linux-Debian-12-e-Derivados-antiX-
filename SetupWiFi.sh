#!/bin/bash
apt-get install -y hostapd dnsmasq wireless-tools iw wvdial

service dnsmasq stop

sed -i 's#^DAEMON_CONF=.*#DAEMON_CONF=/etc/hostapd/hostapd.conf#' /etc/init.d/hostapd

cat <<EOF > /etc/dnsmasq.conf
log-facility=/var/log/dnsmasq.log
interface=wlan0
dhcp-range=192.168.137.10,192.168.137.250,12h
dhcp-option=3,192.168.137.1
dhcp-option=6,192.168.137.1
log-queries
EOF

service dnsmasq start

service hostapd stop

ifconfig wlan0 up
ifconfig wlan0 192.168.137.1/24

iptables -t nat -F
iptables -F 
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT
echo '1' > /proc/sys/net/ipv4/ip_forward

cat <<EOF > /etc/hostapd/hostapd.conf
interface=wlan0
driver=nl80211
channel=1

ssid=MARX-MONTE-J1800
wpa=2
wpa_passphrase=marx8401
wpa_key_mgmt=WPA-PSK
wpa_pairwise=CCMP
# Change the broadcasted/multicasted keys after this many seconds.
wpa_group_rekey=600
# Change the master key after this many seconds. Master key is used as a basis
wpa_gmk_rekey=86400

EOF

service hostapd start

