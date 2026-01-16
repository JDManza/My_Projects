#!/bin/bash

set -euo pipefail

USERNAME="sudoer"

# Check if user exists
if id "$USERNAME" &>/dev/null; then
    echo "[INFO] User '$USERNAME' already exists. Exiting."
    exit 0
fi

# Prompt for password
while true; do
    read -s -p "Enter password for new user '$USERNAME': " PASSWORD
    echo
    read -s -p "Confirm password: " PASSWORD_CONFIRM
    echo
    [[ "$PASSWORD" == "$PASSWORD_CONFIRM" ]] && break
    echo "[ERROR] Passwords do not match. Try again."
done

# Create user and set password
useradd -m -G wheel "$USERNAME"
echo "$USERNAME:$PASSWORD" | chpasswd

echo "[INFO] User '$USERNAME' created and added to 'wheel' group (sudo access)."
