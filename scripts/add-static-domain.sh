#!/bin/bash

###############################################################################
# Add Static Domain (HTML/CSS) - Nginx Configuration Script
# Usage: ./add-static-domain.sh [domain] [root_directory]
###############################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ensure the script is run with sudo or as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}This script must be run as root (use sudo)${NC}"
    exit 1
fi

###############################################################################
# Helper Functions
###############################################################################

log()     { echo -e "${GREEN}[OK]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
info()    { echo -e "${BLUE}[INFO]${NC} $1"; }

prompt_input() {
    local prompt="$1"
    local default="$2"
    local response
    if [ -n "$default" ]; then
        read -e -p "$(echo -e ${BLUE}"$prompt [$default]: "${NC})" response
        echo "${response:-$default}"
    else
        read -e -p "$(echo -e ${BLUE}"$prompt: "${NC})" response
        echo "$response"
    fi
}

prompt_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local response
    while true; do
        if [ "$default" = "y" ]; then
            read -e -p "$(echo -e ${BLUE}"$prompt [Y/n]: "${NC})" response
            response=${response:-y}
        else
            read -e -p "$(echo -e ${BLUE}"$prompt [y/N]: "${NC})" response
            response=${response:-n}
        fi
        case $response in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

is_ip_address() {
    local input="$1"
    if [[ "$input" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 0
    fi
    return 1
}

###############################################################################
# Collect Input
###############################################################################

# Get domain from argument or prompt
if [ -n "$1" ]; then
    DOMAIN="$1"
else
    DOMAIN=$(prompt_input "Enter domain name (e.g., example.com or www.example.com)" "")
    [ -z "$DOMAIN" ] && error "Domain name is required."
fi

# Get root directory from argument or prompt
DEFAULT_ROOT="/var/www/$DOMAIN"
if [ -n "$2" ]; then
    ROOT_PATH="$2"
else
    ROOT_PATH=$(prompt_input "Enter root directory" "$DEFAULT_ROOT")
fi

NGINX_CONF_PATH="/etc/nginx/sites-available/$DOMAIN"
NGINX_LINK_PATH="/etc/nginx/sites-enabled/$DOMAIN"

###############################################################################
# Create Nginx Configuration
###############################################################################

info "Creating Nginx configuration for $DOMAIN..."

cat > "$NGINX_CONF_PATH" <<EOL
server {
    listen 80;
    server_name $DOMAIN;
    root $ROOT_PATH;

    index index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    # Cache static assets
    location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        return 404;
    }
}
EOL

log "Nginx configuration created at $NGINX_CONF_PATH"

###############################################################################
# Create Root Directory and Sample index.html
###############################################################################

if [ ! -d "$ROOT_PATH" ]; then
    mkdir -p "$ROOT_PATH"
    info "Created directory: $ROOT_PATH"
else
    info "Directory already exists: $ROOT_PATH"
fi

# Create sample index.html
cat > "$ROOT_PATH/index.html" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to $DOMAIN</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #f0f4f8;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            color: #333;
        }
        .container {
            text-align: center;
            background: white;
            padding: 3rem 4rem;
            border-radius: 12px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.08);
        }
        h1 { font-size: 2.5rem; color: #2d3748; margin-bottom: 0.5rem; }
        p { font-size: 1.1rem; color: #718096; margin-top: 0.75rem; }
        .domain { color: #4299e1; font-weight: 600; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome!</h1>
        <p>You're visiting <span class="domain">$DOMAIN</span></p>
        <p>Your site is live and ready. Replace this file to get started.</p>
    </div>
</body>
</html>
EOF

log "Sample index.html created at $ROOT_PATH/index.html"

# Set permissions
chown -R www-data:www-data "$ROOT_PATH"
chmod -R 755 "$ROOT_PATH"
log "Permissions set on $ROOT_PATH"

###############################################################################
# Enable Nginx Site
###############################################################################

if [ -L "$NGINX_LINK_PATH" ]; then
    warning "Symlink already exists at $NGINX_LINK_PATH — skipping."
else
    ln -s "$NGINX_CONF_PATH" "$NGINX_LINK_PATH"
    log "Site enabled (symlink created)"
fi

# Test and reload Nginx
nginx -t || error "Nginx configuration test failed. Check $NGINX_CONF_PATH"
systemctl reload nginx
log "Nginx reloaded successfully"

###############################################################################
# Certbot (SSL)
###############################################################################

if is_ip_address "$DOMAIN"; then
    info "IP address detected — skipping Certbot (SSL requires a domain name)."
else
    if prompt_yes_no "Install SSL certificate with Certbot for $DOMAIN?" "n"; then
        if ! command -v certbot &>/dev/null; then
            info "Installing Certbot..."
            apt install -y certbot python3-certbot-nginx >> /dev/null 2>&1
            log "Certbot installed"
        fi
        EMAIL=$(prompt_input "Enter email for Let's Encrypt notifications" "")
        if [ -n "$EMAIL" ]; then
            certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$EMAIL" \
                && log "SSL certificate obtained for $DOMAIN" \
                || warning "Certbot failed. You can retry manually: certbot --nginx -d $DOMAIN"
        else
            certbot --nginx -d "$DOMAIN" \
                && log "SSL certificate obtained for $DOMAIN" \
                || warning "Certbot failed. You can retry manually: certbot --nginx -d $DOMAIN"
        fi
    fi
fi

###############################################################################
# Done
###############################################################################

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}  Static site setup complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "  Domain    : $DOMAIN"
echo "  Root dir  : $ROOT_PATH"
echo "  Nginx conf: $NGINX_CONF_PATH"
echo ""
info "Visit http://$DOMAIN to verify your site."
echo ""
