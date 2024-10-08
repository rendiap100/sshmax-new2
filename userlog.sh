#!/bin/bash

# File log yang akan dibaca
log_file="/etc/user-create/user.log"

# Mengecek apakah file log ada
if [ ! -f "$log_file" ]; then
  echo "File log tidak ditemukan: $log_file"
  exit 1
fi

# Membuat header untuk daftar user
echo "---------------------------------------------------------"
echo "Daftar User dari $log_file"
echo "---------------------------------------------------------"
echo -e "No\tUser\t\tTanggal Pembuatan\tStatus"

# Inisialisasi counter
count=1

# Membaca file log dan menampilkan daftar
while read -r line; do
  # Misalnya format user.log: user | tanggal | status
  user=$(echo "$line" | awk '{print $1}')
  tanggal=$(echo "$line" | awk '{print $2}')
  status=$(echo "$line" | awk '{print $3}')

  # Menampilkan hasil
  echo -e "$count\t$user\t\t$tanggal\t\t$status"

  # Increment counter
  count=$((count + 1))
done < "$log_file"

echo "---------------------------------------------------------"
echo "Total Users: $((count - 1))"
