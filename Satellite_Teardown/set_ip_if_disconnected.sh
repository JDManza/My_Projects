#!/bin/bash

# Usage: ./set_static_ip_if_disconnected.sh <interface> <static_ip>/<cidr>

IFACE="$1"
STATIC_IP="$2"

# Check if both arguments are provided
if [[ -z "$IFACE" || -z "$STATIC_IP" ]]; then
  echo "Usage: $0 <interface> <static_ip>/<cidr>"
  exit 1
fi

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
