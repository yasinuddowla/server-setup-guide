# Ubuntu System Management

System updates, timezone configuration, and maintenance tasks.

## Initial System Update

```bash
sudo apt update
sudo apt upgrade -y
sudo timedatectl set-timezone Asia/Dhaka
```

## Ubuntu Version Upgrade

### Standard Upgrade
```bash
sudo apt update
sudo apt upgrade
sudo apt dist-upgrade
```

### Distribution Upgrade
```bash
sudo do-release-upgrade
```

## Disable Apache2 (if installed)

If Apache2 is installed and you want to use Nginx instead:

```bash
sudo systemctl stop apache2
sudo systemctl disable apache2
```

## System Maintenance

### Check System Status
```bash
systemctl status
```

### Monitor System Resources
```bash
htop
df -h
free -h
```

## Next Steps

Continue with [Nginx Configuration](./03-nginx-setup.md) for web server setup.
