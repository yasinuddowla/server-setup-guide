# PHP & PHP-FPM Setup

Installation and configuration of PHP with FastCGI Process Manager.

## Install PHP with Extensions

```bash
# Only for application servers
sudo apt install php php-mysql openssl php-common php-curl php-json php-mbstring php-xml php-zip php-gd php-cli php-intl php-soap php-xmlrpc

# Check PHP version
php -v
```

## Install PHP-FPM

```bash
# Only for application servers
sudo apt install php-fpm
sudo systemctl start php8.3-fpm
sudo systemctl enable php8.3-fpm
```

### Alternative PHP Version Management (macOS)
```bash
# Start and stop different versions on macOS
brew services stop php && brew services start php@8.1
```

## Upgrade to PHP 8.3

```bash
sudo apt update && sudo apt upgrade
sudo apt install -y software-properties-common apt-transport-https
sudo add-apt-repository ppa:ondrej/php -y

sudo apt update

sudo apt install php8.3

# Install PHP 8.3 extensions
sudo apt install php8.3-mysql php8.3-common php8.3-curl php8.3-json php8.3-mbstring php8.3-xml php8.3-zip php8.3-gd php8.3-cli php8.3-fpm

# Start and enable PHP-FPM
sudo systemctl start php8.3-fpm
sudo systemctl enable php8.3-fpm

# Restart services
sudo systemctl restart nginx
sudo systemctl restart php8.3-fpm
```

## Install Composer

```bash
# Only for application servers
cd /tmp

# Get the installer signature
HASH=`curl -sS https://composer.github.io/installer.sig`

# Download and verify installer
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"

# Install Composer
php composer-setup.php

# Clean up and make globally available
php -r "unlink('composer-setup.php');"
sudo mv composer.phar /usr/local/bin/composer

cd ~
composer --version
```

## Configure PHP for Large Applications

### Update PHP.ini
```bash
sudo nano /etc/php/8.3/fpm/php.ini 
```

Update these settings:
```ini
; Increase maximum file size to upload
upload_max_filesize = 20M

; Increase the maximum size of POST data
post_max_size = 20M

; Increase the maximum execution time (if large files take longer to upload)
max_execution_time = 300

; Increase memory limit
memory_limit = 256M
```

### Restart Services
```bash
# Restart PHP-FPM
sudo service php8.3-fpm restart 

# Reload Nginx
sudo systemctl reload nginx    
```

## Next Steps

Continue with [MySQL Database Setup](./05-mysql-setup.md) for database configuration.
