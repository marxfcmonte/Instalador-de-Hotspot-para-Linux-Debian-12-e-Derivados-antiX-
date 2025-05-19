#!/bin/bash

apt-get install -y hostapd dnsmasq wireless-tools iw wvdial

service dnsmasq stop

sed -i 's#^DAEMON_CONF=.*#DAEMON_CONF=/etc/hostapd/hostapd.conf#' /etc/init.d/hostapd

echo "Verifique o nome da interface de rede Ethernet"

echo ""

ip addr | grep "th"

echo ""

echo "Se o nome da interface de rede Ethernet é eth0 aperte 
Enter para continuar, se não digite o nome da interface:"
read ethe

echo "Verifique o nome da interface de rede WiFi"

echo ""

ip addr | grep "lan"

echo ""

echo "Se o nome da interface de rede WiFi é wlan0 aperte 
Enter para continuar, se não digite o nome da interface:"
read wifi

echo "Nome da rede Wi-Fi (SSID):"
read rede

echo ""

echo "Senha da rede Wi-Fi:"
read senha

echo ""

if [ "$wifi" = "" ]; then
	wifi="wlan0"
	echo "O nome da interface de rede Wi-Fi (PADRÃO): $wifi"	
else
	echo "O nome da interface de rede substituída com sucesso!"
	echo "O nome da interface de rede Wi-Fi: $wifi"
fi

if [ "$ethe" = "" ]; then
	ethe="eth0"
	echo "O nome da interface de rede Ethernet (PADRÃO): $ethe"
else
	echo "O nome da interface de rede substituída com sucesso!"
	echo "O nome da interface de rede Etherne: $ethe"
fi


cat <<EOF > /etc/dnsmasq.conf
log-facility=/var/log/dnsmasq.log
interface=$wifi
dhcp-range=192.168.137.10,192.168.137.250,12h
dhcp-option=3,192.168.137.1
dhcp-option=6,192.168.137.1
log-queries
EOF

service dnsmasq start

service hostapd stop

ifconfig $wifi up
ifconfig $wifi 192.168.137.1/24

iptables -t nat -F
iptables -F 
iptables -t nat -A POSTROUTING -o $ethe -j MASQUERADE
iptables -A FORWARD -i $wifi -o $ethe -j ACCEPT
echo '1' > /proc/sys/net/ipv4/ip_forward

cat <<EOF > /etc/hostapd/hostapd.conf
interface=$wifi
driver=nl80211
channel=1

ssid=$rede
wpa=2
wpa_passphrase=$senha
wpa_key_mgmt=WPA-PSK
wpa_pairwise=CCMP
# Altera as chaves transmitidas/multidifundidas após esse número de segundos.
wpa_group_rekey=600
# Troca a chave mestra após esse número de segundos. A chave mestra é usada como base.
wpa_gmk_rekey=86400

EOF

if [ -d "/usr/share/Hotspot" ]; then
	echo "O diretório Hotspot existe e será deletado..."
	rm -rf /usr/share/Hotspot
	echo "O diretório Hotspot será criado..."
	mkdir /usr/share/Hotspot
else
	echo "O diretório Hotspot será criado..."
	mkdir /usr/share/Hotspot
fi

touch /usr/share/Hotspot/Start.sh

cat <<EOF > /usr/share/Hotspot/Start.sh
#!/bin/bash

service hostapd stop
service dnsmasq stop
sed -i 's#^DAEMON_CONF=.*#DAEMON_CONF=/etc/hostapd/hostapd.conf#' /etc/init.d/hostapd
ifconfig $wifi up
ifconfig $wifi 192.168.137.1/24
iptables -t nat -F
iptables -F 
iptables -t nat -A POSTROUTING -o $ethe -j MASQUERADE
iptables -A FORWARD -i $wifi -o $ethe -j ACCEPT
echo '1' > /proc/sys/net/ipv4/ip_forward
service hostapd start
service dnsmasq start
exit 0

EOF

touch /usr/share/Hotspot/RStar.sh

cat <<EOF > /usr/share/Hotspot/RStar.sh
#!/bin/bash

service hostapd stop
service dnsmasq stop
sed -i 's#^DAEMON_CONF=.*#DAEMON_CONF=/etc/hostapd/hostapd.conf#' /etc/init.d/hostapd
ifconfig $wifi up
ifconfig $wifi 192.168.137.1/24
iptables -t nat -F
iptables -F 
iptables -t nat -A POSTROUTING -o $ethe -j MASQUERADE
iptables -A FORWARD -i $wifi -o $ethe -j ACCEPT
echo '1' > /proc/sys/net/ipv4/ip_forward
service hostapd start
service dnsmasq start
echo 'Hotspot Reiniciado...' >&2
sleep 2
exit 0

EOF

touch /usr/share/Hotspot/Stop.sh

cat <<EOF > /usr/share/Hotspot/Stop.sh
#!/bin/bash

sudo service hostapd stop
sudo service dnsmasq stop

EOF

touch /usr/share/applications/RStar.desktop
touch /usr/share/applications/Stop.desktop

cat <<EOF > /usr/share/applications/RStar.desktop
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Name=Restart do Hotspot
Name[pt_BR]=Restart do Hotspot
Exec=roxterm -e "sudo bash -c /usr/share/Hotspot/RStar.sh"
Terminal=false
StartupNotify=true
Comment=Reinicia o hotspot
Comment[pt_BR]=Reinicia o hotspot
Keywords=hotspot;internet;network;
Keywords[pt_BR]=internet;network;hotspot;
Categories=Network;WebBrowser;
GenericName=Restart do Hotspot
GenericName[pt_BR]=Restart do Hotspot
Icon=/usr/share/pixmaps/network-assistant.png

EOF

cat <<EOF > /usr/share/applications/Stop.desktop
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Name=Finaliza o Hotspot
Name[pt_BR]=Finaliza o Hotspot
Exec=roxterm -e "sudo bash -c /usr/share/Hotspot/Stop.sh"
Terminal=false
StartupNotify=true
Comment=Finaliza o hotspot
Comment[pt_BR]=Finaliza o hotspot
Keywords=hotspot;internet;network;
Keywords[pt_BR]=internet;network;hotspot;
Categories=Network;WebBrowser;
GenericName=Restart do Hotspot
GenericName[pt_BR]=Restart do Hotspot
Icon=/usr/share/pixmaps/cross_red.png

EOF

chmod +x /usr/share/Hotspot/Start.sh

chmod +x /usr/share/Hotspot/RStar.sh

chmod +x /usr/share/Hotspot/Stop.sh

chmod +x /usr/share/applications/RStar.desktop

chmod +x /usr/share/applications/Stop.desktop

cat /var/spool/cron/crontabs/root | grep -q "@reboot sudo /usr/share/Hotspot/Start.sh"

if [ "$?" = "1" ]; then
	echo "As configurações no crontab serão atualizadas..." 
	echo "@reboot sudo /usr/share/Hotspot/Start.sh" >> /var/spool/cron/crontabs/root
else
	echo "As configurações no crontab estão atualizadas... "
fi

sleep 2

service hostapd start

exit 0
