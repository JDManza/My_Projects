#!/bin/bash

set -euo pipefail

MPM_CONF="/etc/httpd/conf.modules.d/00-mpm.conf"
SATELLITE_PATTERNS="katello|foreman|pulp|candlepin|satellite"
BACKUP_DIR="/root/httpd_satellite_backups_$(date +%Y%m%d_%H%M%S)"

echo "[INFO] Starting Apache MPM and Satellite config cleanup."

# Step 1: Ensure only one MPM is enabled (default: prefork)
echo "[INFO] Checking Apache MPM configuration in $MPM_CONF..."

mkdir -p "$BACKUP_DIR"
cp "$MPM_CONF" "$BACKUP_DIR"

# Comment out all MPM modules
sed -i 's/^\(LoadModule mpm_.*_module.*\)/#\1/' "$MPM_CONF"

# Uncomment only prefork (you can change this to worker or event)
sed -i 's/^#\(LoadModule mpm_prefork_module.*\)/\1/' "$MPM_CONF"

echo "[INFO] Ensured only mpm_prefork_module is enabled."

# Step 2: Find Satellite-related Apache configs
echo "[INFO] Scanning for Satellite-related Apache configuration files..."

SAT_FILES=$(find /etc/httpd -type f -regextype posix-extended -regex ".*/.*($SATELLITE_PATTERNS).*")

if [ -z "$SAT_FILES" ]; then
    echo "[INFO] No Satellite-related config files found."
else
    echo "[INFO] Found the following Satellite-related config files:"
    echo "$SAT_FILES"
    
    echo "[INFO] Backing up and removing Satellite-related config files..."
    while IFS= read -r file; do
        mkdir -p "$BACKUP_DIR/$(dirname "$file")"
        cp "$file" "$BACKUP_DIR/$file"
        rm -f "$file"
        echo "  - Removed $file"
    done <<< "$SAT_FILES"
fi

# Step 3: Restart Apache
echo "[INFO] Restarting Apache to apply changes..."
systemctl restart httpd && echo "[SUCCESS] Apache restarted successfully."

echo "[DONE] Apache MPM cleaned and Satellite configs removed."
echo "[INFO] Backup of modified/deleted files is in: $BACKUP_DIR"
