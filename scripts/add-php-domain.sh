#!/bin/bash

# Ensure the script is run with sudo or as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Usage: ./add_domain.sh domain.com /var/www/path/to/project

# Check if the script is run with two arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 domain.com /var/www/path/to/project"
    exit 1
fi

DOMAIN=$1
ROOT_PATH=$2
NGINX_CONF_PATH="/etc/nginx/sites-available/$DOMAIN"
NGINX_LINK_PATH="/etc/nginx/sites-enabled/$DOMAIN"

# Create Nginx configuration file
cat > $NGINX_CONF_PATH <<EOL
server {
    listen 80;
    server_name $DOMAIN;
    root $ROOT_PATH;

    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include fastcgi.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
    }

    # Deny access to .env and other sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        return 404;
    }
}
EOL

# Create root directory if not exists
if [ ! -d "$ROOT_PATH" ]; then
    mkdir -p $ROOT_PATH
    # Copy the new-domain.html template and rename it to index.html
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/new-domain.html" ]; then
        cp "$SCRIPT_DIR/new-domain.html" "$ROOT_PATH/index.html"
        # Replace the {{domain}} placeholder with the actual domain
        sed -i "s/{{domain}}/$DOMAIN/g" "$ROOT_PATH/index.html"
        echo "Created index.html from new-domain.html template"
    else
        echo "Warning: new-domain.html template not found, creating basic index.html"
        cat > "$ROOT_PATH/index.html" << 'EOF'
<!DOCTYPE html>
<html><head><title>Welcome</title></head>
<body><h1>Welcome</h1><p>Site under construction</p></body>
</html>
EOF
    fi
    chown -R $(whoami):www-data $ROOT_PATH
    chmod -R 775 $ROOT_PATH
fi

# Enable the site
ln -s $NGINX_CONF_PATH $NGINX_LINK_PATH

# Test Nginx configuration
nginx -t

if [ $? -eq 0 ]; then
    # Reload Nginx
    systemctl reload nginx
    echo "Domain $DOMAIN added and Nginx reloaded."
else
    echo "Nginx configuration test failed. Please check the configuration."
fi