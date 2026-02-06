# Server Setup Automation Script

An interactive bash script to automate the installation and configuration of a complete server stack for hosting PHP, Node.js, and Python applications.

## Features

- **Interactive Installation**: Prompts for user preferences and versions
- **Selective Installation**: Choose which components to install
- **Version Agnostic**: Specify versions or use latest defaults
- **Comprehensive Stack**: Supports PHP, MySQL, Node.js, Python, Nginx, PM2, Certbot, and Oh My Zsh
- **Logging**: Detailed logs of all installation steps
- **Error Handling**: Graceful error handling with informative messages

## Supported Components

1. **PHP** with extensions and PHP-FPM
   - Version selection (8.1, 8.2, 8.3, or latest)
   - Custom extension selection
   - Optional Composer installation
   - PHP configuration for large applications

2. **MySQL** Database Server
   - Secure installation
   - Root password configuration
   - Optional database and user creation
   - Remote access configuration

3. **Node.js** via NVM
   - Version selection (LTS, latest, or specific version)
   - NVM installation and configuration
   - Persistent shell configuration

4. **Python** with optional Gunicorn
   - System default or specific version
   - Virtual environment support
   - Optional global Gunicorn installation

5. **Nginx** Web Server
   - Installation and basic configuration
   - Common configuration files
   - Configuration validation

6. **PM2** Process Manager
   - Global installation
   - Optional system startup configuration

7. **Certbot** for SSL Certificates
   - Nginx integration
   - Optional SSL certificate generation
   - Automatic renewal setup

8. **Oh My Zsh** Shell Framework
   - Zsh installation
   - Oh My Zsh framework installation
   - Optional prompt customization
   - Optional default shell configuration

## Requirements

- Ubuntu/Debian-based Linux distribution
- Root or sudo access
- Internet connection

## Usage

### Basic Usage

```bash
sudo ./scripts/server-setup.sh
```

### What to Expect

1. **Initial Prompt**: The script will ask which components you want to install
2. **Version Selection**: For PHP, Node.js, and Python, you can specify versions or use defaults
3. **Configuration Options**: Various configuration options will be presented during installation
4. **Installation Progress**: All steps are logged and displayed in real-time

### Example Flow

```
========================================
  Server Setup Automation Script
========================================

[INFO] This script will help you install and configure:
  - PHP with extensions
  - MySQL database server
  - Node.js (via NVM)
  - Python with optional Gunicorn
  - Nginx web server
  - PM2 process manager
  - Certbot for SSL certificates

[INFO] Install PHP? [y/N]: y
[INFO] Install MySQL? [y/N]: y
[INFO] Install Node.js (via NVM)? [y/N]: y
...
```

## Installation Details

### PHP Installation

- Adds Ondrej's PHP PPA repository
- Installs PHP-FPM and CLI
- Allows custom extension selection
- Optional Composer installation
- Configurable PHP settings (upload limits, memory, etc.)

**Example PHP Extensions:**
- mysql, curl, json, mbstring, xml, zip, gd, intl, soap, xmlrpc, openssl, common

### MySQL Installation

- Installs MySQL server and client
- Runs `mysql_secure_installation` (optional)
- Sets root password (optional)
- Creates database and user (optional)
- Configures remote access (optional)

### Node.js Installation

- Installs NVM (Node Version Manager)
- Configures NVM for current and future shell sessions
- Installs selected Node.js version
- Sets default Node.js version

**Version Options:**
- `lts` - Latest LTS version (default)
- `latest` - Latest stable version
- `18`, `20`, etc. - Specific major version
- `20.11.0` - Specific version

### Python Installation

- Installs Python 3 with pip and venv
- Upgrades pip to latest version
- Optional global Gunicorn installation

### Nginx Installation

- Installs and starts Nginx
- Creates common configuration directories
- Sets up basic security configurations
- Validates Nginx configuration

### PM2 Installation

- Installs PM2 globally via npm
- Configures PM2 for system startup (optional)
- Requires Node.js to be installed first

### Certbot Installation

- Installs Certbot with Nginx plugin
- Optionally obtains SSL certificate during installation
- Configures automatic certificate renewal

### Oh My Zsh Installation

- Installs Zsh shell
- Installs Oh My Zsh framework
- Detects target user automatically (or prompts if running as root)
- Optional prompt customization
- Optional default shell configuration
- Note: Requires logout/login for shell change to take effect

## Logs

The script creates two log files:

1. **Main Log**: `/var/log/server-setup-YYYYMMDD-HHMMSS.log`
   - Contains all user-facing messages and important events

2. **Installation Log**: `/tmp/server-setup-install.log`
   - Contains detailed output from all package installations

## Post-Installation

After installation, you may need to:

1. **Configure Nginx Sites**: Create site configurations in `/etc/nginx/sites-available/`
2. **Set Up Applications**: Deploy your PHP, Node.js, or Python applications
3. **Configure Firewall**: Ensure ports 80, 443, and 3306 (if MySQL remote access) are open
4. **Obtain SSL Certificates**: Run `certbot --nginx` for domains not configured during installation
5. **Use Zsh**: If Oh My Zsh was installed, log out and log back in to use the new shell

## Troubleshooting

### PHP-FPM Not Starting

```bash
sudo systemctl status php8.3-fpm
sudo systemctl restart php8.3-fpm
```

### NVM Not Available in New Terminal

The script adds NVM configuration to `~/.bashrc` and `~/.zshrc`. If it's not working:

```bash
source ~/.bashrc  # or source ~/.zshrc
```

### MySQL Connection Issues

```bash
sudo mysql -u root -p
# Check user permissions and database access
```

### Nginx Configuration Errors

```bash
sudo nginx -t
sudo tail -f /var/log/nginx/error.log
```

### Oh My Zsh Not Working

```bash
# Check if Zsh is installed
which zsh
zsh --version

# Check if Oh My Zsh is installed
ls -la ~/.oh-my-zsh

# Manually change shell
chsh -s $(which zsh)

# Reload shell configuration
source ~/.zshrc
```

## Security Considerations

- The script runs with root privileges - review it before execution
- MySQL root password is set during installation
- SSL certificates are obtained via Let's Encrypt (free)
- Firewall configuration is not automated - configure UFW manually if needed

## Customization

You can modify the script to:
- Change default versions
- Add additional PHP extensions
- Modify PHP configuration values
- Add custom Nginx configurations
- Include additional software packages

## Notes

- The script is designed for Ubuntu/Debian-based systems
- All installations use `apt` package manager
- Node.js is installed via NVM (not system packages)
- Python uses system packages (not pyenv)
- PM2 requires Node.js to be installed first

## Contributing

If you find issues or want to add features, please:
1. Test on a clean Ubuntu/Debian system
2. Ensure backward compatibility
3. Update this README with new features
4. Follow the existing code style

## License

This script is part of the Server Setup Guide project.
