#!/bin/bash
set -e

# ==========================================================
# Script: 01-prepare-host.sh
# Deskripsi: Persiapan Host OS, Download Packages, Setup User LFS
# ==========================================================

export LFS=/mnt/lfs
echo "Mulai persiapan Host LFS di direktori: $LFS"

# 1. Membuat direktori utama
mkdir -pv $LFS
mkdir -pv $LFS/sources
chmod -v a+wt $LFS/sources

# 2. Download LFS packages menggunakan wget
echo "Mengunduh packages..."
wget --input-file=wget-list --continue --directory-prefix=$LFS/sources

# 3. Membuat struktur folder dasar
mkdir -pv $LFS/{etc,var,tools}
mkdir -pv $LFS/usr/{bin,lib,sbin}
for i in bin lib sbin; do
  ln -sv usr/$i $LFS/$i
done

# 4. Membuat User LFS
groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs
chown -v lfs $LFS/tools
chown -v lfs $LFS/sources

echo "Persiapan Host Selesai! Silakan login ke user lfs (su - lfs)."