# Debugging & Logs

Comprehensive guide for debugging server issues and analyzing logs.

## Nginx Debugging

### Check Nginx Error Logs
```bash
# View recent errors
sudo tail /var/log/nginx/error.log

# Follow errors in real-time
sudo tail -f /var/log/nginx/error.log

# View specific number of lines
sudo tail -n 100 /var/log/nginx/error.log
```

### Check Nginx Access Logs
```bash
# View access logs
sudo tail /var/log/nginx/access.log

# Follow access logs
sudo tail -f /var/log/nginx/access.log

# Filter by specific domain
sudo grep "example.com" /var/log/nginx/access.log
```

### Test Nginx Configuration
```bash
# Test configuration syntax
sudo nginx -t

# Test and show configuration details
sudo nginx -T

# Reload configuration if test passes
sudo nginx -t && sudo systemctl reload nginx
```

## PHP Debugging

### PHP Error Logs
```bash
# Check PHP-FPM error logs
sudo tail -f /var/log/php8.3-fpm.log

# Check specific pool logs
sudo tail -f /var/log/php/8.3/fpm/error.log
```

### PHP Configuration Check
```bash
# Check PHP version and configuration
php -v
php --ini

# Check PHP-FPM status
sudo systemctl status php8.3-fpm

# Check PHP-FPM pools
sudo php-fpm8.3 -t
```

## MySQL Debugging

### MySQL Error Logs
```bash
# Check MySQL error logs
sudo tail -f /var/log/mysql/error.log

# Check MySQL slow query log
sudo tail -f /var/log/mysql/slow.log
```

### MySQL Status and Performance
```bash
# Check MySQL status
sudo systemctl status mysql

# MySQL process list
mysql -u root -p -e "SHOW PROCESSLIST;"

# MySQL status variables
mysql -u root -p -e "SHOW STATUS LIKE 'Threads%';"
```

## System-Level Debugging

### Check System Resources
```bash
# Memory usage
free -h

# Disk usage
df -h

# CPU usage
top
htop

# I/O statistics
iostat -x 1

# Network connections
netstat -tulpn
ss -tulpn
```

### Check Running Processes
```bash
# Find processes using specific ports
sudo lsof -i :80
sudo lsof -i :443
sudo lsof -i :3000

# Check specific service status
sudo systemctl status nginx
sudo systemctl status php8.3-fpm
sudo systemctl status mysql
```

## Application-Specific Debugging

### PM2 Debugging
```bash
# Check PM2 status
pm2 status

# View PM2 logs
pm2 logs

# View specific application logs
pm2 logs app_name

# Monitor PM2 processes
pm2 monit

# Restart application
pm2 restart app_name
```

### Docker Debugging
```bash
# Check container status
docker ps -a

# View container logs
docker logs container_name

# Follow container logs
docker logs -f container_name

# Execute commands in container
docker exec -it container_name bash

# Check Docker Compose services
docker-compose ps
docker-compose logs
```

## SSL/Certificate Debugging

### Check Certificate Status
```bash
# Check certificate expiration
sudo certbot certificates

# Test certificate
openssl x509 -in /etc/letsencrypt/live/example.com/cert.pem -text -noout

# Check SSL connection
openssl s_client -connect example.com:443 -servername example.com
```

### SSL Configuration Test
```bash
# Test SSL configuration online
# Use: https://www.ssllabs.com/ssltest/

# Local SSL test
curl -I https://example.com
```

## Network Debugging

### DNS Resolution
```bash
# Check DNS resolution
dig example.com
nslookup example.com

# Check reverse DNS
dig -x IP_ADDRESS
```

### Connectivity Tests
```bash
# Test port connectivity
telnet example.com 80
nc -zv example.com 80

# Trace network route
traceroute example.com
mtr example.com
```

### Firewall Debugging
```bash
# Check UFW status
sudo ufw status verbose

# Check iptables rules
sudo iptables -L -n

# Check listening ports
sudo netstat -tlnp
```

## Log Analysis Tools

### Using grep for Log Analysis
```bash
# Find errors in last hour
sudo grep "$(date -d '1 hour ago' '+%d/%b/%Y:%H')" /var/log/nginx/error.log

# Count specific errors
sudo grep -c "404" /var/log/nginx/access.log

# Find large files requests
sudo awk '$10 > 1000000' /var/log/nginx/access.log
```

### Real-time Log Monitoring
```bash
# Monitor multiple logs simultaneously
sudo multitail /var/log/nginx/error.log /var/log/nginx/access.log

# Using journalctl for systemd services
sudo journalctl -u nginx -f
sudo journalctl -u php8.3-fpm -f
```

## Performance Debugging

### Nginx Performance
```bash
# Check nginx worker processes
ps aux | grep nginx

# Check nginx status (if status module enabled)
curl http://localhost/nginx_status
```

### Database Performance
```bash
# MySQL performance variables
mysql -u root -p -e "SHOW VARIABLES LIKE 'max_connections';"

# Check slow queries
mysql -u root -p -e "SHOW VARIABLES LIKE 'slow_query_log';"
```

## Common Issues and Solutions

### 502 Bad Gateway
```bash
# Check if PHP-FPM is running
sudo systemctl status php8.3-fpm

# Check PHP-FPM socket
sudo ls -la /var/run/php/

# Check nginx error logs
sudo tail /var/log/nginx/error.log
```

### 504 Gateway Timeout
```bash
# Check PHP execution time
grep max_execution_time /etc/php/8.3/fpm/php.ini

# Check nginx timeout settings
grep timeout /etc/nginx/nginx.conf
```

### Permission Issues
```bash
# Check file permissions
ls -la /var/www/

# Fix common permission issues
sudo chown -R www-data:www-data /var/www/your-site/
sudo chmod -R 755 /var/www/your-site/
```

## Debugging Commands Cheat Sheet

```bash
# Service status
sudo systemctl status service_name

# Service logs
sudo journalctl -u service_name -f

# Process information
ps aux | grep process_name

# Port usage
sudo lsof -i :port_number

# Disk usage by directory
du -sh /path/to/directory

# Find large files
find /path -type f -size +100M

# Check memory usage by process
ps aux --sort=-%mem | head

# Network connections by process
sudo netstat -tulpn | grep process_name
```

## Log Rotation and Cleanup

### Configure Log Rotation
```bash
# Check logrotate configuration
sudo cat /etc/logrotate.d/nginx

# Manually rotate logs
sudo logrotate -f /etc/logrotate.d/nginx
```

### Clean Old Logs
```bash
# Find and remove old logs
find /var/log -name "*.log" -mtime +30 -delete

# Compress old logs
find /var/log -name "*.log" -mtime +7 -exec gzip {} \;
```

## Next Steps

Continue with [Domain Management](./12-domain-management.md) for DNS and domain configuration examples.
