#!/bin/bash

# File log yang akan dibaca
log_file="/etc/user-create/user.log"

# Mengecek apakah file log ada
if [ ! -f "$log_file" ]; then
  echo "File log tidak ditemukan: $log_file"
  exit 1
fi

# Membuat header untuk daftar client
echo "---------------------------------------------------------"
echo "Daftar Client dari $log_file"
echo "---------------------------------------------------------"
echo -e "No\tClient"

# Inisialisasi counter
count=1

# Membaca file log dan menampilkan daftar client
while read -r line; do
  # Misalnya format user.log: user | tanggal | status
  client=$(echo "$line" | awk '{print $1}')

  # Menampilkan hasil
  echo -e "$count\t$client"

  # Increment counter
  count=$((count + 1))
done < "$log_file"

echo "---------------------------------------------------------"
echo "Total Clients: $((count - 1))"
