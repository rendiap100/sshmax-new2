#!/bin/bash

# Mendapatkan tanggal dari server
dateFromServer=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
biji=$(date +"%Y-%m-%d" -d "$dateFromServer")

# Membersihkan layar
clear

# Menghitung jumlah klien
NUMBER_OF_CLIENTS=$(grep -c -E "^#! " "/etc/xray/config.json")

if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
    clear
    echo "Anda tidak memiliki klien yang ada!"
    exit 1
fi

clear
echo "TAMPILKAN INFORMASI AKUN XRAY VMESS WS"
echo "Silakan pilih klien yang ingin ditampilkan informasinya"
echo "Tekan CTRL+C untuk kembali"
echo "==============================="
grep -E "^#! " "/etc/xray/config.json" | cut -d ' ' -f 2-3 | nl -s ') '

# Memilih klien
read -rp "Pilih klien [1-${NUMBER_OF_CLIENTS}]: " CLIENT_NUMBER

# Mendapatkan informasi klien
domain=$(cat /etc/xray/domain)
export user=$(grep -E "^#! " "/etc/xray/config.json" | cut -d ' ' -f 2 | sed -n "${CLIENT_NUMBER}"p)
export exp=$(grep -E "^#! " "/etc/xray/config.json" | cut -d ' ' -f 3 | sed -n "${CLIENT_NUMBER}"p)

# Mendapatkan UUID berdasarkan email
export uuid=$(grep -E "\"email\": \"${user}\"" "/etc/xray/config.json" | cut -d '"' -f 4)

# Menampilkan informasi akun
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\\E[40;1;37m        Informasi Akun Xray/Vmess        \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "Nama Pengguna   : ${user}"
echo -e "Domain          : ${domain}"
echo -e "ID              : ${uuid}"
echo -e "Batas Waktu     : ${exp}"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali ke menu"
menu