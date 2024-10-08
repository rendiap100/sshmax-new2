#!/bin/bash

# File log yang akan dibaca
log_file="/etc/user-create/user.log"

# Mengecek apakah file log ada
if [ ! -f "$log_file" ]; then
  echo "File log tidak ditemukan: $log_file"
  exit 1
fi

# Membaca semua client dari file log
clients=()
while read -r line; do
  # Misalnya format user.log: user | domain | uuid | port_tls | port_ntls | path | serviceName | batas_ip | batas_kuota | aktif_selama | tanggal_dibuat | tanggal_exp
  clients+=("$line")
done < "$log_file"

# Menampilkan daftar nama client
echo "Daftar nama client VMess:"
for i in "${!clients[@]}"; do
  user=$(echo "${clients[$i]}" | awk '{print $2}')
  echo "$i) $user"
done

read -p "Masukkan nomor client VMess yang ingin ditampilkan: " client_choice

# Menampilkan informasi untuk client yang dipilih
if [[ "$client_choice" =~ ^[0-9]+$ ]] && [ "$client_choice" -ge 0 ] && [ "$client_choice" -lt "${#clients[@]}" ]; then
  selected_client="${clients[$client_choice]}"
  
  # Ekstrak informasi dari baris yang dipilih
  domain=$(echo "$selected_client" | awk '{print $1}')
  user=$(echo "$selected_client" | awk '{print $2}')
  uuid=$(echo "$selected_client" | awk '{print $3}')
  port_tls=$(echo "$selected_client" | awk '{print $4}')
  port_ntls=$(echo "$selected_client" | awk '{print $5}')
  path=$(echo "$selected_client" | awk '{print $6}')
  serviceName=$(echo "$selected_client" | awk '{print $7}')
  batas_ip=$(echo "$selected_client" | awk '{print $8}')
  batas_kuota=$(echo "$selected_client" | awk '{print $9}')
  aktif_selama=$(echo "$selected_client" | awk '{print $10}')
  tanggal_dibuat=$(echo "$selected_client" | awk '{print $11}')
  tanggal_exp=$(echo "$selected_client" | awk '{print $12}')

  # Menampilkan informasi akun
  echo -e "\n◈━━━━━◈◈━━━━━◈"
  echo "» INFORMASI AKUN «"
  echo "◈━━━━━◈◈━━━━━◈"
  echo "» Domain     : $domain"
  echo "» Pengguna   : $user"
  echo "◈━━━━━◈◈━━━━━◈"
  echo "» Port TLS   : $port_tls"
  echo "» Port NTLS  : $port_ntls"
  echo "» UUID       : $uuid"
  echo "» Path       : $path"
  echo "» ServiceName: $serviceName"
  echo "◈━━━━━◈◈━━━━━◈"

  # Menampilkan informasi VMess
  echo "» VMess TLS"
  echo "◈━━━━━◈◈━━━━━◈"
  echo "vmess://$(echo -n "$uuid@$domain:$port_tls#${user}" | base64)"

  echo "◈━━━━━◈◈━━━━━◈"
  echo "» VMess NTLS"
  echo "◈━━━━━◈◈━━━━━◈"
  echo "vmess://$(echo -n "$uuid@$domain:80#${user}" | base64)"

  echo "◈━━━━━━━━◈◈━━━━━━━━◈"
  echo "» Batas Ip    : $batas_ip"
  echo "» Batas Kuota : $batas_kuota"
  echo "» Aktif Selama: $aktif_selama"
  echo "» Tanggal Dibuat: $tanggal_dibuat"
  echo "» Tanggal Exp : $tanggal_exp"
  echo "◈━━━━━━━━◈◈━━━━━━━━◈"
else
  echo "Pilihan tidak valid."
fi
