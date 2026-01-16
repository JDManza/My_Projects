#!/bin/bash

set -euo pipefail

# Variables
OLD_HOSTNAME=$(hostname)
NEW_HOSTNAME="$1"

if [[ -z "$NEW_HOSTNAME" ]]; then
    echo "Usage: $0 new-hostname"
    exit 1
fi

echo "[INFO] Changing hostname from '$OLD_HOSTNAME' to '$NEW_HOSTNAME'..."

# Set the new hostname
hostnamectl set-hostname "$NEW_HOSTNAME"

# Update /etc/hostname
echo "$NEW_HOSTNAME" > /etc/hostname

# Update /etc/hosts
sed -i "s/\b$OLD_HOSTNAME\b/$NEW_HOSTNAME/g" /etc/hosts

# Ensure there's a local entry
if ! grep -q "$NEW_HOSTNAME" /etc/hosts; then
    IP=$(hostname -I | awk '{print $1}')
    echo "$IP    $NEW_HOSTNAME" >> /etc/hosts
    echo "[INFO] Added $NEW_HOSTNAME to /etc/hosts with IP $IP"
fi

echo "[INFO] Hostname updated. A reboot or re-login may be required to see the new prompt."
