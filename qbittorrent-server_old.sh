#!/bin/bash

# Criador : LUCIANO PEREIRA DE SOUZA
# Finalidade : Criar um servidor de torrents.
# Como instalar : bash qbittorrent-server.sh
# Como acesar : No navegador digite o IP do servidor e a porta
    # Exemplo : 192.168.0.10:8080
    # Login : admin
    # Senha : adminadmin

App="qbittorrent"
servico="qbit.service"

# Instalação do qbittorrent
apt install $App-nox -y

# Criação do arquivo de serviço.
echo -e "\
[Unit]
Description=qbittorrent
After=network.target syslog.target
[Service]
Type=simple
ExecStart=/usr/bin/$App-nox
ExecStop=/usr/bin/killall $App-nox
restart=on-failure
[Install]
WantedBy=multi-user.target\n" >> /lib/systemd/system/$servico

# Reinicia o daemon.
systemctl daemon-reload

# Habilita na inicialização do sistema.
systemctl enable $servico

# Inicia o serviço.
systemctl start $servico

# Mostra o status do serviço.
systemctl status $servico

#=== Reseta a senha ===#
# sed -r "/WebUI.Password_PBKDF2/d" /.config/qBittorrent/qBittorrent.conf -i
# sed -r "/WebUI.Username=admin/d"  /.config/qBittorrent/qBittorrent.conf -i
