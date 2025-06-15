#!/bin/bash

trim() {
	# Desabilitação da verificação do shell=2048,2086
    set -f
    set -- $*
    printf '%s\n' "${*//[[:space:]]/}"
    set +f
}

Ppid(){
	# Obter o ID do processo pai do PID
	ppid="$(grep -i -F "PPid:" "/proc/${1:-$PPID}/status")"
    ppid="$(trim "${ppid/PPid:}")"
    printf "%s" "$ppid"

}

processo_nome() {
    # Obter nome PID.
    nome="$(< "/proc/${1:-$PPID}/comm")"
    printf "%s" "$nome"
}

terminal() {
    # Verificando $PPID para emulador de terminal.
     while [[ -z "$term" ]]; do
        pai="$(Ppid "$pai")"
        [[ -z "$pai" ]] && break
        nome="$(processo_nome "$pai")"

        case ${nome// } in
            "${SHELL/*\/}"|*"sh"|"screen"|"su"*) ;;

            "login"*|*"Login"*|"init"|"(init)")
                term="$(tty)"
            ;;

            "ruby"|"1"|"tmux"*|"systemd"|"sshd"*|"python"*|"USER"*"PID"*|"kdeinit"*|"launchd"*)
                break
            ;;

            "gnome-terminal-") term="gnome-terminal" ;;
            "urxvtd")          term="urxvt" ;;
            *"nvim")           term="Neovim Terminal" ;;
            *"NeoVimServer"*)  term="VimR Terminal" ;;

            *)
                # Corrigir problemas com nomes longos de processos no Linux.
                term="${nome##*/}"
            ;;
        esac
    done
}

display_principal(){
	cont="$[${#texto} + 4]"
	dialog --title "$titulo" --infobox "$texto" 3 $cont
	sleep 2
	clear
}

input_principal(){
	cont="$[${#texto} + 4]"
	nome=$(dialog --inputbox "$texto" 8 $cont --stdout)
	validacao="$?"
	clear
}

cancelar_principal(){
	if [ "$validacao" = "1" ]; then
		texto="Cancelado pelo usuário."
		titulo="CANCELADO"
		display_principal
		exit 0
	fi
}

if [ "$USER" != "root" ]; then
	echo -e "Use comando 'sudo'  ou comando 'su'
antes de inicializar o programa.\n"
	exit 1
fi
if ! [ -e "/usr/bin/dialog" ]; then
	echo -e "Dialog não instalado e será instaladp...\n"
	sudo apt install -y dialog
fi

pasta_hotspot=/usr/share/Hotspot
pasta_icones=/usr/share/pixmaps/hotspot

terminal
texto="Para a Distribuição Debian 12 e derivados (antiX 23)"
cont="$[${#texto} + 4]"
dialog --title "Desenvolvedor" --infobox "Desenvolvido por Marx F. C. Monte\n
Instalador de Hotspot v 1.8 (2025)\n
Para a Distribuição Debian 12 e derivados (antiX 23)" 5 $cont
clear
conexoes=$(ifconfig -a | grep BROADCAST -c)
if [ "$conexoes" -lt 2 ]; then
	texto="Deve haver pelo menos 2 interfaces ativas (Ethernet e Wi-Fi)..."
	tituto="ERRO"
	display_principal
	texto="Instalação finalizada."
	tituto="ERRO"
	display_principal
	exit 1
fi
texto="SETAS PARA ESCOLHER E ENTER PARA CONFIRMAR"
cont="$[${#texto} + 4]"
opcao=$(dialog --title "MENU" --menu "$texto" 10 $cont 3 \
"1" "INSTALAR" \
"2" "REMOVER" \
"3" "SAIR" \
--stdout)
clear
case $opcao in
	1)
	texto="Instalação sendo iniciada..."
	display_principal
	while true
	do
		interfaces=($(ifconfig -a | grep BROADCAST | cut -d ":" -f1))
		ethe=${interfaces[0]}
		wifi=${interfaces[1]}
		tituto="NOME DA REDE"
		texto="Nome da rede W-Fi (SSID)"
		input_principal
		cancelar_principal
		rede=$nome
		if [ -z "$rede" ]; then
			texto="Nome da rede Wi-Fi (SSID) não informado."
			titulo="ERRO"
			display_principal
		else
			break
		fi
	done
	while true
	do
		texto="Senha da rede Wi-Fi"
		tituto="SENHA DA REDE"
		input_principal
		cancelar_principal
		senha=$nome
		if [ -z "$senha" ]; then
			texto="Senha da rede Wi-Fi não informada."
			titulo="ERRO"
			display_principal
		else
			break
		fi
	done
	if [ -e "$pasta_hotspot/install.conf" ]; then
		texto="A instalação dos pacotes não será necessária..."
		titulo="INSTALAÇÃO"
		display_principal
	else
		apt update && apt upgrade -y
		apt install -y hostapd dnsmasq wireless-tools iw tlp
	fi
	if [ -d "$pasta_hotspot" ]; then
		texto="O diretório Hotspot existe..."
		titulo="INSTALAÇÃO"
		display_principal
	else
		texto="O diretório Hotspot será criado..."
		titulo="INSTALAÇÃO"
		display_principal
		mkdir $pasta_hotspot
	fi
	if [ -e "$pasta_hotspot/install.conf" ]; then
		texto="O arquivo install.conf existe..."
		titulo="INSTALAÇÃO"
		display_principal
	else
		texto="O arquivo install.conf será criado..."
		titulo="INSTALAÇÃO"
		display_principal
		echo "Pacotes instalados hostapd dnsmasq \
wireless-tools iw tlp." > $pasta_hotspot/install.conf
	fi
	
	if [ "$(echo "\$dns" | grep running)" ]; then
		service dnsmasq stop
	fi

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
	if ! [ "$(echo "$host" | grep "not running")" ]; then
		service hostapd stop
	fi

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
	if [ -d "$pasta_icones" ]; then
		texto="O diretório para os icones existe..."
		display_principal
	else
		texto="O diretório para os icones será criado..."
		display_principal
		mkdir $pasta_icones
		cat <<EOF > $pasta_hotspot/hotspot_icones
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
		wget -i $pasta_hotspot/hotspot_icones -P /tmp/
		mv /tmp/connection.png  $pasta_icones
		mv /tmp/hotspot.png $pasta_icones
		mv /tmp/hotspot2.png $pasta_icones
	fi
	cat <<EOF > $pasta_hotspot/StartHotspot.sh
#!$SHELL

pasta_hotspot=/usr/share/Hotspot
host="\$(service hostapd status)"
dns="\$(service dnsmasq status)"
if ! [ "\$(echo "\$host" | grep "not running")" ]; then
	service hostapd stop
fi
if [ "\$(echo "\$dns" | grep running)" ]; then
	service dnsmasq stop
fi
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
echo -e "Hotspot\033[32m iniciado\033[0m..." > \$pasta_hotspot/hotspot.conf

exit 0

EOF
	cat <<EOF > /usr/share/Hotspot/RStarHotspot.sh
#!$SHELL

pasta_hotspot=/usr/share/Hotspot
host="\$(service hostapd status)"
dns="\$(service dnsmasq status)"
if ! [ "\$(echo "\$host" | grep "not running")" ]; then
	service hostapd stop
fi
if [ "\$(echo "\$dns" | grep running)" ]; then
	service dnsmasq stop
fi
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
echo -e "Hotspot\033[33;1m reiniciando\033[0m..." > \$pasta_hotspot/hotspot.conf 
cat \$pasta_hotspot/hotspot.conf
sleep 5
echo -e "Hotspot\033[32;1m reiniciado\033[0m..." > \$pasta_hotspot/hotspot.conf
cat \$pasta_hotspot/hotspot.conf
sleep 5

exit 0

EOF
	fim=EOF
	cat <<EOF > $pasta_hotspot/HotspotLogin.sh
#!$SHELL

display_principal(){
	cont="\$[\${#texto} + 4]"
	dialog --title "\$titulo" --infobox "\$texto" 3 \$cont
	sleep 2
	clear
}

input_principal(){
	cont="\$[\${#texto} + 14]"
	nome=\$(dialog --inputbox "\$texto" 8 \$cont --stdout)
	validacao="\$?"
	clear
}

cancelar_principal(){
	if [ "\$validacao" = "1" ]; then
		texto="Cancelado pelo usuário."
		display_principal
		sudo chown root:root /etc/hostapd/hostapd.conf
		sudo service hostapd start
		sudo service dnsmasq start
		exit 0
	fi
}


pasta_hotspot=/usr/share/Hotspot
while true
do
	senha=\$(dialog --title "AUTORIZAÇÃO" --passwordbox "Digite a senha (SUDO):" 8 40 --stdout)
	validacao="\$?"
	cancelar_principal
	if [ -z "\$senha" ]; then
		dialog --colors --title "\Zr\Z1  ERRO                               \Zn" --infobox "A senha (SUDO) não foi digitada." 3 37
		sleep 2
		clear
	else
		break
	fi
done
clear
host="\$(echo \$senha|sudo -S -p "" service hostapd status)"
dns="\$(sudo service dnsmasq status)"
if ! [ "\$(echo "\$host" | grep "not running")" ]; then
	sudo service hostapd stop
fi
if [ "\$(echo "\$dns" | grep running)" ]; then
	sudo service dnsmasq stop
fi
sudo chown \$USER:\$USER /etc/hostapd/hostapd.conf
sudo sed -i 's#^DAEMON_CONF=.*#DAEMON_CONF=/etc/hostapd/hostapd.conf#' /etc/init.d/hostapd
sudo ifconfig $wifi up
sudo ifconfig $wifi 192.168.137.1/24
sudo iptables -t nat -F
sudo iptables -F
sudo iptables -t nat -A POSTROUTING -o $ethe -j MASQUERADE
sudo iptables -A FORWARD -i $wifi -o $ethe -j ACCEPT
sudo echo '1' > /proc/sys/net/ipv4/ip_forward
clear
while true
do
	texto="Nome da rede Wi-Fi (SSID)"
	input_principal
	cancelar_principal
	rede=\$nome
	if [ -z "\$rede" ]; then
		texto="Nome da rede Wi-Fi (SSID) não informado."
		display_principal
	else
		break
	fi
done
while true
do
	texto="Senha da rede Wi-Fi"
	input_principal
	cancelar_principal
	senha=\$nome
	if [ -z "\$senha" ]; then
		texto="Senha da rede Wi-Fi não informada."
		display_principal
	else
		break
	fi
done
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
echo -e "Hotspot\033[32;1m reiniciado\033[0m..." > \$pasta_hotspot/hotspot.conf
reset

exit 0

EOF

	cat <<EOF > /usr/share/Hotspot/StopHotspot.sh
#!$SHELL

pasta_hotspot=/usr/share/Hotspot
service hostapd stop
service dnsmasq stop
echo -e "Hotspot\033[31;1m parado\033[0m..." > \$pasta_hotspot/hotspot.conf

exit 0

EOF

	cat <<EOF > /usr/share/applications/RStarHotspot.desktop
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Name=Restart do Hotspot
Name[pt_BR]=Restart do Hotspot
Exec=$term -e "sudo service hotstop restart"
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
Exec=$term -e "bash -c /usr/share/Hotspot/HotspotLogin.sh"
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
Exec=$term -e "sudo service hotstop stop"
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
	titulo="INSTALAÇÃO"
	display_principal
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
	$pasta_hotspot/StartHotspot.sh
	;;
  stop)
	$pasta_hotspot/StopHotspot.sh
	;;
  restart)
	$pasta_hotspot/RStarHotspot.sh
	;;
  status)
	cat $pasta_hotspot/hotspot.conf
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
		titulo="INSTALAÇÃO"
		display_principal
		sed '/^$/d' /etc/sudoers > /tmp/temp.txt && mv /tmp/temp.txt /etc/sudoers
		echo "$SUDO_USER ALL=NOPASSWD: /etc/init.d/hotstop" >> /etc/sudoers
	else
		texto="As configurações estão atualizadas..."
		titulo="INSTALAÇÃO"
		display_principal
	fi
	clear
	service hostapd start
	echo "Testanto o serviço Hotspot..."
	service hotstop start
	service hotstop status
	desktop-menu --write-out-global
	;;
	2)
	if [ -d "$pasta_hotspot" ]; then
		texto="O diretório Hotspot será removido..."
		titulo="DESINSTALAÇÃO"
		display_principal
		service hotstop stop
		update-rc.d hostapd remove
		update-rc.d dnsmasq remove
		update-rc.d hotstop remove
		update-rc.d tlp remove
		rm -rf $pasta_hotspot
		apt remove -y hostapd dnsmasq wireless-tools iw tlp
		apt autoremove -y
		clear
	else
		texto="O diretório Hotspot não encontrado..."
		titulo="DESINSTALAÇÃO"
		display_principal
	fi
	if [ -d "$pasta_icones" ]; then
		texto="O diretório ../pixmaps/hotspot será removido..."
		titulo="DESINSTALAÇÃO"
		display_principal
		rm -rf $pasta_icones
	else
		texto="O diretório ../pixmaps/hotspot não encontrado..."
		titulo="DESINSTALAÇÃO"
		display_principal
	fi
	if [ -e "/etc/init.d/hotstop" ]; then
		texto="O arquivo ../init.d/hotstop será removido..."
		titulo="DESINSTALAÇÃO"
		display_principal
		rm /etc/init.d/hotstop
	else
		texto="O arquivo ../init.d/hotstop não encontrado..."
		titulo="DESINSTALAÇÃO"
		display_principal
	fi
	if [ -e "/usr/share/applications/RStarHotspot.desktop" ]; then
		texto="O arquivo ../applications/RStarHotspot.desktop será removido..."
		titulo="DESINSTALAÇÃO"
		display_principal
		rm /usr/share/applications/RStarHotspot.desktop
	else
		texto="O arquivo ../applications/RStarHotspot.desktop não encontrado..."
		display_principal
	fi
	if [ -e "/usr/share/applications/HotspotLogin.desktop" ]; then
		texto="O arquivo ../applications/HotspotLogin.desktop será removido..."
		titulo="DESINSTALAÇÃO"
		display_principal
		rm /usr/share/applications/HotspotLogin.desktop
	else
		texto="O arquivo ../applications/HotspotLogin.desktop não encontrado..."
		titulo="DESINSTALAÇÃO"
		display_principal
	fi
	if [ -e "/usr/share/applications/StopHotspot.desktop" ]; then
		texto="O arquivo ../applications/StopHotspot.desktop será removido..."
		titulo="DESINSTALAÇÃO"
		display_principal
		rm /usr/share/applications/StopHotspot.desktop
	else
		texto="O arquivo ../applications/StopHotspot.desktop não encontrado..."
		titulo="DESINSTALAÇÃO"
		display_principal
	fi
	if [ -e "/home/$SUDO_USER/Desktop/RStarHotspot.desktop" ]; then
		texto="O arquivo ../Desktop/RStarHotspot.desktop será removido..."
		titulo="DESINSTALAÇÃO"
		display_principal
		rm /home/$SUDO_USER/Desktop/RStarHotspot.desktop
	else
		texto="O arquivo ../Desktop/RStarHotspot.desktop não encontrado..."
		titulo="DESINSTALAÇÃO"
		display_principal
	fi
	if [ -e "/home/$SUDO_USER/Desktop/HotspotLogin.desktop" ]; then
		texto="O arquivo ../Desktop/HotspotLogin.desktop será removido..."
		titulo="DESINSTALAÇÃO"
		display_principal
		rm /home/$SUDO_USER/Desktop/HotspotLogin.desktop
	else
		texto="O arquivo ../Desktop/HotspotLogin.desktop não encontrado..."
		titulo="DESINSTALAÇÃO"
		display_principal
	fi
	if [ -e "/home/$SUDO_USER/Desktop/StopHotspot.desktop" ]; then
		texto="O arquivo ../Desktop/StopHotspot.desktop será removido..."
		titulo="DESINSTALAÇÃO"
		display_principal
		rm /home/$SUDO_USER/Desktop/StopHotspot.desktop
	else
		texto="O arquivo ../Desktop/StopHotspot.desktop não encontrado..."
		titulo="DESINSTALAÇÃO"
		display_principal
	fi
	if [ "$(cat "/etc/hostapd/hostapd.conf")" ]; then
		texto="A configuração será removida em hostapd.conf..."
		titulo="DESINSTALAÇÃO"
		display_principal
		echo "" > /etc/hostapd/hostapd.conf
	else
		texto="Configuração não encontrada em hostapd.conf..."
		titulo="DESINSTALAÇÃO"
		display_principal
	fi
	cat /etc/sudoers | grep -q "$SUDO_USER ALL=NOPASSWD: /etc/init.d/hotstop"
	if [ "$?" = "1" ]; then
		texto="Configuração não encontrada em ../etc/sudoers..."
		titulo="DESINSTALAÇÃO"
		display_principal
	else
		texto="A configuração será deletada em ../etc/sudoers..."
		titulo="DESINSTALAÇÃO"
		display_principal3
		clear
		awk -F "$SUDO_USER ALL=NOPASSWD: /etc/init.d/hotstop" '{print $1}' /etc/sudoers > /tmp/temp.txt
		mv /tmp/temp.txt /etc/sudoers
		sed '/^$/d' /etc/sudoers > /tmp/temp.conf && mv /tmp/temp.conf /etc/sudoers
		texto="Configuração foi removida ../etc/sudoers..."
		titulo="DESINSTALAÇÃO"
		display_principal
		desktop-menu --write-out-global
	fi
	reset
	;;
	3)
	texto="Saindo do instalador..."
	titulo="SAINDO"
	display_principal
	;;
	*)
	texto="Instalação cancelada..."
	titulo="CANCELADO"
	display_principal
	;;
esac

reset

exit 0
