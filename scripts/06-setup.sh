#!/bin/bash

# 1. Regenerate unique SSH host cryptographic keys
ssh-keygen -A
systemctl restart sshd

# 2. Enable IP Forwarding routing capability within the kernel
sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

# 3. Reconfigure Iptables firewall policies and rules
iptables -F
iptables -P INPUT DROP
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -p udp --dport 51820 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -i wg0 -p tcp --dport 22 -j ACCEPT
iptables-save > /etc/iptables.rules
iptables-save > /etc/iptables.rules

# 4. Generate new WireGuard VPN cryptographic key pair
mkdir -p /etc/wireguard/
cd /etc/wireguard/
wg genkey | tee privatekey | wg pubkey > publickey
PRIV_KEY=$(cat privatekey)

cat <<EOF > /etc/wireguard/wg0.conf
[Interface]
PrivateKey = $PRIV_KEY
Address = 10.0.0.1/24
ListenPort = 51820
EOF
systemctl enable --now wg-quick@wg0

# 5. Integrate and initialize Cloudflare Tunnel configuration
echo "Please input your Cloudflare Tunnel Token and press Enter:"
read CF_TOKEN
sed -i "s|Environment=\"TUNNEL_TOKEN=.*\"|Environment=\"TUNNEL_TOKEN=$CF_TOKEN\"|g" /etc/systemd/system/cloudflared.service
systemctl daemon-reload
systemctl enable --now cloudflared
systemctl restart cloudflared