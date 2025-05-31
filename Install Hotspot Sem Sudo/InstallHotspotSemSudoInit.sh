#!/bin/bash

if ! [ -e "/usr/bin/dialog" ]; then
	senha=read -p "Dialog não instalado, digite a senha (SUDO): "
	echo $senha|sudo -S -p "" apt install -y dialog
else
	senha=$(dialog --title "AUTORIZAÇÃO" --passwordbox "Digite a senha (SUDO):" 8 40 --stdout)
fi

if [ -z "\$senha" ]; then
	dialog --title "ERRO" --infobox "A senha (SUDO) não foi digitada." 3 40
	sleep 3
	clear
	exit 1
fi
clear
if ! [ -e "/usr/bin/roxterm" ]; then
	echo -e "Roxterm não instalado e será instaladp...\n"
	echo $senha|sudo -S -p "" apt install -y roxterm
fi
local="$(pwd)"
if ! [ -e "/bin/shc" ]; then
	echo $senha|sudo -S -p "" apt install -y shc libc6-dev
	shc -f "$local/InstallHotspotSemSudo.sh" -o "$local/InstallHotspotSemSudo"
	sudo bash -c "$local/InstallHotspotSemSudo"
else
	shc -f "$local/InstallHotspotSemSudo.sh" -o "$local/InstallHotspotSemSudo"
	echo $senha|sudo -S -p "" bash -c "$local/InstallHotspotSemSudo"
fi



