#!/bin/bash

Green="\e[92;1m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[36m"
FONT="\033[0m"
OK="${Green}  »${FONT}"
ERROR="${RED}[ERROR]${FONT}"
green='\e[0;32m'
NC='\e[0m'

# ----- Clear screen -----
clear

# ----- Detect Environment -----
source /etc/os-release
ARCH=$(uname -m)
IP=$(curl -sS icanhazip.com)

# ----- Banner -----
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  » This Will Quick Setup VPN Server On Your Server"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
sleep 2

# ----- Check Architecture -----
if [[ "$ARCH" != "x86_64" ]]; then
    echo -e "${ERROR} Architecture not supported: ${YELLOW}$ARCH${NC}"
    exit 1
fi
print_success() {
    [[ 0 -eq $? ]] && echo -e "${green} ✔ $1 ${NC}" && sleep 1
}
echo -e "${OK} Architecture Supported: ${green}$ARCH${NC}"

# ----- Check OS -----
case $ID in
    ubuntu|debian)
        echo -e "${OK} OS Supported: ${green}${PRETTY_NAME}${NC}"
        ;;
    *)
        echo -e "${ERROR} Unsupported OS: ${YELLOW}${PRETTY_NAME}${NC}"
        exit 1
        ;;
esac

# ----- Check IP -----
if [[ -z "$IP" ]]; then
    echo -e "${ERROR} IP Address Not Detected"
    exit 1
else
    echo -e "${OK} IP Address Detected: ${green}$IP${NC}"
fi

# ----- Root Check -----
if [[ $EUID -ne 0 ]]; then
    echo -e "${ERROR} Run script as root"
    exit 1
fi

# ----- Virtualization Check -----
if [[ $(systemd-detect-virt) == "openvz" ]]; then
    echo -e "${ERROR} OpenVZ is not supported"
    exit 1
fi

# ----- Begin Installation Timer -----
start=$(date +%s)

# ----- Function: Setup Environment -----
function setup_environment() {
    echo -e "${OK} Setting up environment..."
    timedatectl set-timezone Asia/Jakarta
    echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
    echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections

    # Update and install base packages
    apt update -y && apt upgrade -y && apt dist-upgrade -y
    apt install -y sudo zip unzip curl wget lsof htop screen gnupg bash-completion ca-certificates cron iptables iptables-persistent net-tools software-properties-common ruby figlet
    gem install lolcat
    print_success "Environment setup complete"
}

# ----- Function: Create Directories -----
function make_directories() {
    echo -e "${OK} Creating necessary directories..."
    mkdir -p /etc/{xray,vmess,vless,trojan,shadowsocks,ssh,bot}
    mkdir -p /var/log/xray /usr/bin/xray /etc/kyt/limit/{vmess,ssh,vless,trojan}/ip /etc/limit/{vmess,ssh,vless,trojan} /etc/user-create
    touch /etc/xray/domain /etc/xray/ipvps
    touch /var/log/xray/access.log /var/log/xray/error.log
    print_success "Directory creation complete"
}

# ----- Function: Setup Domain -----
pasang_domain() {
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e " SETUP DOMAIN CLOUDFLARE"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e " 1) Gunakan Domain Sendiri"
    echo -e " 2) Gunakan Domain Random"
    read -t 10 -p " Pilih Opsi Domain [1-2] (default: 2): " domain_choice
    domain_choice=${domain_choice:-2}

    if [[ "$domain_choice" == "1" ]]; then
        read -p " Masukkan domain Anda: " user_domain
        echo "$user_domain" > /etc/xray/domain
        echo "$user_domain" > /root/domain
    else
        REPO="https://raw.githubusercontent.com/rendiap100/sshmax-new2/main/"
        wget -q ${REPO}files/cf.sh -O cf.sh && chmod +x cf.sh && ./cf.sh && rm -f cf.sh
    fi
    print_success "Domain setup complete"
}

# ----- Function: Install SSL -----
pasang_ssl() {
    echo -e "${OK} Memasang SSL..."
    rm -f /etc/xray/xray.key /etc/xray/xray.crt
    domain=$(cat /etc/xray/domain)
    systemctl stop nginx
    curl -s https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh
    chmod +x /root/.acme.sh/acme.sh
    /root/.acme.sh/acme.sh --upgrade --auto-upgrade
    /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    /root/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256
    ~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc
    chmod 600 /etc/xray/xray.key /etc/xray/xray.crt
    print_success "SSL installation complete"
}

# ----- Function: Install Xray -----
install_xray() {
    echo -e "${OK} Menginstall Xray versi terbaru..."
    domainSock_dir="/run/xray"
    mkdir -p $domainSock_dir && chown www-data:www-data $domainSock_dir

    # Fetch latest version number
    latest_version=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | grep tag_name | cut -d '"' -f4 | sed 's/^v//')

    # Download and install latest version using Xray install script
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u www-data --version "$latest_version"

    REPO="https://raw.githubusercontent.com/rendiap100/sshmax-new2/main/"
    wget -qO /etc/xray/config.json "${REPO}config/config.json"
    wget -qO /etc/systemd/system/xray.service "${REPO}files/xray.service"
    systemctl daemon-reexec
    systemctl enable xray
    print_success "Xray versi $latest_version berhasil diinstal"
}

# ----- Function: Install SSH, Dropbear, OpenVPN -----
install_ssh_stack() {
    echo -e "${OK} Menginstall SSH, Dropbear & OpenVPN..."
    apt install -y dropbear openvpn easy-rsa
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
    echo "Port 22" >> /etc/ssh/sshd_config
    echo "/bin/false" >> /etc/shells
    echo "/usr/sbin/nologin" >> /etc/shells
    wget -qO /etc/default/dropbear https://raw.githubusercontent.com/rendiap100/sshmax-new2/main/config/dropbear.conf
    wget -qO - https://raw.githubusercontent.com/rendiap100/sshmax-new2/main/files/openvpn | bash -
    systemctl restart ssh
    systemctl restart dropbear
    systemctl restart openvpn
    print_success "SSH stack installed"
}

# ----- Function: Install UDP Limit Tools -----
install_udp_limit() {
    echo -e "${OK} Menginstall UDP limit dan quota tools..."
    REPO="https://raw.githubusercontent.com/rendiap100/sshmax-new2/main/"
    wget -q -O /usr/local/kyt/udp-mini "${REPO}files/udp-mini"
    chmod +x /usr/local/kyt/udp-mini
    for i in 1 2 3; do
        wget -q -O /etc/systemd/system/udp-mini-$i.service "${REPO}files/udp-mini-$i.service"
        systemctl enable --now udp-mini-$i
    done
    print_success "UDP limiter aktif"
}

# ----- Function: Install SlowDNS & ePro -----
install_slowdns_epro() {
    echo -e "${OK} Menginstall SlowDNS & ePro WebSocket..."
    REPO="https://raw.githubusercontent.com/rendiap100/sshmax-new2/main/"
    wget -q -O /tmp/nameserver "${REPO}files/nameserver" && chmod +x /tmp/nameserver && bash /tmp/nameserver
    wget -O /usr/bin/ws "${REPO}files/ws" && chmod +x /usr/bin/ws
    wget -O /etc/systemd/system/ws.service "${REPO}files/ws.service"
    systemctl enable --now ws
    print_success "SlowDNS dan ePro aktif"
}

# ----- Function: Install Menu & Cronjobs -----
setup_menu_and_cron() {
    echo -e "${OK} Mengatur Menu dan Cronjob..."
    REPO="https://raw.githubusercontent.com/rendiap100/sshmax-new2/main/"
    wget -q ${REPO}menu/menu.zip -O menu.zip
    unzip -o menu.zip -d /usr/local/sbin
    chmod +x /usr/local/sbin/*
    rm -rf menu.zip

    cat >/etc/cron.d/xp_all <<EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
2 0 * * * root /usr/local/sbin/xp
EOF

    cat >/etc/cron.d/logclean <<EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/20 * * * * root /usr/local/sbin/clearlog
EOF

    cat >/etc/cron.d/daily_reboot <<EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 3 * * * root /sbin/reboot
EOF

    cat >/etc/profile.d/menu.sh <<EOF
#!/bin/sh
[ -x /usr/local/sbin/menu ] && /usr/local/sbin/menu
EOF
    chmod +x /etc/profile.d/menu.sh
    print_success "Menu & Cronjob aktif"
}

# ----- Function: Install Backup Tools & Swap -----
install_backup_and_swap() {
    echo -e "${OK} Menginstal Backup Tools dan Swap..."
    apt install -y rclone msmtp-mta bsd-mailx
    mkdir -p /root/.config/rclone
    wget -qO /root/.config/rclone/rclone.conf https://raw.githubusercontent.com/rendiap100/sshmax-new2/main/config/rclone.conf
    echo -e "${OK} Rclone konfigurasi siap"

    # Setup 1G Swap
    dd if=/dev/zero of=/swapfile bs=1M count=1024
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    print_success "Swap 1G aktif"

    # Install Gotop (Monitoring)
    ver=$(curl -s https://api.github.com/repos/xxxserxxx/gotop/releases/latest | grep tag_name | cut -d '"' -f4)
    wget -qO gotop.deb https://github.com/xxxserxxx/gotop/releases/download/${ver}/gotop_${ver}_linux_amd64.deb
    dpkg -i gotop.deb
    rm -f gotop.deb
    print_success "Monitoring (gotop) siap"
}

# ----- Function: Finish Setup -----
finish_setup() {
    echo -e "${OK} Finalizing setup..."
    secs=$(( $(date +%s) - start ))
    echo -e "${green} Installation completed in $(($secs / 60))m $(($secs % 60))s${NC}"
    echo -e "${green} Server will reboot... ${NC}"
    sleep 3
    reboot
}

# ================================
#  MAIN EXECUTION
# ================================
setup_environment
make_directories
pasang_domain
pasang_ssl
install_xray
install_ssh_stack
install_udp_limit
install_slowdns_epro
setup_menu_and_cron
install_backup_and_swap
finish_setup
