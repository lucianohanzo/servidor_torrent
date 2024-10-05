#!/bin/bash

# Criador : LUCIANO PEREIRA DE SOUZA
# Finalidade : Cria um servidor de torrents.
# Como instalar : bash ./qbittorrent-server.sh
# Como acesar : No navegador digite o IP do servidor e a porta
    # Exemplo : 192.168.0.10:8080
    # Login : admin
    # Senha : adminadmin


# Instalação do qbittorrent
apt install qbittorrent-nox

# Criação do arquivo qbittorrent.service.
echo -e "\
[Unit]
Description=qbittorrent
After=network.target syslog.target
[Service]
Type=simple
ExecStart=/usr/bin/qbittorrent-nox
ExecStop=/usr/bin/killall qbittorrent-nox
restart=on-failure
[Install]
WantedBy=multi-user.target\n" >> /lib/systemd/system/qbittorrent.service

# Reinicia o daemon.
systemctl daemon-reload

# Habilita na inicialização do sistema.
systemctl enable qbittorrent.service

# Inicia o serviço.
systemctl start qbittorrent.service

# Mostra o status do serviço.
systemctl status qbittorrent.service
