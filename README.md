# Instalador de Hotspot para Linux Debian e (Derivados antiX - SysV)

Os arquivos InstallHotspot.sh, InstallHotspot e Installhotspot.deb  devem ser executados no terminal como root, usando o comando sudo ou su.

Ele desenvolve três softwares: um para restabelecer a rede Wi-Fi, um para mudar o login da rede Wi-Fi e, por fim, um para encerrar o serviço de rede Wi-Fi. Além disso, permite que o serviço de rede Wi-Fi seja iniciado automaticamente com a inicialização do sistema. (SysV)

Cria atalhos para a Área de trabalho e no menu dos aplicativos do sistema.

## Dependências

- hostapd
- dnsmasq
- wireless-tools
- iw
- tlp (A dependênia **tlp** é instalada devido ao pacote **iw**)
- dialog (A dependênia **dialog** é nativa em diversas distribuições baseadas em Debian, caso não haja será instalada)
- roxterm (A dependênia **roxterm** é nativa em diversas distribuições baseadas em Debian, caso não haja será instalada)

## Totalmente automatizado.

Ele reconhece as Interfaces e faz as configurações, apenas solicitando do usuário o nome para a rede Wi-FI e senha.

Agora com pacote Deb, Installhotspot.deb, para uma instalação automatizada pelo gerenciador de pacotes Deb sem precisar do terminal.
