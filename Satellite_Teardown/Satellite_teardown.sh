#!/bin/bash

set -euo pipefail

# Function to log output
log() {
    echo -e "\e[1;34m[INFO]\e[0m $1"
}

# 1. Uninstall Satellite and dependencies
log "Stopping Satellite services..."
satellite-installer --stop-services || true

log "Removing Satellite packages..."
yum remove -y satellite\* foreman\* katello\* candlepin\* pulp\* || true

log "Removing leftover configs..."
rm -rf /etc/foreman /etc/katello /etc/pulp /var/lib/pulp /var/lib/mongodb /var/lib/pgsql /etc/httpd/conf.d/05-foreman* \
       /etc/httpd/conf.d/05-katello* /etc/puppetlabs /opt/theforeman /opt/puppetlabs /root/ssl-build \
       /etc/candlepin /var/lib/candlepin /etc/tomcat /var/lib/tomcats /etc/sysconfig/katello /etc/sysconfig/foreman \
       /etc/systemd/system/katello* /etc/systemd/system/foreman* /etc/systemd/system/pulp* /var/www/html/pub

# 2. Create repo directory
REPO_DIR="/data1/repo_rhel"
log "Ensuring $REPO_DIR exists..."
mkdir -p "$REPO_DIR"

# 3. Set SELinux context for Apache to access repo directory
log "Configuring SELinux for $REPO_DIR..."
semanage fcontext -a -t httpd_sys_content_t "${REPO_DIR}(/.*)?"
restorecon -Rv "$REPO_DIR"

# 4. Create symlink to Apache web root
WEB_LINK="/var/www/html/repo_rhel"
if [[ -L "$WEB_LINK" || -e "$WEB_LINK" ]]; then
    log "Removing existing $WEB_LINK"
    rm -rf "$WEB_LINK"
fi

log "Creating symbolic link $WEB_LINK -> $REPO_DIR"
ln -s "$REPO_DIR" "$WEB_LINK"

# 5. Modify httpd.conf to ensure access
HTTPD_CONF="/etc/httpd/conf/httpd.conf"

log "Updating $HTTPD_CONF to ensure directory access..."

# Ensure there is a <Directory /data1/repo_rhel> block with correct settings
grep -q "<Directory \"$REPO_DIR\">" "$HTTPD_CONF" || {
    cat <<EOF >> "$HTTPD_CONF"

<Directory "$REPO_DIR">
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>
EOF
}

# Ensure /var/www/html also allows access to symlink
grep -q "<Directory \"/var/www/html\">" "$HTTPD_CONF" || {
    cat <<EOF >> "$HTTPD_CONF"

<Directory "/var/www/html">
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>
EOF
}

log "Restarting httpd..."
systemctl restart httpd
systemctl enable httpd

log "Opening firewall for HTTP..."
firewall-cmd --permanent --add-service=http
firewall-cmd --reload

log "Done. /data1/repo_rhel is now web-accessible at http://<server-ip>/repo_rhel/"
