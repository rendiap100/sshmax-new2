#!/bin/bash

# Path ke file konfigurasi
CONFIG_FILE="/etc/xray/config.json"

# Fungsi untuk menampilkan informasi akun dari VMess
check_vmess_accounts() {
    echo "=== VMess Accounts ==="
    jq -r '.inbounds[] | select(.protocol=="vmess") | .settings.clients[] | "\(.id) - \(.email) - \(.alterId)"' $CONFIG_FILE
}

# Fungsi untuk menampilkan informasi akun dari VLESS
check_vless_accounts() {
    echo "=== VLESS Accounts ==="
    jq -r '.inbounds[] | select(.protocol=="vless") | .settings.clients[] | "\(.id) - \(.email)"' $CONFIG_FILE
}

# Fungsi untuk menampilkan informasi akun dari Trojan
check_trojan_accounts() {
    echo "=== Trojan Accounts ==="
    jq -r '.inbounds[] | select(.protocol=="trojan") | .settings.clients[] | "\(.password) - \(.email)"' $CONFIG_FILE
}

# Fungsi untuk menampilkan informasi akun dari Shadowsocks
check_shadowsocks_accounts() {
    echo "=== Shadowsocks Accounts ==="
    jq -r '.inbounds[] | select(.protocol=="shadowsocks") | .settings.clients[] | "\(.method) - \(.password)"' $CONFIG_FILE
}

# Mengecek apakah file konfigurasi ada
if [ ! -f "$CONFIG_FILE" ]; then
    echo "File konfigurasi tidak ditemukan!"
    exit 1
fi

# Menampilkan informasi akun
check_vmess_accounts
check_vless_accounts
check_trojan_accounts
check_shadowsocks_accounts
