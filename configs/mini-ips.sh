#!/bin/bash

# ==========================================
# System: TeknikBaik OS
# Component: Mini Intrusion Prevention System
# ==========================================

MAX_ATTEMPTS=10
TIME_WINDOW="1 hour ago"

echo "Starting Mini IPS scan for failed SSH logins..."

# Extract IPs with failed logins exceeding MAX_ATTEMPTS
BAD_IPS=$(journalctl -u sshd --since "$TIME_WINDOW" --no-pager | \
          grep "Failed password" | \
          grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | \
          sort | uniq -c | awk -v limit=$MAX_ATTEMPTS '$1 >= limit {print $2}')

if [ -z "$BAD_IPS" ]; then
    echo "Status: No suspicious activity detected."
else
    for IP in $BAD_IPS; do
        # Check if rule already exists to prevent duplicate entries
        iptables -C INPUT -s "$IP" -j DROP &> /dev/null
        if [ $? -ne 0 ]; then
            echo "Warning: IP $IP exceeded failed login limit ($MAX_ATTEMPTS times)."
            echo "Action: Applying DROP rule to firewall for IP $IP."
            iptables -I INPUT -s "$IP" -j DROP
            iptables-save > /etc/iptables.rules
            echo "Status: IP $IP successfully blocked."
        else
            echo "Info: IP $IP is already in the blocklist."
        fi
    done
fi