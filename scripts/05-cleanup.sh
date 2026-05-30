#!/bin/bash

# 1. Menghapus konfigurasi dan kunci VPN WireGuard
rm -rf /etc/wireguard/*
systemctl disable wg-quick@wg0

# 2. Menghapus Token Cloudflare (Mengosongkan nilai di dalam tanda kutip)
sed -i 's/Environment="TUNNEL_TOKEN=.*"/Environment="TUNNEL_TOKEN="/g' /etc/systemd/system/cloudflared.service

# 3. Menghapus kunci unik SSH Server
rm -f /etc/ssh/ssh_host_*

# 4. Mengosongkan isi file log tanpa menghapus direktori
find /var/log -type f -exec truncate -s 0 {} \;

# 5. Mengosongkan ID unik mesin
truncate -s 0 /etc/machine-id
truncate -s 0 /var/lib/dbus/machine-id

# 6. Membersihkan seluruh file sementara
rm -rf /tmp/* /var/tmp/*

# 7. Menghapus skrip ini sendiri agar tidak terbaca oleh penerima file
rm -f /root/cleanup.sh

# 8. Membersihkan riwayat perintah terminal
rm -f /root/.bash_history
history -c
unset HISTFILE

# Mematikan mesin secara langsung
poweroff