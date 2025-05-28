#!/bin/bash

echo "
Desenvolvido por Marx F. C. Monte
Instalador de Hotspot v 1.8 (2025)
Para a Distribuição Debian 12 e derivados (antiX 23)\
"

if [ "$USER" != "root" ]; then
	echo -e "Use comando 'sudo'  ou comando 'su' 
antes de inicializar o programa.\n"

	exit 1	
fi
conexoes=$(ifconfig -a | grep broadcast -c)
if [ "$conexoes" -lt 2 ]; then
	echo -e "\nDeve haver pelo menos 2 interfaces ativas (Ethernet e Wi-Fi)...\n
Instalação finalizada...\n"
	exit 1        
fi
echo "
	MENU
[1] PARA INSTALAR
[2] PARA REMOVER
[3] PARA SAIR
"
read -p "OPÇÃO: " opcao

if [ "$opcao" = "1" ]; then
	echo -e "\nInstalação sendo iniciada...\n"	
	interfaces=( $(ifconfig -a | grep broadcast -B 1 | cut -d ":" -f1 -s | sed 's/ //g') )
	ethe=${interfaces[0]}
	wifi=${interfaces[1]}
	
	echo -e "Nome da interface da rede Ethernet: $ethe"
	echo -e "Nome da interface da rede Wi-Fi: $wifi"
	read -p "Nome da rede Wi-Fi (SSID): " rede
	read -p "Senha da rede Wi-Fi: " senha
	echo 
	if [ -e "/usr/share/Hotspot/install.conf" ]; then
		echo "A instalação dos pacotes não será necessária..."
	else
		apt update && apt upgrade -y
		apt install -y hostapd dnsmasq wireless-tools iw tlp dialog
	fi
	if [ -d "/usr/share/Hotspot" ]; then
		echo -e "O diretório Hotspot existe..."
	else
		echo -e "\nO diretório Hotspot será criado...\n"
				mkdir /usr/share/Hotspot
	fi
	if [ -e "/usr/share/Hotspot/install.conf" ]; then
		echo "O arquivo install.conf existe..."
	else
		echo -e "O arquivo install.conf será criado..."
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
		echo "O diretório para os icones existe..."
	else
		echo "O diretório para os icones será criado..."
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

	cat <<EOF > /usr/share/Hotspot/RStarHotspot.sh
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
echo "Hotspot reiniciando..." > /usr/share/Hotspot/hotspot.conf
cat /usr/share/Hotspot/hotspot.conf
sleep 5
echo "Hotspot reiniciado..." > /usr/share/Hotspot/hotspot.conf
cat /usr/share/Hotspot/hotspot.conf
sleep 5

exit 0

EOF
	fim=EOF
	cat <<EOF > /usr/share/Hotspot/HotspotLogin.sh
#!/bin/bash
senha=\$(dialog --title "AUTORIZAÇÃO" --passwordbox "Digite a senha (SUDO):" 8 40 --stdout)
if [[ -z "\$senha" ]]; then
	dialog --title "ERRO" --infobox "A senha (SUDO) não foi digitada." 3 40
	exit 1
fi
clear
echo \$senha|sudo -S -p "" service hostapd stop
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
clear
sudo cat <<$fim > /etc/hostapd/hostapd.conf
interface=$wifi
driver=nl80211
channel=1

ssid=\$rede
wpa=2
wpa_passphrase=\$senha
wpa_key_mgmt=WPA-PSK
wpa_pairwise=CCMP
# Altera as chaves transmitidas/multidifundidas após esse número de segundos.
wpa_group_rekey=600
# Troca a chave mestra após esse número de segundos. A chave mestra é usada como base.
wpa_gmk_rekey=86400

$fim

sudo service hostapd start
sudo service dnsmasq start

exit 0

EOF


	cat <<EOF > /usr/share/Hotspot/StopHotspot.sh
#!/bin/bash

service hostapd stop
service dnsmasq stop

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
	echo "Os atalhos na Àrea de trabalho foram criados..."
	chmod +x /usr/share/Hotspot/*.sh /usr/share/applications/RStarHotspot.desktop /usr/share/applications/StopHotspot.desktop 
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
	echo "Hotspot\e[32;1m iniciado\e[0m..." > /usr/share/Hotspot/hotspot.conf
	;;
  stop)
	/usr/share/Hotspot/StopHotspot.sh
	echo "Hotspot\e[31;1m parado\e[0m..." > /usr/share/Hotspot/hotspot.conf
	;;
  restart)
	/usr/share/Hotspot/RStarHotspot.sh
	echo "Hotspot\e[32;1m reiniciado\e[0m..." > /usr/share/Hotspot/hotspot.conf
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
		echo "As configurações serão atualizadas..." 
		sed '/^$/d' /etc/sudoers > /tmp/temp.txt && mv /tmp/temp.txt /etc/sudoers
		echo "$SUDO_USER ALL=NOPASSWD: /etc/init.d/hotstop" >> /etc/sudoers
	else
		echo "As configurações estão atualizadas..."
	fi
	service hostapd start
	echo "Testanto o serviço Hotspot..."
	service hotstop start
	service hotstop status
	desktop-menu --write-out-global
elif [ "$opcao" = "2" ]; then
	echo ""
	if [ -d "/usr/share/Hotspot" ]; then
		echo "Os arquivos serão removidos..." 
		service hotstop stop
		update-rc.d hostapd remove
		update-rc.d dnsmasq remove
		update-rc.d hotstop remove
		update-rc.d tlp remove
		rm /etc/init.d/hotstop
		rm -rf /usr/share/Hotspot
		apt remove -y hostapd dnsmasq wireless-tools iw tlp
		apt autoremove -y
		
	else
		echo "O diretório não encontrado..."
	fi
	if [ -d "/usr/share/pixmaps/hotspot" ]; then
		echo "Os arquivos serão removidos..." 
		rm -rf /usr/share/pixmaps/hotspot
	else
		echo "O diretório não encontrado..."
	fi
	if [ -e "/etc/init.d/hotstop" ]; then
		rm /etc/init.d/hotstop
	else
		echo "O arquivo não encontrado..."
	fi
	if [ -e "/usr/share/applications/RStarHotspot.desktop" ]; then
		rm /usr/share/applications/RStarHotspot.desktop
	else
		echo "O arquivo não encontrado..."
	fi
	if [ -e "/usr/share/applications/StopHotspot.desktop" ]; then
		rm /usr/share/applications/StopHotspot.desktop
	else
		echo "O arquivo não encontrado..."
	fi
	if [ -e "/home/$SUDO_USER/Desktop/RStarHotspot.desktop" ]; then
		rm /home/$SUDO_USER/Desktop/RStarHotspot.desktop
	else
		echo "O arquivo não encontrado..."
	fi
	if [ -e "/home/$SUDO_USER/Desktop/HotspotLogin.desktop" ]; then
		rm /home/$SUDO_USER/Desktop/HotspotLogin.desktop
	else
		echo "O arquivo não encontrado..."
	fi
	if [ -e "/home/$SUDO_USER/Desktop/StopHotspot.desktop" ]; then
		rm /home/$SUDO_USER/Desktop/StopHotspot.desktop
	else
		echo "O arquivo não encontrado..."
	fi
	if [ -e "/etc/hostapd/hostapd.conf" ]; then
		echo "" > /etc/hostapd/hostapd.conf
	else
		echo "O arquivo não encontrado..."
	fi
	cat /etc/sudoers | grep -q "$SUDO_USER ALL=NOPASSWD: /etc/init.d/hotstop"
	if [ "$?" = "1" ]; then
		echo "Configuração não encontrada..."
	else
		echo "A configuração será deletada... "
		awk -F "$SUDO_USER ALL=NOPASSWD: /etc/init.d/hotstop" '{print $1}' /etc/sudoers > /tmp/temp.txt
		mv /tmp/temp.txt /etc/sudoers
		echo "Os arquivos foram removidos..."
		desktop-menu --write-out-global
	fi	 
elif [ "$opcao" = "3" ]; then
	echo -e "\nSaindo do instalador...\n" 
else
	echo -e "\nOpção inválida!!!\n" 
fi

sleep 2

echo 

exit 0
