# Instalador de Hotspot para Linux Debian e DerivadosantiX-23 (SysV)

Os arquivos InstallHotspot.sh, InstallHotspot e Installhotspot.deb  podem ser executados no terminal como root, usando o comando sudo ou su.

Ele desenvolve três softwares: um para restabelecer a rede Wi-Fi, um para mudar o login da rede Wi-Fi e, por fim, um para encerrar o serviço de rede Wi-Fi. Além disso, permite que o serviço de rede Wi-Fi seja iniciado automaticamente com a inicialização do sistema. (SysV)

Cria atalhos para a Área de trabalho e no menu dos aplicativos do sistema.

## Dependências

- hostapd dnsmasq wireless-tools iw tlp dialog (A dependênia **tlp** é instalada devido ao pacote **iw**)

## Totalmente automatizado.

Ele reconhece as interfaces e faz as configurações, apenas solicitando do usuário o nome da rede Wi-FI e senha.

Agora com pacote Deb, Installhotspot.deb, para uma instalação automatizada pelo gerenciador de pacotes Deb sem precisar do terminal.
