#!/bin/bash

###############################################################################
# Add Laravel Domain/IP - Nginx Configuration Script
# Usage: ./add-laravel-domain.sh [domain_or_ip] [root_directory] [port]
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

prompt_secret() {
    local prompt="$1"
    local response
    read -sp "$(echo -e ${BLUE}"$prompt: "${NC})" response
    echo ""
    echo "$response"
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

detect_php_version() {
    # Try to detect installed PHP-FPM version
    for ver in 8.3 8.2 8.1 8.0 7.4; do
        if [ -S "/run/php/php${ver}-fpm.sock" ]; then
            echo "$ver"
            return
        fi
    done
    # Fallback: check php binary
    if command -v php &>/dev/null; then
        php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;"
        return
    fi
    echo "8.3"
}

execute_mysql() {
    local sql="$1"
    # Try sudo mysql first (auth_socket), then password auth
    if sudo mysql -e "SELECT 1" >/dev/null 2>&1; then
        sudo mysql <<< "$sql"
    elif [ -n "$MYSQL_ROOT_PASSWORD" ]; then
        mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<< "$sql"
    else
        error "Cannot connect to MySQL. Ensure MySQL is running and accessible."
    fi
}

###############################################################################
# Collect Input
###############################################################################

# Domain or IP
if [ -n "$1" ]; then
    DOMAIN="$1"
else
    DOMAIN=$(prompt_input "Enter domain name or IP address" "")
    [ -z "$DOMAIN" ] && error "Domain/IP is required."
fi

# Root directory (parent directory of the Laravel project)
DEFAULT_ROOT="/var/www/$DOMAIN"
if [ -n "$2" ]; then
    ROOT_PATH="$2"
else
    ROOT_PATH=$(prompt_input "Enter project root directory (parent of 'public/')" "$DEFAULT_ROOT")
fi

PUBLIC_PATH="$ROOT_PATH/public"

# Port
if [ -n "$3" ]; then
    PORT="$3"
else
    PORT=$(prompt_input "Enter port number" "80")
fi

# Detect PHP version
PHP_VERSION=$(detect_php_version)
PHP_VERSION=$(prompt_input "Enter PHP version (for PHP-FPM socket)" "$PHP_VERSION")
PHP_FPM_SOCK="/run/php/php${PHP_VERSION}-fpm.sock"

NGINX_CONF_PATH="/etc/nginx/sites-available/$DOMAIN"
NGINX_LINK_PATH="/etc/nginx/sites-enabled/$DOMAIN"

###############################################################################
# Database Setup
###############################################################################

DB_TYPE="sqlite"
MYSQL_DB_NAME=""
MYSQL_DB_USER=""
MYSQL_DB_PASSWORD=""
MYSQL_ROOT_PASSWORD=""

if prompt_yes_no "Does this application require a database?" "y"; then
    echo ""
    info "Database type options: sqlite, mysql"
    DB_TYPE=$(prompt_input "Enter database type" "sqlite")

    if [ "$DB_TYPE" = "mysql" ]; then
        MYSQL_DB_NAME=$(prompt_input "Enter database name" "$(echo "$DOMAIN" | tr '.-' '_')_db")
        MYSQL_DB_USER=$(prompt_input "Enter database user name" "$(echo "$DOMAIN" | tr '.-' '_')_user")
        MYSQL_DB_PASSWORD=$(prompt_secret "Enter database user password")
        [ -z "$MYSQL_DB_PASSWORD" ] && error "Database password cannot be empty."

        echo ""
        info "MySQL root credentials are needed to create the database and user."

        # Try sudo mysql (auth_socket) first
        if sudo mysql -e "SELECT 1" >/dev/null 2>&1; then
            info "Connected to MySQL via sudo (auth_socket)."
        else
            MYSQL_ROOT_PASSWORD=$(prompt_secret "Enter MySQL root password")
            if ! mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; then
                error "Invalid MySQL root credentials."
            fi
        fi

        info "Creating database '$MYSQL_DB_NAME' and user '$MYSQL_DB_USER'..."
        ESCAPED_PASS=$(echo "$MYSQL_DB_PASSWORD" | sed "s/'/''/g")
        execute_mysql "
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DB_NAME}\`;
CREATE USER IF NOT EXISTS '${MYSQL_DB_USER}'@'localhost' IDENTIFIED BY '${ESCAPED_PASS}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DB_NAME}\`.* TO '${MYSQL_DB_USER}'@'localhost';
FLUSH PRIVILEGES;
"
        log "MySQL database '$MYSQL_DB_NAME' and user '$MYSQL_DB_USER' created."
    fi
fi

###############################################################################
# Create Directory Structure and Sample Files
###############################################################################

if [ ! -d "$PUBLIC_PATH" ]; then
    mkdir -p "$PUBLIC_PATH"
    info "Created directory: $PUBLIC_PATH"
fi

# Create sample public/index.php
cat > "$PUBLIC_PATH/index.php" <<EOF
<?php
/**
 * Laravel - A PHP Framework For Web Artisans
 *
 * Domain: $DOMAIN
 * Public path: $PUBLIC_PATH
 *
 * Replace this file with your actual Laravel application.
 */

echo <<<HTML
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
            background: #1a1a2e;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            color: #eee;
        }
        .container {
            text-align: center;
            background: #16213e;
            padding: 3rem 4rem;
            border-radius: 12px;
            box-shadow: 0 4px 30px rgba(0,0,0,0.4);
            border: 1px solid #0f3460;
        }
        h1 { font-size: 2.5rem; color: #e94560; margin-bottom: 0.5rem; }
        p { font-size: 1.1rem; color: #a8b2d8; margin-top: 0.75rem; }
        .domain { color: #4fc3f7; font-weight: 600; }
        .badge {
            display: inline-block;
            margin-top: 1.5rem;
            padding: 0.3rem 0.9rem;
            background: #0f3460;
            border-radius: 20px;
            font-size: 0.85rem;
            color: #4fc3f7;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Laravel Ready</h1>
        <p>Your application at <span class="domain">$DOMAIN</span> is configured.</p>
        <p>Deploy your Laravel project to <code>$ROOT_PATH</code></p>
        <span class="badge">PHP <?php echo PHP_VERSION; ?></span>
    </div>
</body>
</html>
HTML;
EOF

log "Sample index.php created at $PUBLIC_PATH/index.php"

# Set permissions
chown -R www-data:www-data "$ROOT_PATH"
chmod -R 755 "$ROOT_PATH"

# Laravel storage/bootstrap cache need write access
if [ -d "$ROOT_PATH/storage" ]; then
    chmod -R 775 "$ROOT_PATH/storage"
fi
if [ -d "$ROOT_PATH/bootstrap/cache" ]; then
    chmod -R 775 "$ROOT_PATH/bootstrap/cache"
fi

log "Permissions set on $ROOT_PATH"

###############################################################################
# Create Nginx Configuration
###############################################################################

info "Creating Nginx configuration for $DOMAIN..."

cat > "$NGINX_CONF_PATH" <<EOL
server {
    listen $PORT;
    server_name $DOMAIN;
    root $PUBLIC_PATH;

    index index.php index.html;

    # Handle Laravel routes
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    # Pass PHP files to PHP-FPM
    location ~ \.php\$ {
        include fastcgi_params;
        fastcgi_pass unix:$PHP_FPM_SOCK;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT \$realpath_root;
        fastcgi_index index.php;
        fastcgi_read_timeout 300;
    }

    # Deny access to .env and hidden files
    location ~ /\.(?!well-known).* {
        deny all;
        access_log off;
        return 404;
    }

    # Cache static assets
    location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, no-transform";
        try_files \$uri =404;
    }

    client_max_body_size 20M;
}
EOL

log "Nginx configuration created at $NGINX_CONF_PATH"

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
# Certbot (SSL) — skip for IP addresses
###############################################################################

if is_ip_address "$DOMAIN"; then
    info "IP address detected — skipping Certbot (SSL requires a domain name)."
else
    if [ "$PORT" != "80" ] && [ "$PORT" != "443" ]; then
        info "Non-standard port ($PORT) detected — skipping Certbot SSL offer."
    elif prompt_yes_no "Install SSL certificate with Certbot for $DOMAIN?" "n"; then
        if ! command -v certbot &>/dev/null; then
            info "Installing Certbot..."
            apt install -y certbot python3-certbot-nginx >> /dev/null 2>&1
            log "Certbot installed"
        fi
        EMAIL=$(prompt_input "Enter email for Let's Encrypt notifications" "")
        if [ -n "$EMAIL" ]; then
            certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$EMAIL" \
                && log "SSL certificate obtained for $DOMAIN" \
                || warning "Certbot failed. Retry manually: certbot --nginx -d $DOMAIN"
        else
            certbot --nginx -d "$DOMAIN" \
                && log "SSL certificate obtained for $DOMAIN" \
                || warning "Certbot failed. Retry manually: certbot --nginx -d $DOMAIN"
        fi
    fi
fi

###############################################################################
# Done
###############################################################################

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}  Laravel site setup complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "  Domain/IP : $DOMAIN"
echo "  Root dir  : $ROOT_PATH"
echo "  Public dir: $PUBLIC_PATH"
echo "  Nginx conf: $NGINX_CONF_PATH"
echo "  PHP-FPM   : $PHP_FPM_SOCK"
if [ "$DB_TYPE" = "mysql" ]; then
echo ""
echo "  DB Type   : MySQL"
echo "  DB Name   : $MYSQL_DB_NAME"
echo "  DB User   : $MYSQL_DB_USER"
elif [ "$DB_TYPE" = "sqlite" ]; then
echo ""
echo "  DB Type   : SQLite"
echo "  DB Path   : $ROOT_PATH/database/database.sqlite (default Laravel path)"
fi
echo ""
info "Next steps:"
echo "  1. Deploy your Laravel project to: $ROOT_PATH"
echo "  2. Copy .env.example to .env and configure it"
echo "  3. Run: php artisan key:generate"
echo "  4. Run: php artisan migrate"
if [ "$DB_TYPE" = "sqlite" ]; then
echo "  5. For SQLite: touch $ROOT_PATH/database/database.sqlite"
fi
echo ""
info "Visit http://$DOMAIN to verify your site."
echo ""
