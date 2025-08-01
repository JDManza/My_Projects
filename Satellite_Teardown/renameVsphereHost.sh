# Requires: vCenter credentials and hostname/IP, govc CLI installed on the Linux host, Network access to vCenter (port 443), hostnamectl support inside the RHEL 8 VM (default)
# Install govc if necessary with curl -L https://github.com/vmware/govmomi/releases/latest/download/govc_Linux_x86_64.tar.gz | tar -xz; sudo install govc /usr/local/bin/
# Make it executable with chmod +x rename_vm_and_host.sh

#!/bin/bash

set -euo pipefail

# Configuration for renaming
OLD_HOSTNAME=""
NEW_HOSTNAME=""

# vCenter info (set these before running or export as env vars)
VCENTER_SERVER="your-vcenter.example.com"
VCENTER_USERNAME="administrator@vsphere.local"
VCENTER_PASSWORD="your_vcenter_password"
VCENTER_DATACENTER="YourDatacenter"
VCENTER_VM_PATH="your/vm/folder/$OLD_HOSTNAME"

# GOVC env vars
export GOVC_URL="$VCENTER_SERVER"
export GOVC_USERNAME="$VCENTER_USERNAME"
export GOVC_PASSWORD="$VCENTER_PASSWORD"
export GOVC_INSECURE=1  # set to 0 if you have valid certs
export GOVC_DATACENTER="$VCENTER_DATACENTER"

log() {
    echo -e "\e[1;34m[INFO]\e[0m $1"
}

error_exit() {
    echo -e "\e[1;31m[ERROR]\e[0m $1"
    exit 1
}

### Step 1: Rename inside the guest OS
CURRENT_HOSTNAME=$(hostname)

if [[ "$CURRENT_HOSTNAME" != "$OLD_HOSTNAME" ]]; then
    error_exit "Current hostname is '$CURRENT_HOSTNAME', expected '$OLD_HOSTNAME'."
fi

log "Renaming local hostname to $NEW_HOSTNAME..."

hostnamectl set-hostname "$NEW_HOSTNAME"
echo "$NEW_HOSTNAME" > /etc/hostname
sed -i "s/\b$OLD_HOSTNAME\b/$NEW_HOSTNAME/g" /etc/hosts

if ! grep -q "$NEW_HOSTNAME" /etc/hosts; then
    IP=$(hostname -I | awk '{print $1}')
    echo "$IP    $NEW_HOSTNAME" >> /etc/hosts
    log "Added $NEW_HOSTNAME to /etc/hosts with IP $IP"
fi

### Step 2: Rename VM in vCenter
log "Renaming VM in vCenter from '$OLD_HOSTNAME' to '$NEW_HOSTNAME'..."

# Ensure govc can see the VM
VM_ID=$(govc vm.info -json "$VCENTER_VM_PATH" | jq -r '.VirtualMachines[0].Self.Value' || true)

if [[ -z "$VM_ID" ]]; then
    error_exit "VM '$VCENTER_VM_PATH' not found in vCenter."
fi

govc vm.rename "$VCENTER_VM_PATH" "$NEW_HOSTNAME"

log "VM in vCenter successfully renamed to '$NEW_HOSTNAME'."

log "✔ Hostname and VM name updated. A reboot is recommended."

# Uncomment to reboot automatically
# reboot
