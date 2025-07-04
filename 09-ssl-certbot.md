# SSL Certificates with Certbot

Complete guide for setting up SSL certificates using Let's Encrypt and Certbot.

## Install Certbot

### For Nginx
```bash
sudo apt install certbot python3-certbot-nginx -y
```

### For Apache (if needed)
```bash
sudo apt install certbot python3-certbot-apache -y
```

## SSL Certificate Setup

### Automatic Certificate Installation (Recommended)
```bash
sudo certbot --nginx
```

This command will:
1. Automatically detect your Nginx sites
2. Generate SSL certificates
3. Update Nginx configuration
4. Set up HTTP to HTTPS redirects

### Manual Certificate Generation
```bash
sudo certbot certonly --nginx -d example.com -d www.example.com
```

### Webroot Method (for custom setups)
```bash
sudo certbot certonly \
  --webroot \
  --webroot-path=/var/www/html \
  --email your-email@example.com \
  --agree-tos \
  --no-eff-email \
  -d example.com \
  -d www.example.com
```

## Certificate Management

### Check Certificate Status
```bash
sudo certbot certificates
```

### Test Certificate Renewal
```bash
sudo certbot renew --dry-run
```

### Force Certificate Renewal
```bash
sudo certbot renew --force-renewal
```

### Renew Specific Certificate
```bash
sudo certbot renew --cert-name example.com
```

## Automatic Renewal Setup

### Check Certbot Timer Status
```bash
sudo systemctl status certbot.timer
```

### Enable Automatic Renewal
```bash
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

### Manual Cron Setup (alternative)
Add to crontab (`sudo crontab -e`):
```bash
0 12 * * * /usr/bin/certbot renew --quiet
```

## SSL Configuration Best Practices

### Strong SSL Configuration for Nginx
```nginx
server {
    listen 443 ssl http2;
    server_name example.com;

    # SSL Certificate paths
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    # Modern SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;

    # HSTS (HTTP Strict Transport Security)
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # OCSP stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;

    # Your site configuration continues here...
}
```

### HTTP to HTTPS Redirect
```nginx
server {
    listen 80;
    server_name example.com www.example.com;
    return 301 https://$server_name$request_uri;
}
```

## Troubleshooting

### Common Certificate Issues

1. **Rate Limiting**
   ```bash
   # Check rate limits
   certbot certificates
   
   # Use staging environment for testing
   sudo certbot --staging --nginx
   ```

2. **Domain Validation Failures**
   ```bash
   # Ensure domain points to your server
   dig example.com
   
   # Check firewall settings
   sudo ufw status
   ```

3. **Nginx Configuration Issues**
   ```bash
   # Test Nginx configuration
   sudo nginx -t
   
   # Check Nginx error logs
   sudo tail -f /var/log/nginx/error.log
   ```

### Certificate Renewal Issues
```bash
# Check renewal process
sudo systemctl status certbot.timer

# View renewal logs
sudo journalctl -u certbot.timer

# Manual renewal with verbose output
sudo certbot renew --dry-run --verbose
```

## Wildcard Certificates

### Generate Wildcard Certificate
```bash
sudo certbot certonly \
  --manual \
  --preferred-challenges=dns \
  --email your-email@example.com \
  --server https://acme-v02.api.letsencrypt.org/directory \
  --agree-tos \
  -d *.example.com \
  -d example.com
```

**Note:** Wildcard certificates require DNS validation.

## Multiple Domain Certificates

### Single Certificate for Multiple Domains
```bash
sudo certbot certonly --nginx \
  -d example.com \
  -d www.example.com \
  -d api.example.com \
  -d admin.example.com
```

## SSL Certificate Backup

### Backup Certificates
```bash
sudo tar -czf letsencrypt-backup-$(date +%Y%m%d).tar.gz /etc/letsencrypt/
```

### Restore Certificates
```bash
sudo tar -xzf letsencrypt-backup-YYYYMMDD.tar.gz -C /
sudo systemctl reload nginx
```

## Security Considerations

1. **Enable port 443** in your firewall/security groups
2. **Use strong SSL configurations** as shown above
3. **Monitor certificate expiration** dates
4. **Keep Certbot updated** regularly
5. **Test renewals** periodically

## Next Steps

Continue with [Load Balancer Configuration](./10-load-balancer.md) for advanced traffic management and scalability.
