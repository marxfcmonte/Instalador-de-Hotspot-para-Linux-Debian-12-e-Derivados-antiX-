#!/bin/bash

if ! [ -e "/usr/bin/dialog" ]; then
	echo -e "Dialog não instalado e será instaladp...\n"
	sudo apt install -y dialog
fi
if ! [ -e "/usr/bin/roxterm" ]; then
	echo -e "Roxterm não instalado e será instaladp...\n"
	apt install -y roxterm
fi

senha=$(dialog --title "AUTORIZAÇÃO" --passwordbox "Digite a senha (SUDO):" 8 40 --stdout)

if [ -z "\$senha" ]; then
	dialog --title "ERRO" --infobox "A senha (SUDO) não foi digitada." 3 40
	sleep 3
	clear
	exit 1
fi
clear
local="$(pwd)"
if ! [ -e "/bin/shc" ]; then
	echo $senha|sudo -S -p "" apt install -y shc libc6-dev
	shc -f "$local/InstallHotspotSemSudo.sh" -o "$local/InstallHotspotSemSudo"
	sudo bash -c "$local/InstallHotspotSemSudo"
	
else
	shc -f "$local/InstallHotspotSemSudo.sh" -o "$local/InstallHotspotSemSudo"
	sudo bash -c "$local/InstallHotspotSemSudo"
fi



