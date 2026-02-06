#!/bin/bash

###############################################################################
# Server Setup Automation Script
# Supports: PHP, MySQL, Node.js, Python, Nginx, PM2, Certbot, Oh My Zsh
# Version: 1.0
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="/var/log/server-setup-$(date +%Y%m%d-%H%M%S).log"
INSTALL_LOG="/tmp/server-setup-install.log"

# Installation flags
UPDATE_SYSTEM=false
INSTALL_PHP=false
INSTALL_MYSQL=false
INSTALL_NODEJS=false
INSTALL_PYTHON=false
INSTALL_NGINX=false
INSTALL_PM2=false
INSTALL_CERTBOT=false
INSTALL_OHMYZSH=false

# Version variables
PHP_VERSION=""
NODEJS_VERSION=""
PYTHON_VERSION=""

    # MySQL variables
MYSQL_ROOT_PASSWORD=""
CREATE_MYSQL_DB=false
CREATE_MYSQL_USER=false
MYSQL_DB_NAME=""
MYSQL_DB_USER=""
MYSQL_DB_PASSWORD=""

# Python variables
INSTALL_GUNICORN=false

###############################################################################
# Utility Functions
###############################################################################

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

# Progress indicator functions
show_spinner() {
    local pid=$1
    local message=$2
    local spinstr='|/-\'
    local temp
    
    while kill -0 $pid 2>/dev/null; do
        temp=${spinstr#?}
        printf "\r${BLUE}[INFO]${NC} $message [%c] " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep 0.2
    done
    printf "\r${GREEN}[OK]${NC} $message                    \n"
}

run_with_progress() {
    local message=$1
    shift
    local cmd="$@"
    
    echo -ne "${BLUE}[INFO]${NC} $message... "
    if eval "$cmd" >> "$INSTALL_LOG" 2>&1; then
        echo -e "\r${GREEN}[OK]${NC} $message                    "
        return 0
    else
        echo -e "\r${RED}[FAILED]${NC} $message                    "
        return 1
    fi
}

run_with_output() {
    local message=$1
    shift
    local cmd="$@"
    
    echo -e "${BLUE}[INFO]${NC} $message..."
    echo "────────────────────────────────────────────────"
    if eval "$cmd" 2>&1 | tee -a "$INSTALL_LOG"; then
        echo "────────────────────────────────────────────────"
        echo -e "${GREEN}[OK]${NC} Completed: $message"
        return 0
    else
        echo "────────────────────────────────────────────────"
        echo -e "${RED}[FAILED]${NC} Failed: $message"
        return 1
    fi
}

prompt_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local response
    
    while true; do
        if [ "$default" = "y" ]; then
            read -p "$(echo -e ${BLUE}$prompt [Y/n]: ${NC})" response
            response=${response:-y}
        else
            read -p "$(echo -e ${BLUE}$prompt [y/N]: ${NC})" response
            response=${response:-n}
        fi
        
        case $response in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

prompt_input() {
    local prompt="$1"
    local default="$2"
    local response
    
    if [ -n "$default" ]; then
        read -p "$(echo -e ${BLUE}$prompt [$default]: ${NC})" response
        echo "${response:-$default}"
    else
        read -p "$(echo -e ${BLUE}$prompt: ${NC})" response
        echo "$response"
    fi
}

check_root() {
    if [ "$EUID" -ne 0 ]; then 
        error "Please run as root or with sudo"
    fi
}

update_system() {
    log "Updating system packages..."
    echo -e "${BLUE}[INFO]${NC} Updating package lists (this may take a minute)..."
    run_with_progress "Updating package lists" "apt update"
    
    echo -e "${BLUE}[INFO]${NC} Upgrading system packages (this may take several minutes)..."
    run_with_progress "Upgrading system packages" "apt upgrade -y"
    
    log "System updated successfully"
}

install_dependencies() {
    log "Installing common dependencies..."
    run_with_progress "Installing common dependencies" "apt install -y software-properties-common apt-transport-https curl wget build-essential openssl"
    log "Dependencies installed"
}

###############################################################################
# PHP Installation
###############################################################################

install_php() {
    log "Starting PHP installation..."
    
    # Add PHP repository
    echo -e "${BLUE}[INFO]${NC} Adding PHP repository..."
    run_with_progress "Adding PHP repository" "add-apt-repository ppa:ondrej/php -y"
    echo -e "${BLUE}[INFO]${NC} Updating package lists after adding repository..."
    run_with_progress "Updating package lists" "apt update"
    
    # Determine PHP version
    if [ -z "$PHP_VERSION" ]; then
        PHP_VERSION=$(prompt_input "Enter PHP version (e.g., 8.1, 8.2, 8.3) or press Enter for latest" "8.3")
    fi
    
    # Install PHP
    log "Installing PHP $PHP_VERSION..."
    echo -e "${BLUE}[INFO]${NC} Installing PHP $PHP_VERSION (this may take a few minutes)..."
    run_with_progress "Installing PHP $PHP_VERSION core packages" "apt install -y php${PHP_VERSION} php${PHP_VERSION}-fpm php${PHP_VERSION}-cli"
    
    # Ask for extensions
    info "Common PHP extensions: mysql, curl, json, mbstring, xml, zip, gd, intl, soap, xmlrpc, openssl, common"
    EXTENSIONS=$(prompt_input "Enter PHP extensions (comma-separated) or press Enter for common set" "mysql,curl,json,mbstring,xml,zip,gd,intl,soap,xmlrpc,openssl,common")
    
    # Install extensions
    IFS=',' read -ra EXT_ARRAY <<< "$EXTENSIONS"
    local ext_count=${#EXT_ARRAY[@]}
    local ext_current=0
    for ext in "${EXT_ARRAY[@]}"; do
        ext=$(echo "$ext" | xargs)  # Trim whitespace
        ext_current=$((ext_current + 1))
        echo -e "${BLUE}[INFO]${NC} Installing extension $ext_current/$ext_count: ${ext}..."
        
        # Check if extension is already loaded (built-in)
        if php -m 2>/dev/null | grep -qi "^${ext}$"; then
            echo -e "${GREEN}[OK]${NC} Extension ${ext} is already available (built-in)"
            continue
        fi
        
        # Try versioned package first (php8.3-json)
        if apt install -y php${PHP_VERSION}-${ext} >> "$INSTALL_LOG" 2>&1; then
            echo -e "${GREEN}[OK]${NC} Installed php${PHP_VERSION}-${ext}"
            continue
        fi
        
        # Fallback to generic package (php-json) for extensions that don't have versioned packages
        if [ "$ext" = "json" ] || [ "$ext" = "openssl" ]; then
            if apt install -y php-${ext} >> "$INSTALL_LOG" 2>&1; then
                echo -e "${GREEN}[OK]${NC} Installed php-${ext}"
                continue
            fi
        fi
        
        # If still failed, check if it's built-in after core installation
        if php -m 2>/dev/null | grep -qi "^${ext}$"; then
            echo -e "${GREEN}[OK]${NC} Extension ${ext} is available (built-in)"
        else
            warning "Failed to install php${PHP_VERSION}-${ext}. Extension may not be available or may be built-in."
        fi
    done
    
    # Start and enable PHP-FPM
    echo -e "${BLUE}[INFO]${NC} Starting PHP-FPM service..."
    systemctl start php${PHP_VERSION}-fpm
    systemctl enable php${PHP_VERSION}-fpm
    echo -e "${GREEN}[OK]${NC} PHP-FPM service started and enabled"
    
    # Install Composer
    if prompt_yes_no "Install Composer?" "y"; then
        log "Installing Composer..."
        cd /tmp
        EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
        php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
        ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"
        
        if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
            error "Composer installer checksum verification failed"
        fi
        
        php composer-setup.php --quiet
        php -r "unlink('composer-setup.php');"
        mv composer.phar /usr/local/bin/composer
        chmod +x /usr/local/bin/composer
        log "Composer installed successfully"
    fi
    
    # Configure PHP
    if prompt_yes_no "Configure PHP for large applications (upload_max_filesize, post_max_size, memory_limit)?" "y"; then
        PHP_INI="/etc/php/${PHP_VERSION}/fpm/php.ini"
        if [ -f "$PHP_INI" ]; then
            log "Configuring PHP settings..."
            sed -i 's/upload_max_filesize = .*/upload_max_filesize = 20M/' "$PHP_INI"
            sed -i 's/post_max_size = .*/post_max_size = 20M/' "$PHP_INI"
            sed -i 's/max_execution_time = .*/max_execution_time = 300/' "$PHP_INI"
            sed -i 's/memory_limit = .*/memory_limit = 256M/' "$PHP_INI"
            systemctl restart php${PHP_VERSION}-fpm
            log "PHP configured successfully"
        fi
    fi
    
    log "PHP $PHP_VERSION installed successfully"
    php -v
}

###############################################################################
# MySQL Installation
###############################################################################

# Helper function to execute MySQL command with proper authentication
execute_mysql_command() {
    local sql_command="$1"
    local use_sudo=false
    
    # Try sudo mysql first (works with auth_socket)
    if sudo mysql -e "SELECT 1" >/dev/null 2>&1; then
        use_sudo=true
    # If we have a password stored, try it
    elif [ -n "$MYSQL_ROOT_PASSWORD" ]; then
        if mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; then
            use_sudo=false
        else
            # Password doesn't work, clear it and prompt
            MYSQL_ROOT_PASSWORD=""
        fi
    fi
    
    # If neither works, prompt for password
    if [ "$use_sudo" = false ] && [ -z "$MYSQL_ROOT_PASSWORD" ]; then
        echo -e "${YELLOW}[WARNING]${NC} MySQL requires authentication. Please enter root password."
        echo -e "${BLUE}Enter MySQL root password (hidden): ${NC}"
        read -s MYSQL_ROOT_PASSWORD
        echo ""
        
        if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
            error "MySQL root password required but not provided."
            return 1
        fi
        
        # Test the password
        if ! mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; then
            error "Invalid MySQL root password. Cannot proceed."
            return 1
        fi
    fi
    
    # Execute the command
    if [ "$use_sudo" = true ]; then
        sudo mysql <<EOF
${sql_command}
EOF
    else
        mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
${sql_command}
EOF
    fi
    
    return $?
}

install_mysql() {
    log "Starting MySQL installation..."
    
    echo -e "${BLUE}[INFO]${NC} Installing MySQL server and client (this may take a few minutes)..."
    run_with_progress "Installing MySQL server and client" "apt install -y mysql-server mysql-client"
    
    # Secure MySQL installation
    log "Running mysql_secure_installation..."
    MYSQL_SECURE_RAN=false
    if prompt_yes_no "Run mysql_secure_installation? (Recommended)" "y"; then
        mysql_secure_installation
        MYSQL_SECURE_RAN=true
        info "Note: If you set a root password in mysql_secure_installation, you can skip setting it again below"
    fi
    
    # Set root password
    if prompt_yes_no "Set/Change MySQL root password?" "y"; then
        echo -e "${BLUE}Enter MySQL root password (hidden): ${NC}"
        read -s MYSQL_ROOT_PASSWORD
        echo ""
        MYSQL_ROOT_PASSWORD=$(echo "$MYSQL_ROOT_PASSWORD" | tr -d ' ')
        if [ -n "$MYSQL_ROOT_PASSWORD" ]; then
            log "Setting MySQL root password..."
            # Use sudo mysql to connect (works with auth_socket authentication)
            # This is the standard way to connect to MySQL after fresh installation
            if sudo mysql <<EOF 2>>"$INSTALL_LOG"
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF
            then
                log "MySQL root password set successfully"
            else
                error "Failed to set MySQL root password. Error logged to $INSTALL_LOG"
                warning "You can set it manually by running: sudo mysql"
                warning "Then execute: ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'your_password';"
                MYSQL_ROOT_PASSWORD=""  # Clear password since we couldn't set it
            fi
        fi
    fi
    
    # Create database (separate question)
    if prompt_yes_no "Create MySQL database?" "n"; then
        CREATE_MYSQL_DB=true
        MYSQL_DB_NAME=$(prompt_input "Enter database name" "")
        
        if [ -n "$MYSQL_DB_NAME" ]; then
            log "Creating database '${MYSQL_DB_NAME}'..."
            
            if execute_mysql_command "CREATE DATABASE IF NOT EXISTS ${MYSQL_DB_NAME}; FLUSH PRIVILEGES;"; then
                log "Database '${MYSQL_DB_NAME}' created successfully"
            else
                warning "Failed to create database. Please check MySQL connection and permissions"
                CREATE_MYSQL_DB=false
            fi
        else
            warning "Database creation skipped - database name not provided"
            CREATE_MYSQL_DB=false
        fi
    fi
    
    # Create database user (separate question, optional)
    if prompt_yes_no "Create MySQL database user?" "n"; then
        CREATE_MYSQL_USER=true
        
        # If database was created, suggest using it, otherwise ask
        if [ "$CREATE_MYSQL_DB" = true ] && [ -n "$MYSQL_DB_NAME" ]; then
            MYSQL_DB_USER=$(prompt_input "Enter database user name" "")
            echo -e "${BLUE}Enter database user password (hidden): ${NC}"
            read -s MYSQL_DB_PASSWORD
            echo ""
            
            # Ask which database to grant privileges on
            GRANT_DB=$(prompt_input "Enter database name to grant privileges on (or press Enter for '${MYSQL_DB_NAME}')" "$MYSQL_DB_NAME")
            GRANT_DB=${GRANT_DB:-$MYSQL_DB_NAME}
        else
            MYSQL_DB_USER=$(prompt_input "Enter database user name" "")
            echo -e "${BLUE}Enter database user password (hidden): ${NC}"
            read -s MYSQL_DB_PASSWORD
            echo ""
            GRANT_DB=$(prompt_input "Enter database name to grant privileges on" "")
        fi
        
        if [ -n "$MYSQL_DB_USER" ] && [ -n "$MYSQL_DB_PASSWORD" ] && [ -n "$GRANT_DB" ]; then
            log "Creating database user '${MYSQL_DB_USER}'..."
            
            # Escape password for SQL (basic escaping)
            ESCAPED_PASSWORD=$(echo "$MYSQL_DB_PASSWORD" | sed "s/'/''/g")
            
            if execute_mysql_command "CREATE USER IF NOT EXISTS '${MYSQL_DB_USER}'@'localhost' IDENTIFIED BY '${ESCAPED_PASSWORD}'; GRANT ALL PRIVILEGES ON ${GRANT_DB}.* TO '${MYSQL_DB_USER}'@'localhost'; FLUSH PRIVILEGES;"; then
                log "Database user '${MYSQL_DB_USER}' created successfully with privileges on '${GRANT_DB}'"
            else
                warning "Failed to create database user. Please check MySQL connection and permissions"
            fi
        else
            warning "Database user creation skipped - missing required information (user, password, or database name)"
        fi
    fi
    
    # Configure remote access
    if prompt_yes_no "Configure MySQL for remote access?" "n"; then
        log "Configuring MySQL for remote access..."
        MYSQL_CONF="/etc/mysql/mysql.conf.d/mysqld.cnf"
        if [ -f "$MYSQL_CONF" ]; then
            sed -i 's/bind-address.*/bind-address = 0.0.0.0/' "$MYSQL_CONF"
            systemctl restart mysql
            warning "MySQL configured for remote access. Ensure firewall allows port 3306"
        fi
    fi
    
    log "MySQL installed successfully"
}

###############################################################################
# Node.js Installation (via NVM)
###############################################################################

install_nodejs() {
    log "Starting Node.js installation via NVM..."
    
    # Set NVM directory
    export NVM_DIR="$HOME/.nvm"
    
    # Install NVM
    echo -e "${BLUE}[INFO]${NC} Installing NVM (Node Version Manager)..."
    run_with_output "Downloading and installing NVM" "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
    
    # Load NVM in current shell
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    else
        error "NVM installation failed - nvm.sh not found"
    fi
    
    # Add to bashrc/zshrc for persistence
    if ! grep -q "NVM_DIR" ~/.bashrc 2>/dev/null; then
        echo '' >> ~/.bashrc
        echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc
        echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc
    fi
    
    if [ -f ~/.zshrc ] && ! grep -q "NVM_DIR" ~/.zshrc 2>/dev/null; then
        echo '' >> ~/.zshrc
        echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.zshrc
        echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.zshrc
    fi
    
    # Determine Node.js version
    if [ -z "$NODEJS_VERSION" ]; then
        NODEJS_VERSION=$(prompt_input "Enter Node.js version (e.g., 18, 20, lts, latest) or press Enter for LTS" "lts")
    fi
    
    # Install Node.js (ensure NVM is loaded in the command)
    log "Installing Node.js $NODEJS_VERSION..."
    echo -e "${BLUE}[INFO]${NC} Installing Node.js $NODEJS_VERSION (this may take a few minutes)..."
    
    # Load NVM and run installation commands
    # Use . (dot) instead of source for better compatibility
    if [ "$NODEJS_VERSION" = "lts" ]; then
        run_with_output "Installing Node.js LTS" ". $NVM_DIR/nvm.sh && nvm install --lts && nvm use --lts && nvm alias default node"
    elif [ "$NODEJS_VERSION" = "latest" ]; then
        run_with_output "Installing latest Node.js" ". $NVM_DIR/nvm.sh && nvm install node && nvm use node && nvm alias default node"
    else
        run_with_output "Installing Node.js $NODEJS_VERSION" ". $NVM_DIR/nvm.sh && nvm install $NODEJS_VERSION && nvm use $NODEJS_VERSION && nvm alias default $NODEJS_VERSION"
    fi
    
    # Verify installation by loading NVM and checking versions
    log "Node.js installed successfully"
    echo -e "${BLUE}[INFO]${NC} Verifying installation..."
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        \. "$NVM_DIR/nvm.sh"
        if command -v node &> /dev/null; then
            echo -e "${GREEN}[OK]${NC} Node.js version: $(node -v)"
            echo -e "${GREEN}[OK]${NC} npm version: $(npm -v)"
        else
            warning "Node.js command not found. You may need to reload your shell or run: source ~/.bashrc"
        fi
    else
        warning "NVM not loaded. Node.js may not be available until you reload your shell."
    fi
}

###############################################################################
# Python Installation
###############################################################################

install_python() {
    log "Starting Python installation..."
    
    # Determine Python version
    if [ -z "$PYTHON_VERSION" ]; then
        PYTHON_VERSION=$(prompt_input "Enter Python version (e.g., 3.10, 3.11, 3.12) or press Enter for system default" "")
    fi
    
    if [ -z "$PYTHON_VERSION" ]; then
        # Install system Python
        log "Installing Python 3..."
        echo -e "${BLUE}[INFO]${NC} Installing Python 3 and dependencies..."
        run_with_progress "Installing Python 3" "apt install -y python3 python3-pip python3-venv python3-dev"
    else
        # Install specific version
        log "Installing Python $PYTHON_VERSION..."
        echo -e "${BLUE}[INFO]${NC} Installing Python $PYTHON_VERSION..."
        if ! run_with_progress "Installing Python $PYTHON_VERSION" "apt install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-pip python${PYTHON_VERSION}-venv python${PYTHON_VERSION}-dev"; then
            warning "Specific Python version not available, installing system default"
            run_with_progress "Installing Python 3 (fallback)" "apt install -y python3 python3-pip python3-venv python3-dev"
        fi
    fi
    
    # Upgrade pip
    echo -e "${BLUE}[INFO]${NC} Upgrading pip..."
    run_with_progress "Upgrading pip" "python3 -m pip install --upgrade pip"
    
    # Install Gunicorn
    if prompt_yes_no "Install Gunicorn globally?" "n"; then
        INSTALL_GUNICORN=true
        echo -e "${BLUE}[INFO]${NC} Installing Gunicorn..."
        run_with_progress "Installing Gunicorn" "pip3 install gunicorn"
        log "Gunicorn installed successfully"
        gunicorn --version
    fi
    
    log "Python installed successfully"
    python3 --version
    pip3 --version
}

###############################################################################
# Nginx Installation
###############################################################################

install_nginx() {
    log "Starting Nginx installation..."
    
    echo -e "${BLUE}[INFO]${NC} Installing Nginx web server..."
    run_with_progress "Installing Nginx" "apt install -y nginx"
    
    # Start and enable Nginx
    echo -e "${BLUE}[INFO]${NC} Starting and enabling Nginx service..."
    systemctl start nginx
    systemctl enable nginx
    echo -e "${GREEN}[OK]${NC} Nginx service started and enabled"
    
    # Create common configuration directories
    mkdir -p /etc/nginx/custom_conf
    
    # Create block direct access config
    cat > /etc/nginx/custom_conf/block-direct-access.conf <<'EOF'
location ~* \.env$ {
    deny all;
    access_log off;
    return 404;
}
EOF
    
    log "Nginx installed successfully"
    
    # Test Nginx configuration
    if nginx -t >> "$INSTALL_LOG" 2>&1; then
        log "Nginx configuration is valid"
    else
        warning "Nginx configuration test failed. Please check manually."
    fi
    
    info "Nginx is running on http://$(hostname -I | awk '{print $1}')"
}

###############################################################################
# PM2 Installation
###############################################################################

install_pm2() {
    log "Starting PM2 installation..."
    
    # Check if Node.js is installed
    if ! command -v node &> /dev/null; then
        error "Node.js is required for PM2. Please install Node.js first."
    fi
    
    echo -e "${BLUE}[INFO]${NC} Installing PM2 globally..."
    run_with_progress "Installing PM2" "npm install -g pm2"
    
    # Configure PM2 for system startup
    if prompt_yes_no "Configure PM2 to start on system boot?" "y"; then
        log "Configuring PM2 startup..."
        pm2 startup
        log "Follow the instructions above to complete PM2 startup configuration"
    fi
    
    log "PM2 installed successfully"
    pm2 --version
}

###############################################################################
# Oh My Zsh Installation
###############################################################################

install_ohmyzsh() {
    log "Starting Oh My Zsh installation..."
    
    # Install Zsh
    echo -e "${BLUE}[INFO]${NC} Installing Zsh shell..."
    run_with_progress "Installing Zsh" "apt install -y zsh"
    
    # Determine target user
    CURRENT_USER=""
    if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
        CURRENT_USER="$SUDO_USER"
    elif [ -n "$USER" ] && [ "$USER" != "root" ]; then
        CURRENT_USER="$USER"
    else
        # If running as root, ask which user to install for
        SUGGESTED_USER=$(who | awk 'NR==1 {print $1}' 2>/dev/null || echo "")
        CURRENT_USER=$(prompt_input "Enter username to install Oh My Zsh for" "$SUGGESTED_USER")
        if [ -z "$CURRENT_USER" ]; then
            CURRENT_USER="root"
        elif ! id "$CURRENT_USER" &>/dev/null; then
            error "Invalid user: $CURRENT_USER"
        fi
    fi
    
    log "Installing Oh My Zsh for user: $CURRENT_USER"
    
    # Determine home directory
    if [ "$CURRENT_USER" = "root" ]; then
        USER_HOME="/root"
    else
        USER_HOME="/home/$CURRENT_USER"
    fi
    
    # Install Oh My Zsh
    echo -e "${BLUE}[INFO]${NC} Installing Oh My Zsh framework..."
    if [ "$CURRENT_USER" = "root" ]; then
        # For root user
        export HOME="$USER_HOME"
        run_with_output "Installing Oh My Zsh for root" "sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" \"\" --unattended" || {
            warning "Oh My Zsh installation had issues, but continuing..."
        }
    else
        # Switch to the user and install
        run_with_output "Installing Oh My Zsh for $CURRENT_USER" "sudo -u $CURRENT_USER HOME=$USER_HOME sh -c 'sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" \"\" --unattended'" || {
            warning "Oh My Zsh installation had issues, but continuing..."
        }
    fi
    
    # Customize prompt (optional)
    if prompt_yes_no "Customize Oh My Zsh prompt?" "n"; then
        PROMPT_TEXT=$(prompt_input "Enter custom prompt text (e.g., 'server' or your name)" "$CURRENT_USER")
        THEME_FILE="$USER_HOME/.oh-my-zsh/themes/robbyrussell.zsh-theme"
        
        if [ -f "$THEME_FILE" ]; then
            log "Customizing prompt..."
            ESCAPED_PROMPT=$(echo "$PROMPT_TEXT" | sed 's/[\/&]/\\&/g')
            if [ "$CURRENT_USER" != "root" ]; then
                sudo -u "$CURRENT_USER" sed -i "s/PROMPT=.*/PROMPT=\"%(?:%{\$fg_bold[green]%}➜ :%{\$fg_bold[red]%}➜ ) %{\$fg_bold[cyan]%}${ESCAPED_PROMPT}: %{\$fg[cyan]%}%c%{\$reset_color%}\"/" "$THEME_FILE"
            else
                sed -i "s/PROMPT=.*/PROMPT=\"%(?:%{\$fg_bold[green]%}➜ :%{\$fg_bold[red]%}➜ ) %{\$fg_bold[cyan]%}${ESCAPED_PROMPT}: %{\$fg[cyan]%}%c%{\$reset_color%}\"/" "$THEME_FILE"
            fi
            log "Prompt customized"
        else
            warning "Theme file not found: $THEME_FILE"
        fi
    fi
    
    # Set Zsh as default shell (optional)
    if prompt_yes_no "Set Zsh as default shell for $CURRENT_USER?" "y"; then
        log "Setting Zsh as default shell..."
        ZSH_PATH=$(which zsh)
        if [ -n "$ZSH_PATH" ]; then
            if [ "$CURRENT_USER" = "root" ]; then
                chsh -s "$ZSH_PATH" || warning "Failed to change default shell. You can run 'chsh -s $ZSH_PATH' manually."
            else
                chsh -s "$ZSH_PATH" "$CURRENT_USER" || warning "Failed to change default shell. You can run 'sudo chsh -s $ZSH_PATH $CURRENT_USER' manually."
            fi
            log "Zsh set as default shell for $CURRENT_USER"
            info "Note: You may need to log out and log back in for the change to take effect"
        else
            warning "Zsh not found in PATH"
        fi
    fi
    
    log "Oh My Zsh installed successfully for $CURRENT_USER"
}

###############################################################################
# Certbot Installation
###############################################################################

install_certbot() {
    log "Starting Certbot installation..."
    
    echo -e "${BLUE}[INFO]${NC} Installing Certbot and Nginx plugin..."
    run_with_progress "Installing Certbot" "apt install -y certbot python3-certbot-nginx"
    
    log "Certbot installed successfully"
    certbot --version
    
    # Optionally obtain SSL certificate
    if prompt_yes_no "Obtain SSL certificate for a domain now?" "n"; then
        DOMAIN=$(prompt_input "Enter domain name (e.g., example.com)" "")
        if [ -n "$DOMAIN" ]; then
            log "Obtaining SSL certificate for $DOMAIN..."
            certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$(prompt_input "Enter email for Let's Encrypt notifications" "")" || {
                warning "SSL certificate generation failed. You can run 'certbot --nginx' manually later."
            }
        fi
    fi
    
    # Enable automatic renewal
    systemctl enable certbot.timer
    systemctl start certbot.timer
    log "Certbot automatic renewal enabled"
}

###############################################################################
# Main Installation Flow
###############################################################################

collect_requirements() {
    clear
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Server Setup Automation Script${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    info "This script will help you install and configure:"
    echo "  - PHP with extensions"
    echo "  - MySQL database server"
    echo "  - Node.js (via NVM)"
    echo "  - Python with optional Gunicorn"
    echo "  - Nginx web server"
    echo "  - PM2 process manager"
    echo "  - Certbot for SSL certificates"
    echo "  - Oh My Zsh shell"
    echo ""
    
    # Ask about system update
    if prompt_yes_no "Update system packages (apt update && apt upgrade)?" "y"; then
        UPDATE_SYSTEM=true
    fi
    
    echo ""
    
    # Ask what to install
    if prompt_yes_no "Install PHP?" "n"; then
        INSTALL_PHP=true
    fi
    
    if prompt_yes_no "Install MySQL?" "n"; then
        INSTALL_MYSQL=true
    fi
    
    if prompt_yes_no "Install Node.js (via NVM)?" "n"; then
        INSTALL_NODEJS=true
    fi
    
    if prompt_yes_no "Install Python?" "n"; then
        INSTALL_PYTHON=true
    fi
    
    if prompt_yes_no "Install Nginx?" "n"; then
        INSTALL_NGINX=true
    fi
    
    if prompt_yes_no "Install PM2?" "n"; then
        INSTALL_PM2=true
    fi
    
    if prompt_yes_no "Install Certbot?" "n"; then
        INSTALL_CERTBOT=true
    fi
    
    if prompt_yes_no "Install Oh My Zsh?" "n"; then
        INSTALL_OHMYZSH=true
    fi
    
    echo ""
    info "Installation summary:"
    [ "$INSTALL_PHP" = true ] && echo "  ✓ PHP"
    [ "$INSTALL_MYSQL" = true ] && echo "  ✓ MySQL"
    [ "$INSTALL_NODEJS" = true ] && echo "  ✓ Node.js"
    [ "$INSTALL_PYTHON" = true ] && echo "  ✓ Python"
    [ "$INSTALL_NGINX" = true ] && echo "  ✓ Nginx"
    [ "$INSTALL_PM2" = true ] && echo "  ✓ PM2"
    [ "$INSTALL_CERTBOT" = true ] && echo "  ✓ Certbot"
    [ "$INSTALL_OHMYZSH" = true ] && echo "  ✓ Oh My Zsh"
    echo ""
    
    if ! prompt_yes_no "Proceed with installation?" "y"; then
        log "Installation cancelled by user"
        exit 0
    fi
}

run_installation() {
    log "Starting installation process..."
    log "Installation log: $LOG_FILE"
    log "Detailed log: $INSTALL_LOG"
    echo ""
    
    # Count total steps
    TOTAL_STEPS=1  # install_dependencies
    [ "$UPDATE_SYSTEM" = true ] && TOTAL_STEPS=$((TOTAL_STEPS + 1))
    [ "$INSTALL_PHP" = true ] && TOTAL_STEPS=$((TOTAL_STEPS + 1))
    [ "$INSTALL_MYSQL" = true ] && TOTAL_STEPS=$((TOTAL_STEPS + 1))
    [ "$INSTALL_NODEJS" = true ] && TOTAL_STEPS=$((TOTAL_STEPS + 1))
    [ "$INSTALL_PYTHON" = true ] && TOTAL_STEPS=$((TOTAL_STEPS + 1))
    [ "$INSTALL_NGINX" = true ] && TOTAL_STEPS=$((TOTAL_STEPS + 1))
    [ "$INSTALL_PM2" = true ] && TOTAL_STEPS=$((TOTAL_STEPS + 1))
    [ "$INSTALL_CERTBOT" = true ] && TOTAL_STEPS=$((TOTAL_STEPS + 1))
    [ "$INSTALL_OHMYZSH" = true ] && TOTAL_STEPS=$((TOTAL_STEPS + 1))
    
    CURRENT_STEP=0
    
    # Update system first (if requested)
    if [ "$UPDATE_SYSTEM" = true ]; then
        CURRENT_STEP=$((CURRENT_STEP + 1))
        echo -e "\n${GREEN}════════════════════════════════════════${NC}"
        echo -e "${GREEN}Step $CURRENT_STEP/$TOTAL_STEPS: System Update${NC}"
        echo -e "${GREEN}════════════════════════════════════════${NC}\n"
        update_system
    fi
    
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo -e "\n${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}Step $CURRENT_STEP/$TOTAL_STEPS: Installing Dependencies${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}\n"
    install_dependencies
    
    # Install components
    [ "$INSTALL_PHP" = true ] && {
        CURRENT_STEP=$((CURRENT_STEP + 1))
        echo -e "\n${GREEN}════════════════════════════════════════${NC}"
        echo -e "${GREEN}Step $CURRENT_STEP/$TOTAL_STEPS: Installing PHP${NC}"
        echo -e "${GREEN}════════════════════════════════════════${NC}\n"
        install_php
    }
    
    [ "$INSTALL_MYSQL" = true ] && {
        CURRENT_STEP=$((CURRENT_STEP + 1))
        echo -e "\n${GREEN}════════════════════════════════════════${NC}"
        echo -e "${GREEN}Step $CURRENT_STEP/$TOTAL_STEPS: Installing MySQL${NC}"
        echo -e "${GREEN}════════════════════════════════════════${NC}\n"
        install_mysql
    }
    
    [ "$INSTALL_NODEJS" = true ] && {
        CURRENT_STEP=$((CURRENT_STEP + 1))
        echo -e "\n${GREEN}════════════════════════════════════════${NC}"
        echo -e "${GREEN}Step $CURRENT_STEP/$TOTAL_STEPS: Installing Node.js${NC}"
        echo -e "${GREEN}════════════════════════════════════════${NC}\n"
        install_nodejs
    }
    
    [ "$INSTALL_PYTHON" = true ] && {
        CURRENT_STEP=$((CURRENT_STEP + 1))
        echo -e "\n${GREEN}════════════════════════════════════════${NC}"
        echo -e "${GREEN}Step $CURRENT_STEP/$TOTAL_STEPS: Installing Python${NC}"
        echo -e "${GREEN}════════════════════════════════════════${NC}\n"
        install_python
    }
    
    [ "$INSTALL_NGINX" = true ] && {
        CURRENT_STEP=$((CURRENT_STEP + 1))
        echo -e "\n${GREEN}════════════════════════════════════════${NC}"
        echo -e "${GREEN}Step $CURRENT_STEP/$TOTAL_STEPS: Installing Nginx${NC}"
        echo -e "${GREEN}════════════════════════════════════════${NC}\n"
        install_nginx
    }
    
    [ "$INSTALL_PM2" = true ] && {
        CURRENT_STEP=$((CURRENT_STEP + 1))
        echo -e "\n${GREEN}════════════════════════════════════════${NC}"
        echo -e "${GREEN}Step $CURRENT_STEP/$TOTAL_STEPS: Installing PM2${NC}"
        echo -e "${GREEN}════════════════════════════════════════${NC}\n"
        install_pm2
    }
    
    [ "$INSTALL_CERTBOT" = true ] && {
        CURRENT_STEP=$((CURRENT_STEP + 1))
        echo -e "\n${GREEN}════════════════════════════════════════${NC}"
        echo -e "${GREEN}Step $CURRENT_STEP/$TOTAL_STEPS: Installing Certbot${NC}"
        echo -e "${GREEN}════════════════════════════════════════${NC}\n"
        install_certbot
    }
    
    [ "$INSTALL_OHMYZSH" = true ] && {
        CURRENT_STEP=$((CURRENT_STEP + 1))
        echo -e "\n${GREEN}════════════════════════════════════════${NC}"
        echo -e "${GREEN}Step $CURRENT_STEP/$TOTAL_STEPS: Installing Oh My Zsh${NC}"
        echo -e "${GREEN}════════════════════════════════════════${NC}\n"
        install_ohmyzsh
    }
    
    log "Installation completed successfully!"
    echo ""
    info "Installation summary saved to: $LOG_FILE"
    info "Detailed installation log: $INSTALL_LOG"
    echo ""
    
    # Show next steps
    echo -e "${GREEN}Next Steps:${NC}"
    [ "$INSTALL_NGINX" = true ] && echo "  - Configure Nginx sites: /etc/nginx/sites-available/"
    [ "$INSTALL_PHP" = true ] && echo "  - PHP-FPM socket: /run/php/php*-fpm.sock"
    [ "$INSTALL_MYSQL" = true ] && echo "  - MySQL is running. Use 'mysql -u root -p' to connect"
    [ "$INSTALL_NODEJS" = true ] && echo "  - Node.js installed via NVM. Use 'nvm list' to see versions"
    [ "$INSTALL_PM2" = true ] && echo "  - PM2 installed. Use 'pm2 start app.js' to start applications"
    [ "$INSTALL_CERTBOT" = true ] && echo "  - Certbot installed. Use 'certbot --nginx' to obtain SSL certificates"
    [ "$INSTALL_OHMYZSH" = true ] && echo "  - Oh My Zsh installed. Log out and log back in to use Zsh"
    echo ""
}

###############################################################################
# Script Entry Point
###############################################################################

main() {
    check_root
    
    # Create log directory
    mkdir -p /var/log
    touch "$LOG_FILE"
    touch "$INSTALL_LOG"
    
    # Collect requirements
    collect_requirements
    
    # Run installation
    run_installation
}

# Run main function
main "$@"
