#!/bin/bash

# 1. Reset account passwords to default values for public distribution
echo "root:root" | chpasswd
echo "posadmin:posadmin" | chpasswd

# 2. Remove WireGuard configurations and keys
rm -rf /etc/wireguard/*
systemctl disable wg-quick@wg0

# 3. Clear Cloudflare Tunnel token value
sed -i 's/Environment="TUNNEL_TOKEN=.*"/Environment="TUNNEL_TOKEN="/g' /etc/systemd/system/cloudflared.service

# 4. Remove unique SSH server host keys and user authorized keys
rm -f /etc/ssh/ssh_host_*
rm -f /root/.ssh/authorized_keys
rm -f /home/posadmin/.ssh/authorized_keys

# 5. Clear log files without deleting the parent directories
find /var/log -type f -exec truncate -s 0 {} \;

# 6. Clear unique machine identification numbers
truncate -s 0 /etc/machine-id
truncate -s 0 /var/lib/dbus/machine-id

# 7. Clean all temporary system files
rm -rf /tmp/* /var/tmp/*

# 8. Remove this cleanup script itself
rm -f /root/cleanup.sh

# 9. Clear terminal command history for all users
rm -f /root/.bash_history
rm -f /home/posadmin/.bash_history
history -c
unset HISTFILE

# 10. Power off the machine immediately to preserve the clean state
poweroff