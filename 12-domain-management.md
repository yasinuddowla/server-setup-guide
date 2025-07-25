# Domain Management

DNS configuration, domain examples, and deployment considerations.

## DNS Configuration

### Basic DNS Records
```dns
# A Records (IPv4)
@               IN A     192.168.1.100
www             IN A     192.168.1.100
api             IN A     192.168.1.100

# AAAA Records (IPv6)
@               IN AAAA  2001:db8::1
www             IN AAAA  2001:db8::1

# CNAME Records
blog            IN CNAME www.example.com.
shop            IN CNAME www.example.com.

# MX Records (Email)
@               IN MX    10 mail.example.com.

# TXT Records
@               IN TXT   "v=spf1 include:_spf.google.com ~all"
_dmarc          IN TXT   "v=DMARC1; p=none; rua=mailto:dmarc@example.com"
```

### SSL Certificate DNS Validation
```dns
# For Let's Encrypt DNS validation
_acme-challenge IN TXT   "verification-string-here"
```

## Multi-Domain Nginx Configuration

### Single Server Block for Multiple Domains
```nginx
server {
    listen 80;
    server_name example.com www.example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name example.com www.example.com;
    
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    
    root /var/www/example.com;
    index index.php index.html;
    
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    
    location ~ \.php$ {
        include fastcgi.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
    }
}
```

### Subdomain Configuration
```nginx
# API subdomain
server {
    listen 443 ssl http2;
    server_name api.example.com;
    
    ssl_certificate /etc/letsencrypt/live/api.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.example.com/privkey.pem;
    
    location / {
        proxy_pass http://localhost:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Assets subdomain
server {
    listen 443 ssl http2;
    server_name assets.example.com;
    
    ssl_certificate /etc/letsencrypt/live/assets.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/assets.example.com/privkey.pem;
    
    root /var/www/assets;
    
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|pdf|zip)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Access-Control-Allow-Origin "*";
    }
}
```

## Domain Setup Checklist

### Pre-Deployment Checklist
1. **DNS Configuration**
   - A/AAAA records pointing to server IP
   - CNAME records for subdomains (if needed)
   - MX records for email (if needed)
   - TTL values set appropriately

2. **Security Groups/Firewall**
   - Port 80 (HTTP) open
   - Port 443 (HTTPS) open
   - Port 22 (SSH) restricted to specific IPs
   - Port 3306 (MySQL) open only for DB server

3. **SSL Certificates**
   - Certificates generated for all domains
   - Auto-renewal configured
   - Certificate includes all necessary domains

### Post-Deployment Checklist
1. **GitHub Configuration**
   - SSH private keys updated in repository secrets
   - Server names updated in deployment scripts
   - Deploy via GitHub Actions or manual upload

2. **Database Setup**
   - Database imported (allow 10+ minutes for large files)
   - Database user permissions configured
   - Remote access configured if needed

3. **Testing**
   - All domains accessible via HTTPS
   - SSL certificates valid
   - Application functionality verified
   - Performance acceptable

## Wildcard Domain Configuration

### Wildcard SSL Certificate
```bash
# Generate wildcard certificate
sudo certbot certonly \
  --manual \
  --preferred-challenges=dns \
  --email admin@example.com \
  --server https://acme-v02.api.letsencrypt.org/directory \
  --agree-tos \
  -d *.example.com \
  -d example.com
```

### Wildcard Nginx Configuration
```nginx
server {
    listen 443 ssl http2;
    server_name *.example.com;
    
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    
    # Extract subdomain
    set $subdomain "";
    if ($host ~* "^(.+)\.example\.com$") {
        set $subdomain $1;
    }
    
    # Route based on subdomain
    location / {
        if ($subdomain = "api") {
            proxy_pass http://localhost:3001;
        }
        if ($subdomain = "admin") {
            proxy_pass http://localhost:3002;
        }
        # Default route
        proxy_pass http://localhost:3000;
    }
}
```

## Domain Monitoring

### Check Domain Status Script
```bash
#!/bin/bash
# domains-check.sh

domains=(
    "example.com"
    "api.example.com"
    "assets.example.com"
    "admin.example.com"
)

for domain in "${domains[@]}"; do
    echo "Checking $domain..."
    
    # Check HTTP status
    status=$(curl -s -o /dev/null -w "%{http_code}" "https://$domain")
    echo "  HTTP Status: $status"
    
    # Check SSL certificate expiration
    expiry=$(echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | openssl x509 -noout -dates | grep notAfter | cut -d= -f2)
    echo "  SSL Expires: $expiry"
    
    echo ""
done
```

### List Domains Script
Create `scripts/list-domains.sh`:
```bash
#!/bin/bash
# List all configured domains and their ports

echo "Configured domains and ports:"
echo "================================"

# Parse nginx configurations
for conf in /etc/nginx/sites-enabled/*; do
    if [ -f "$conf" ]; then
        echo "Configuration: $(basename $conf)"
        grep -E "server_name|listen|proxy_pass" "$conf" | sed 's/^/  /'
        echo ""
    fi
done
```

## Domain Migration

### Pre-Migration Steps
1. **Backup current configuration**
   ```bash
   sudo tar -czf nginx-backup-$(date +%Y%m%d).tar.gz /etc/nginx/
   sudo tar -czf ssl-backup-$(date +%Y%m%d).tar.gz /etc/letsencrypt/
   ```

2. **Test new configuration**
   ```bash
   sudo nginx -t
   ```

### DNS Propagation Check
```bash
# Check DNS propagation
dig @8.8.8.8 example.com
dig @1.1.1.1 example.com

# Check from multiple locations
# Use online tools like: whatsmydns.net
```

## Troubleshooting Domain Issues

### Common Domain Problems

1. **Domain not resolving**
   ```bash
   # Check DNS resolution
   nslookup example.com
   dig example.com
   
   # Check DNS propagation
   dig @8.8.8.8 example.com
   ```

2. **SSL certificate issues**
   ```bash
   # Check certificate
   sudo certbot certificates
   
   # Test SSL connection
   openssl s_client -connect example.com:443
   ```

3. **Subdomain not working**
   ```bash
   # Check nginx configuration
   sudo nginx -t
   
   # Check subdomain DNS
   dig subdomain.example.com
   ```

## Performance Optimization

### CDN Configuration
```nginx
# Set appropriate headers for CDN
location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    add_header Vary "Accept-Encoding";
    
    # CORS headers for CDN
    add_header Access-Control-Allow-Origin "*";
    add_header Access-Control-Allow-Methods "GET, OPTIONS";
}
```

### DNS Performance
```dns
# Use shorter TTL for testing, longer for production
@    300  IN A     192.168.1.100  # 5 minutes (testing)
@    3600 IN A     192.168.1.100  # 1 hour (production)
```

## Congratulations!

🎉 You've completed the comprehensive server setup guide! Your server should now be fully configured with:

- Secure initial setup and user management
- Ubuntu system optimization
- Nginx web server with domain configuration
- PHP and MySQL for dynamic applications
- Docker for containerized deployments
- Node.js with PM2 for JavaScript applications
- Laravel framework configuration
- SSL certificates for secure HTTPS
- Load balancing for scalability
- Debugging tools and techniques
- Domain and DNS management

### What's Next?

- **Monitor your server**: Set up monitoring tools like Grafana, Prometheus, or New Relic
- **Implement backups**: Regular database and file system backups
- **Security audits**: Regular security updates and vulnerability scans
- **Performance optimization**: Fine-tune based on your application's specific needs
- **Scaling**: Consider adding more servers behind your load balancer as traffic grows

### Contributing

Found an issue or want to improve this guide? Check out our [Contributing Guidelines](./README.md#contributing) to get started!
