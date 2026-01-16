#!/bin/bash

# Usage: ./set_static_ip_if_disconnected.sh <interface> <static_ip>/<cidr>

IFACE="$1"
STATIC_IP="$2"

# Check if both arguments are provided
if [[ -z "$IFACE" || -z "$STATIC_IP" ]]; then
  echo "Usage: $0 <interface> <static_ip>/<cidr>"
  exit 1
fi

# Validate IP/CIDR Schema from input
if ! [[ "$STATIC_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$ ]]; then
    echo "[ERROR] Static IP must be in valid CIDR format (e.g., 192.168.1.100/24)"
    exit 1
fi

# Validate that each octet <= 255
IFS=/ read IP CIDR <<< "$STATIC_IP"
IFS=. read -r o1 o2 o3 o4 <<< "$IP"
for octet in "$o1" "$o2" "$o3" "$o4"; do
    if (( octet < 0 || octet > 255)); then
        echo "[ERROR] Invalid IP address: octet $octet out of range"
        exit 1
    fi
done

# Check if interface exists
if ! ip link show "$IFACE" &>/dev/null; then
  echo "Error: Interface '$IFACE' does not exist."
  exit 1
fi

# Check if interface has an IP
HAS_IP=$(ip -o -4 addr show "$IFACE" | awk '{print $4}')
if [[ -n "$HAS_IP" ]]; then
  echo "Interface '$IFACE' already has IP address: $HAS_IP"
  exit 0
fi

# Check if interface is down or disconnected (for Ethernet, 'state DOWN' means no cable)
STATE=$(cat /sys/class/net/"$IFACE"/operstate)

if [[ "$STATE" != "up" ]]; then
  echo "Interface '$IFACE' is disconnected or down (state: $STATE). Setting static IP $STATIC_IP."
  sudo ip addr add "$STATIC_IP" dev "$IFACE"
  sudo ip link set "$IFACE" up
  echo "Static IP $STATIC_IP set on $IFACE."
else
  echo "Interface '$IFACE' is connected. No action taken."
fi
