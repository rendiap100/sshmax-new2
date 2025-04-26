#!/bin/bash

# Warna
Green="\e[92;1m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[36m"
FONT="\033[0m"
OK="${Green}  »${FONT}"
ERROR="${RED}[ERROR]${FONT}"
NC='\e[0m'
green='\e[0;32m'

# IP & Repo
export IP=$(curl -sS icanhazip.com)
REPO="https://raw.githubusercontent.com/rendiap100/sshmax-new2/main/"

clear

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  » Quick Minimal VPN Setup"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
sleep 2

if [ "${EUID}" -ne 0 ]; then
    echo -e "${ERROR} Jalankan script sebagai root"
    exit 1
fi

# ------------------------------
function first_setup() {
    timedatectl set-timezone Asia/Jakarta
    echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
    echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
}

function nginx_install() {
    apt-get install nginx -y
}

function base_package() {
    apt update -y
    DEBIAN_FRONTEND=noninteractive apt install -y \
        zip unzip curl sudo figlet wget \
        iptables iptables-persistent netfilter-persistent
}

function make_folder_xray() {
    mkdir -p /etc/xray /var/log/xray /var/lib/kyt
    touch /etc/xray/domain /var/log/xray/access.log /var/log/xray/error.log
}

function pasang_domain() {
    echo -e "\n[1] Domain Pribadi\n[2] Domain Bawaan"
    read -t 10 -p "Pilih jenis domain [default: 2]: " host
    host=${host:-2}
    if [[ $host == "1" ]]; then
        read -p "Masukkan domain anda: " host1
        echo "$host1" > /etc/xray/domain
        echo "$host1" > /root/domain
    else
        wget ${REPO}files/cf.sh && chmod +x cf.sh && ./cf.sh && rm -f cf.sh
    fi
}

function pasang_ssl() {
    domain=$(cat /root/domain)
    STOPWEBSERVER=$(lsof -i:80 | awk 'NR==2 {print $1}')
    systemctl stop $STOPWEBSERVER 2>/dev/null
    systemctl stop nginx
    curl https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh
    chmod +x /root/.acme.sh/acme.sh
    /root/.acme.sh/acme.sh --upgrade --auto-upgrade
    /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    /root/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256
    /root/.acme.sh/acme.sh --installcert -d $domain \
        --fullchainpath /etc/xray/xray.crt \
        --keypath /etc/xray/xray.key --ecc
    chmod 600 /etc/xray/xray.key
}

function install_xray() {
    bash -c "$(curl -Ls https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh)" @ install -u www-data
    wget -O /etc/xray/config.json "${REPO}config/config.json"
    wget -O /etc/nginx/conf.d/xray.conf "${REPO}config/xray.conf"
    domain=$(cat /etc/xray/domain)
    sed -i "s/xxx/${domain}/g" /etc/nginx/conf.d/xray.conf
}

function menu() {
    wget ${REPO}menu/menu.zip
    unzip -o menu.zip -d /usr/local/sbin
    chmod +x /usr/local/sbin/*
    rm -f menu.zip
}

function profile() {
    echo -e '#!/bin/bash\nmenu' > /root/.profile
    chmod +x /root/.profile
    echo "0 3 * * * root /sbin/reboot" > /etc/cron.d/daily_reboot
    echo "*/1 * * * * root echo -n > /var/log/xray/access.log" > /etc/cron.d/log.xray
    service cron restart
}

function enable_services() {
    systemctl daemon-reload
    systemctl enable nginx xray cron rc-local netfilter-persistent
    systemctl restart nginx xray cron
}

function ins_backup() {
    apt install rclone -y
    printf "q\n" | rclone config
    mkdir -p /root/.config/rclone
    wget -O /root/.config/rclone/rclone.conf "${REPO}config/rclone.conf"
    echo "Rclone backup diaktifkan"
}

function instal() {
    first_setup
    nginx_install
    base_package
    make_folder_xray
    pasang_domain
    pasang_ssl
    install_xray
    ins_backup
    menu
    profile
    enable_services
}

instal

echo -e "${green} Setup Selesai.${NC}"
read -p "Tekan Enter untuk reboot..."
reboot
