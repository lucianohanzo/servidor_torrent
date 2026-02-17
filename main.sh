#!/bin/bash

# Criador : LUCIANO PEREIRA DE SOUZA
# Finalidade : Criar um servidor de torrents.
# Como instalar : bash qbittorrent-server.sh
# Como acesar : No navegador digite o IP do servidor e a porta
    # Exemplo : 192.168.0.10:8080
    # Login : admin
    # Senha : adminadmin


# Cria as pastas, caso não existam.
pasta_systemd="$HOME/.config/systemd/user/"
pasta_bin=$HOME/.local/bin/
pasta_ssl=$HOME/.local/ssl/qbittorrent-nox/
[ -d "$pasta_systemd" ] || mkdir -p "$pasta_systemd"
[ -d "$pasta_bin" ]     || mkdir -p "$pasta_bin"
[ -d "$pasta_ssl" ]     || mkdir -p "$pasta_ssl"


# Verifica a arquitetura.
arquitetura=$(uname -m)


# Armazena arquivos em váriaveis.
arquivo_x86_64="x86_64-qbittorrent-nox"
arquivo_aarch64="aarch64-qbittorrent-nox"
arquivo_bin=


# Descompacta arquivo .tar.xz.
function descompac_tar(){
    tar -xJf "$1"
}


# Move o arquivo qbittorrent-nox para o ~/.local do usuário.
if   [ "$arquitetura" = "x86_64" ]; then
    if [ -f "${arquivo_x86_64}.tar.xz" ]; then
        descompac_tar "${arquivo_x86_64}.tar.xz"
        chmod +x "$arquivo_x86_64"
        mv "$arquivo_x86_64" "$pasta_bin"
        arquivo_bin="$arquivo_x86_64"
    else
        echo "Arquivo ${arquivo_x86_64}.tar.xz, não existe!" ; exit 1
    fi
elif [ "$arquitetura" = "aarch64" ]; then
    if [ -f "${arquivo_aarch64}.tar.xz" ]; then
        descompac_tar "${arquivo_aarch64}.tar.xz"
        chmod +x "$arquivo_aarch64"
        mv "$arquivo_aarch64" "$pasta_bin"
        arquivo_bin="$arquivo_aarch64"
    else
        echo "Arquivo ${arquivo_aarch64}.tar.xz, não existe!" ; exit 2
    fi
fi


# Crie o arquivo do serviço
echo "[Unit]
Description=qBittorrent-nox (User Mode)
After=network.target

[Service]
Type=simple
ExecStart=${pasta_bin}/${arquivo_bin}
Restart=on-failure

[Install]
WantedBy=default.target" >> "${pasta_systemd}/qbittorrent-nox.service"


# Inicia serviço qbittorrent-nox
systemctl --user daemon-reload
systemctl --user enable qbittorrent-nox.service
systemctl --user start qbittorrent-nox.service


# Cria um certificado.
echo -e "Criando certificado..." && sleep 2
openssl req -x509 -nodes -newkey rsa:4096        \
        -keyout ${pasta_ssl}/qbittorrent-nox.key \
        -out ${pasta_ssl}/qbittorrent-nox.cert   \
        -subj "/CN=qBittorrent"
echo -e "Certificado criado!\n" && sleep 2


# Define a porta de acesso via web.
sleep 2
systemctl --user stop qbittorrent-nox.service

read -p "Defina a porta de serviço web : " porta

# Define a senha como adminadmin.
echo -e "Criando arquivo de configuração.\n\n" && sleep 2
echo -e "\
[BitTorrent]
Session\\\AddTorrentStopped=false
Session\\\Port=44718
Session\\\QueueingSystemEnabled=true
Session\\\SSL\\\Port=11389
Session\\\ShareLimitAction=Stop

[Meta]
MigrationVersion=8

[Network]
Proxy\\\HostnameLookupEnabled=false
Proxy\\\Profiles\\\BitTorrent=true
Proxy\\\Profiles\\\Misc=true
Proxy\\\Profiles\\\RSS=true

[Preferences]
MailNotification\\\req_auth=true
Web\\\Port=$porta
WebUI\\\HTTPS\\\CertificatePath=${pasta_ssl}/qbittorrent-nox.cert
WebUI\\\HTTPS\\\Enabled=true
WebUI\\\HTTPS\\\KeyPath=${pasta_ssl}/qbittorrent-nox.key
WebUI\\\Password_PBKDF2=\"@ByteArray(cjrkEmcVmY/rGCtkbKgKkA==:3EE66W4epajReEKx0/1O14miX2O0W+5x+1fs8DcDXyZPzZ7ZDqFKZFuJLxDoQYM9rf28MJQ/izfxr6nN7ArF8A==)\"
WebUI\\\Port=$porta\n" > $HOME/.config/qBittorrent/qBittorrent.conf


# Inciando servidor.
systemctl --user start qbittorrent-nox.service
systemctl --user status qbittorrent-nox.service


#=== Como desinstalar ===#
# Pare o serviço -> systemctl --user stop qbittorrent-nox.service
# Tire da inicialização -> systemctl --user disable qbittorrent-nox.service
# Remova o arquivo do daemon -> rm $HOME/.config/systemd/user/qbittorrent-nox.service
# Remova o arquivo de configuração -> rm $HOME/.config/qBittorrent/qBittorrent.conf
# Reinicia o daemon -> systemctl --user daemon-reload








