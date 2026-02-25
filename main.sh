#!/bin/bash

# Criador : LUCIANO PEREIRA DE SOUZA
# Finalidade : Criar um servidor de torrents.

#=== Instruções ===#
# Como instalar : bash main.sh
# Como acesar : No navegador digite o IP do servidor e a porta
# Exemplo : 192.168.0.10:8080
# Login Padrão : admin
# Senha Padrão : adminadmin

versao="2.0"

if [ "$1" = "-V" -o "$1" = "--version" ]; then
    echo "Versão : ${versao}."
    exit 10
fi


# Testa se o usuário é root.
usuario="$(whoami)"
if [ "$usuario" != "root" ]; then
    echo "Usuário $usuario não é root!"
    echo "Tente \"sudo -i\" ou \"su - root\""
    exit 20
fi


# Cria as pastas, caso não existam.
pasta_systemd="/etc/systemd/system"
pasta_bin="/usr/local/bin"
pasta_ssl="/etc/ssl/qbittorrent-nox"
pasta_config="$HOME/.config/qBittorrent"
pasta_local="$HOME/.local/share/"
[ -d "$pasta_systemd" ]  || mkdir -p "$pasta_systemd"
[ -d "$pasta_bin" ]      || mkdir -p "$pasta_bin"
[ -d "$pasta_ssl" ]      || mkdir -p "$pasta_ssl"
[ -d "$pasta_config" ]   || mkdir -p "$pasta_config"
[ -d "$pasta_local" ]   || mkdir -p "$pasta_local"


# Cria grupo de torrents caso não exista.
comando="$(cut -d: -f1 /etc/group | grep torrents)"
if [ "$comando" != "torrents" ]; then
    groupadd torrents
fi

echo "#=== Instalando Servidor de Torrents ===#" ; sleep 2.5

echo -e "\nFoi criado um grupo de 'torrents'."
echo -e "Lembre-se de adicionar seu usuário do SAMBA no grupo 'torrents'."
echo -e "\tCaso tenha o SAMBA instalado!"

# Definição de segurança.
definicao_umask=0007
while true; do
    echo -e "\n\n#=== Definindo o nível de segurança dos arquivos. ===#"
    echo "1. Usuário que não está no grupo 'torrents', pode ver e copiar arquivos."
    echo "2. Usuário que não está no grupo 'torrents', não pode ver nada."
    echo
    read -p "Escolha uma definição de segurança : " seguranca

    if   [ "$seguranca" = "1" ]; then
        echo "Mais flexível"
        definicao_umask=0002
        sleep 1
        break
    elif [ "$seguranca" = "2" ]; then
        echo "Mais seguro"
        sleep 1
        definicao_umask=0007
        break
    else
        echo "Opção inválida!" ; sleep 3
    fi
done


# Armazena a arquitetura.
arquitetura=$(uname -m)


# Armazena arquivos em váriaveis.
arquivo_x86_64=$(realpath  $(find . -type f -name \
    "*x86_64-qbittorrent-nox.tar.xz" ) 2> /dev/null)
arquivo_aarch64=$(realpath $(find . -type f -name \
    "*aarch64-qbittorrent-nox.tar.xz") 2> /dev/null)
arquivo_bin=


# Descompacta arquivo .tar.xz.
function descompac_tar(){
    tar -xJvf "$1" -C "$2"
}


# Move o arquivo qbittorrent-nox para o ~/.local do usuário.
echo -e "\n\nVerificando arquivos compactados." ; sleep 1
if   [ "$arquitetura" = "x86_64" ]; then
    if [ -f "${arquivo_x86_64}" ]; then
        descompac_tar "${arquivo_x86_64}" "$(dirname "${arquivo_x86_64}")"
        chmod +x "${arquivo_x86_64%%.*}"
        mv "${arquivo_x86_64%%.*}" "$pasta_bin"
        arquivo_bin="x86_64-qbittorrent-nox"
    else
        echo "Arquivo ${arquivo_x86_64}, não existe!" ; exit 1
    fi
elif [ "$arquitetura" = "aarch64" ]; then
    if [ -f "${arquivo_aarch64}" ]; then
        echo "$arquivo_aarch64"
        descompac_tar "${arquivo_aarch64}" "$(dirname "${arquivo_aarch64}")"
        chmod +x "${arquivo_aarch64%%.*}"
        mv "${arquivo_aarch64%%.*}" "$pasta_bin"
        arquivo_bin="aarch64-qbittorrent-nox"
    else
        echo "Arquivo ${arquivo_aarch64}, não existe!" ; exit 2
    fi
fi


# Crie o arquivo do serviço
echo -e "\n\nCriando arquivo systemd." ; sleep 1
echo "[Unit]
Description=Servidor de torrents (qBittorrent-nox)
After=network.target

[Service]
UMask=$definicao_umask
Group=torrents
Type=simple
ExecStart=${pasta_bin}/${arquivo_bin}
Restart=on-failure

[Install]
WantedBy=default.target" > "${pasta_systemd}/qbittorrent-nox.service"


# Inicia serviço qbittorrent-nox
systemctl daemon-reload
systemctl enable qbittorrent-nox.service
systemctl start qbittorrent-nox.service


# Cria um certificado.
echo -e "Criando certificado..." && sleep 1
openssl req -x509 -nodes -newkey rsa:4096        \
        -keyout ${pasta_ssl}/qbittorrent-nox.key \
        -out ${pasta_ssl}/qbittorrent-nox.cert   \
        -subj "/CN=qBittorrent"
echo -e "Certificado criado!" && sleep 2


# Define a porta de acesso via web.
systemctl stop qbittorrent-nox.service ; sleep 1

echo -e "\n#=== Definindo porta de serviço web ===#"
read -p "Defina a porta de serviço web : " porta_web

# Define a senha como adminadmin.
echo -e "\nCriando arquivo de configuração." && sleep 2
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
Web\\\Port=$porta_web
WebUI\\\HTTPS\\\CertificatePath=${pasta_ssl}/qbittorrent-nox.cert
WebUI\\\HTTPS\\\Enabled=true
WebUI\\\HTTPS\\\KeyPath=${pasta_ssl}/qbittorrent-nox.key
WebUI\\\Password_PBKDF2=\"@ByteArray(cjrkEmcVmY/rGCtkbKgKkA==:3EE66W4epajReEKx0/1O14miX2O0W+5x+1fs8DcDXyZPzZ7ZDqFKZFuJLxDoQYM9rf28MJQ/izfxr6nN7ArF8A==)\"
WebUI\\\Port=$porta_web\n" > $pasta_config/qBittorrent.conf


# Inciando servidor.
echo -e "\n\nAtivando os serviços." ; sleep 1
systemctl start qbittorrent-nox.service
systemctl status qbittorrent-nox.service


#=== Como desinstalar ===#
# Pare o serviço -> systemctl stop qbittorrent-nox.service
# Tire da inicialização -> systemctl disable qbittorrent-nox.service
# Remova o arquivo do systemd -> rm /etc/systemd/system/qbittorrent-nox.service
# Remova o arquivo de configuração -> rm /root/.config/qBittorrent/qBittorrent.conf
# Reinicia o daemon -> systemctl daemon-reload
