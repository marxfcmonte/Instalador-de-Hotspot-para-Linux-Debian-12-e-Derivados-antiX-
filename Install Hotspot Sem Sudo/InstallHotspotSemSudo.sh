#!/bin/bash

texto="Para a Distribuição Debian 12 e derivados (antiX 23)"
cont="$[${#texto} + 4]"
dialog --title "Desenvolvedor" --infobox "Desenvolvido por Marx F. C. Monte\n
Instalador de Hotspot v 1.8 (2025)\n
Para a Distribuição Debian 12 e derivados (antiX 23)" 5 $cont
sleep 3
clear
conexoes=$(ifconfig -a | grep broadcast -c)
if [ "$conexoes" -lt 2 ]; then
	texto="Deve haver pelo menos 2 interfaces ativas (Ethernet e Wi-Fi)..."
	cont="$[${#texto} + 4]"
	dialog --title "ERRO" --infobox "$texto\nInstalação finalizada." 4 $cont
	sleep 3
	clear
	exit 1
fi
texto="SETAS PARA ESCOLHER E ENTER PARA CONFIRMAR"
cont="$[${#texto} + 4]"
opcao=$(dialog --title "MENU" --menu "$texto" 10 $cont 3 \
"1" "PARA INSTALAR" \
"2" "PARA REMOVER" \
"3" "PARA SAIR" \
--stdout)
clear
case $opcao in
	1)
	texto="Instalação sendo iniciada..."
	cont="$[${#texto} + 4]"
	dialog --infobox "$texto" 3 $cont
	interfaces=($(ifconfig -a | grep BROADCAST | cut -d ":" -f1))
	ethe=${interfaces[0]}
	wifi=${interfaces[1]}
	sleep 5
	texto="Nome da rede Wi-Fi (SSID)"
	cont="$[${#texto} + 4]"
	# Coloque '$cont' no lugar de '35' para ajuste automático de largura
	rede=$(dialog --inputbox "$texto" 10 35 --stdout)
	texto="Senha da rede Wi-Fi"
	cont="$[${#texto} + 4]"
	# Coloque '$cont' no lugar de '35' para ajuste automático de largura
	senha=$(dialog --inputbox "$texto" 10 35 --stdout)
	clear
	if [ -z "$rede" -o -z "$senha" ]; then
		texto="Nome da rede Wi-Fi (SSID) ou Senha da rede Wi-Fi não informados."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
		exit 1
	fi
	if [ -e "/usr/share/Hotspot/install.conf" ]; then
		texto="A instalação dos pacotes não será necessária..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
	else
		apt update && apt upgrade -y
		apt install -y hostapd dnsmasq wireless-tools iw tlp
	fi
	if [ -d "/usr/share/Hotspot" ]; then
		texto="O diretório Hotspot existe..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
	else
		texto="O diretório Hotspot será criado..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
		mkdir /usr/share/Hotspot
	fi
	if [ -e "/usr/share/Hotspot/install.conf" ]; then
		texto="O arquivo install.conf existe..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
	else
		texto="O arquivo install.conf será criado..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
		echo "Pacotes instalados hostapd dnsmasq\
		 wireless-tools iw tlp." >\
		/usr/share/Hotspot/install.conf
	fi

	service dnsmasq stop

	sed -i 's#^DAEMON_CONF=.*#DAEMON_CONF=/etc/hostapd/hostapd.conf#' /etc/init.d/hostapd

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
	chown $SUDO_USER:$SUDO_USER /etc/hostapd/hostapd.conf

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
	if [ -d "/usr/share/pixmaps/hotspot" ]; then
		texto="O diretório para os icones existe..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
	else
		texto="O diretório para os icones será criado..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
		mkdir /usr/share/pixmaps/hotspot
		cat <<EOF > /usr/share/Hotspot/hotspot_icones
https://raw.githubusercontent.com/marxfcmonte/Instalador-de-Hotspot-\
para-Linux-Debian-12-e-Derivados-antiX-/refs/heads/main/Icones/\
connection.png
https://raw.githubusercontent.com/marxfcmonte/Instalador-de-Hotspot-\
para-Linux-Debian-12-e-Derivados-antiX-/refs/heads/main/Icones/\
hotspot.png
https://raw.githubusercontent.com/marxfcmonte/Instalador-de-Hotspot-\
para-Linux-Debian-12-e-Derivados-antiX-/refs/heads/main/Icones/\
hotspot2.png
EOF
		wget -i /usr/share/Hotspot/hotspot_icones -P /tmp/
		mv /tmp/connection.png  /usr/share/pixmaps/hotspot
		mv /tmp/hotspot.png /usr/share/pixmaps/hotspot
		mv /tmp/hotspot2.png /usr/share/pixmaps/hotspot
	fi
	cat <<EOF > /usr/share/Hotspot/StartHotspot.sh
#!$SHELL

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
echo -e "Hotspot\033[32;1m iniciado\033[0m..." >\
 /usr/share/Hotspot/hotspot.conf

exit 0

EOF
	cat <<EOF > /usr/share/Hotspot/RStarHotspot.sh
#!$SHELL

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
echo -e "Hotspot\033[33;1m reiniciando\033[0m..." >\
 /usr/share/Hotspot/hotspot.conf
cat /usr/share/Hotspot/hotspot.conf
sleep 5
echo -e "Hotspot\033[32;1m reiniciado\033[0m..." >\
 /usr/share/Hotspot/hotspot.conf
cat /usr/share/Hotspot/hotspot.conf
sleep 5

exit 0

EOF
	fim=EOF
	cat <<EOF > /usr/share/Hotspot/HotspotLogin.sh
#!$SHELL

senha=\$(dialog --title "AUTORIZAÇÃO" --passwordbox "Digite a senha (SUDO):" 8 40 --stdout)
if [ -z "\$senha" ]; then
	dialog --title "ERRO" --infobox "A senha (SUDO) não foi digitada." 3 40
	sleep 3
	clear
	exit 1
fi
clear
echo \$senha|sudo -S -p "" service hostapd stop
sudo chown $SUDO_USER:$SUDO_USER /etc/hostapd/hostapd.conf
sudo sed -i 's#^DAEMON_CONF=.*#DAEMON_CONF=/etc/hostapd/hostapd.conf#' /etc/init.d/hostapd
sudo ifconfig $wifi up
sudo ifconfig $wifi 192.168.137.1/24
sudo iptables -t nat -F
sudo iptables -F
sudo iptables -t nat -A POSTROUTING -o $ethe -j MASQUERADE
sudo iptables -A FORWARD -i $wifi -o $ethe -j ACCEPT
sudo echo '1' > /proc/sys/net/ipv4/ip_forward
clear
rede=\$(dialog --inputbox "Nome da rede Wi-Fi (SSID)" 10 45 --stdout)
clear
senha=\$(dialog --inputbox "Senha da rede Wi-Fi" 10 45 --stdout)
if [ -z "\$rede" -o -z "\$senha" ]; then
	texto="Nome da rede Wi-Fi (SSID) ou Senha da rede Wi-Fi não informados."
	cont="\$[\${#texto} + 4]"
	dialog --infobox "\$texto" 3 \$cont
	sleep 3
	clear
	sudo chown root:root /etc/hostapd/hostapd.conf
	sudo service hostapd start
	sudo service dnsmasq start
	exit 1
fi

clear
cat <<$fim > /etc/hostapd/hostapd.conf
interface=$wifi
driver=nl80211
channel=1

ssid=\$rede
wpa=2
wpa_passphrase=\$senha
wpa_key_mgmt=WPA-PSK
wpa_pairwise=CCMP
# Altera as chaves transmitidas/multidifundidas 
# após esse número de segundos.
wpa_group_rekey=600
# Troca a chave mestra após esse número de segundos. 
# A chave mestra é usada como base.
wpa_gmk_rekey=86400

$fim

sudo chown root:root /etc/hostapd/hostapd.conf
sudo service hostapd start
sudo service dnsmasq start
echo -e "Hotspot\033[32;1m iniciado\033[0m..." >\
 /usr/share/Hotspot/hotspot.conf
reset

exit 0

EOF

	cat <<EOF > /usr/share/Hotspot/StopHotspot.sh
#!$SHELL

service hostapd stop
service dnsmasq stop
echo -e "Hotspot\033[31;1m parado\033[0m..." >\
 /usr/share/Hotspot/hotspot.conf

exit 0

EOF

	cat <<EOF > /usr/share/applications/RStarHotspot.desktop
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Name=Restart do Hotspot
Name[pt_BR]=Restart do Hotspot
Exec=roxterm -e "sudo service hotstop restart"
Terminal=false
StartupNotify=true
Comment=Reinicia o hotspot
Comment[pt_BR]=Reinicia o hotspot
Keywords=hotspot;internet;network;
Keywords[pt_BR]=internet;network;hotspot;
Categories=Network;WebBrowser;
GenericName=Restart do Hotspot
GenericName[pt_BR]=Restart do Hotspot
Icon=/usr/share/pixmaps/hotspot/connection.png

EOF

	cat <<EOF > /usr/share/applications/HotspotLogin.desktop
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Name=Altera o login do Hotspot
Name[pt_BR]=Altera o login do Hotspot
Exec=roxterm -e "bash -c /usr/share/Hotspot/HotspotLogin.sh"
Terminal=false
StartupNotify=true
Comment=Altera o login do Hotspot
Comment[pt_BR]=Altera o login do Hotspot
Keywords=hotspot;internet;network;
Keywords[pt_BR]=internet;network;hotspot;
Categories=Network;WebBrowser;
GenericName=Restart do Hotspot
GenericName[pt_BR]=Restart do Hotspot
Icon=/usr/share/pixmaps/hotspot/hotspot2.png

EOF

	cat <<EOF > /usr/share/applications/StopHotspot.desktop
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Name=Finaliza o Hotspot
Name[pt_BR]=Finaliza o Hotspot
Exec=roxterm -e "sudo service hotstop stop"
Terminal=false
StartupNotify=true
Comment=Finaliza o hotspot
Comment[pt_BR]=Finaliza o hotspot
Keywords=hotspot;internet;network;
Keywords[pt_BR]=internet;network;hotspot;
Categories=Network;WebBrowser;
GenericName=Restart do Hotspot
GenericName[pt_BR]=Restart do Hotspot
Icon=/usr/share/pixmaps/hotspot/hotspot.png

EOF

	cp /usr/share/applications/RStarHotspot.desktop /home/$SUDO_USER/Desktop
	cp /usr/share/applications/HotspotLogin.desktop /home/$SUDO_USER/Desktop
	cp /usr/share/applications/StopHotspot.desktop /home/$SUDO_USER/Desktop
	clear
	texto="Os atalhos na Àrea de trabalho foram criados..."
	cont="$[${#texto} + 4]"
	dialog --infobox "$texto" 3 $cont
	sleep 3
	clear
	chmod +x /usr/share/Hotspot/*.sh /usr/share/applications/*.desktop
	chmod 775 /home/$SUDO_USER/Desktop/*.desktop
	chown $SUDO_USER:$SUDO_USER /home/$SUDO_USER/Desktop/*.desktop

	cat <<EOF >  /etc/init.d/hotstop
#!/bin/sh

### BEGIN INIT INFO
# Provides:		hotspot
# Required-Start:	$remote_fs
# Required-Stop:	$remote_fs
# Should-Start:		$network
# Should-Stop:
# Default-Start:	2 3 4 5
# Default-Stop:		0 1 6
# Short-Description:	Access point and authentication server for Wi-Fi and Ethernet
# Description:		Access point and authentication server for Wi-Fi and Ethernet
#			Userspace IEEE 802.11 AP and IEEE 802.1X/WPA/WPA2/EAP Authenticator
### END INIT INFO

. /lib/lsb/init-functions

case "\$1" in
  start)
	sleep 3
	/usr/share/Hotspot/StartHotspot.sh
	;;
  stop)
	/usr/share/Hotspot/StopHotspot.sh
	;;
  restart)
	/usr/share/Hotspot/RStarHotspot.sh
	;;
  status)
	cat /usr/share/Hotspot/hotspot.conf
	;;
esac

exit 0

EOF
	chmod +x /etc/init.d/hotstop
	update-rc.d hotstop defaults
	update-rc.d hostapd defaults
	update-rc.d dnsmasq defaults
	update-rc.d tlp defaults
	cat /etc/sudoers | grep -q "$SUDO_USER ALL=NOPASSWD: /etc/init.d/hotstop"
	if [ "$?" = "1" ]; then
		texto="As configurações serão atualizadas..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		reset
		sed '/^$/d' /etc/sudoers > /tmp/temp.txt && mv /tmp/temp.txt /etc/sudoers
		echo "$SUDO_USER ALL=NOPASSWD: /etc/init.d/hotstop" >> /etc/sudoers
	else
		texto="As configurações estão atualizadas..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		reset
	fi
	service hostapd start
	echo "Testanto o serviço Hotspot..."
	service hotstop start
	service hotstop status
	desktop-menu --write-out-global
	;;
	2)
	if [ -d "/usr/share/Hotspot" ]; then
		texto="O diretório Hotspot será removido..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
		service hotstop stop
		update-rc.d hostapd remove
		update-rc.d dnsmasq remove
		update-rc.d hotstop remove
		update-rc.d tlp remove
		rm -rf /usr/share/Hotspot
		apt remove -y hostapd dnsmasq wireless-tools iw tlp
		apt autoremove -y
		clear
	else
		texto="O diretório Hotspot não encontrado..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
	fi
	if [ -d "/usr/share/pixmaps/hotspot" ]; then
		texto="O diretório ../pixmaps/hotspot será removido..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
		rm -rf /usr/share/pixmaps/hotspot
	else
		texto="O diretório ../pixmaps/hotspot não encontrado..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
	fi
	if [ -e "/etc/init.d/hotstop" ]; then
		texto="O arquivo ../init.d/hotstop será removido..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
		rm /etc/init.d/hotstop
	else
		texto="O arquivo ../init.d/hotstop não encontrado..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
	fi
	if [ -e "/usr/share/applications/RStarHotspot.desktop" ]; then
		texto="O arquivo ../applications/RStarHotspot.desktop será removido..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
		rm /usr/share/applications/RStarHotspot.desktop
	else
		texto="O arquivo ../applications/RStarHotspot.desktop não encontrado..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
	fi
	if [ -e "/usr/share/applications/HotspotLogin.desktop" ]; then
		texto="O arquivo ../applications/HotspotLogin.desktop será removido..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
		rm /usr/share/applications/HotspotLogin.desktop
	else
		texto="O arquivo ../applications/HotspotLogin.desktop não encontrado..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
	fi
	if [ -e "/usr/share/applications/StopHotspot.desktop" ]; then
		texto="O arquivo ../applications/StopHotspot.desktop será removido..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
		rm /usr/share/applications/StopHotspot.desktop
	else
		texto="O arquivo ../applications/StopHotspot.desktop não encontrado..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
	fi
	if [ -e "/home/$SUDO_USER/Desktop/RStarHotspot.desktop" ]; then
		texto="O arquivo ../Desktop/RStarHotspot.desktop será removido..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
		rm /home/$SUDO_USER/Desktop/RStarHotspot.desktop
	else
		texto="O arquivo ../Desktop/RStarHotspot.desktop não encontrado..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
	fi
	if [ -e "/home/$SUDO_USER/Desktop/HotspotLogin.desktop" ]; then
		texto="O arquivo ../Desktop/HotspotLogin.desktop será removido..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
		rm /home/$SUDO_USER/Desktop/HotspotLogin.desktop
	else
		texto="O arquivo ../Desktop/HotspotLogin.desktop não encontrado..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
	fi
	if [ -e "/home/$SUDO_USER/Desktop/StopHotspot.desktop" ]; then
		texto="O arquivo ../Desktop/StopHotspot.desktop será removido..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
		rm /home/$SUDO_USER/Desktop/StopHotspot.desktop
	else
		texto="O arquivo ../Desktop/StopHotspot.desktop não encontrado..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
	fi
	if [ "$(cat "/etc/hostapd/hostapd.conf")" ]; then
		texto="A configuração será removida em hostapd.conf..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
		echo "" > /etc/hostapd/hostapd.conf
	else
		texto="Configuração não encontrada em hostapd.conf..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
	fi
	cat /etc/sudoers | grep -q "$SUDO_USER ALL=NOPASSWD: /etc/init.d/hotstop"
	if [ "$?" = "1" ]; then
		texto="Configuração não encontrada em ../etc/sudoers..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		reset
	else
		texto="A configuração será deletada em ../etc/sudoers..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		clear
		awk -F "$SUDO_USER ALL=NOPASSWD: /etc/init.d/hotstop" '{print $1}' /etc/sudoers > /tmp/temp.txt
		mv /tmp/temp.txt /etc/sudoers
		texto="Configuração foi removida ../etc/sudoers..."
		cont="$[${#texto} + 4]"
		dialog --infobox "$texto" 3 $cont
		sleep 3
		reset
		desktop-menu --write-out-global
	fi
	;;
	3)
	texto="Saindo do instalador..."
	cont="$[${#texto} + 4]"
	dialog --infobox "$texto" 3 $cont
	sleep 3
	reset
	;;
	*)
	texto="Instalação cancelada..."
	cont="$[${#texto} + 4]"
	dialog --infobox "$texto" 3 $cont
	sleep 3
	reset
	exit 1
	;;
esac

exit 0

