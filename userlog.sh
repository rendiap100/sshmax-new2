#!/bin/bash

# File log yang akan dibaca
log_file="/etc/user-create/user.log"

# Mengecek apakah file log ada
if [ ! -f "$log_file" ]; then
  echo "File log tidak ditemukan: $log_file"
  exit 1
fi

# Menampilkan log yang sudah diurutkan berdasarkan nama client (misalkan nama client ada di kolom kedua)
echo "Log yang disusun berdasarkan nama client:"
sort -k2 "$log_file"
