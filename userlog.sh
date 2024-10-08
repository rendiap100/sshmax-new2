#!/bin/bash

# File log yang akan dibaca
log_file="/etc/user-create/user.log"

# Mengecek apakah file log ada
if [ ! -f "$log_file" ]; then
  echo "File log tidak ditemukan: $log_file"
  exit 1
fi

# Membuat header untuk daftar pengguna
echo "-------------------------------------"
echo "Daftar Pengguna dari $log_file"
echo "-------------------------------------"
printf "%-5s %-20s\n" "No" "Nama Pengguna"

# Inisialisasi counter
count=1

# Membaca file log dan menampilkan daftar pengguna (misalnya nama pengguna ada di kolom ke-2)
while read -r line; do
  # Ekstrak kolom kedua sebagai nama pengguna
  user=$(echo "$line" | awk '{print $2}')

  # Menampilkan hasil jika kolom user tidak kosong
  if [ ! -z "$user" ]; then
    printf "%-5s %-20s\n" "$count" "$user"
    count=$((count + 1))
  fi
done < "$log_file"

echo "-------------------------------------"
echo "Total Pengguna: $((count - 1))"
