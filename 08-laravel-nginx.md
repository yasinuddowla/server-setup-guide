# Laravel Nginx Configuration

Optimized Nginx configuration specifically for Laravel applications.

## Laravel-Specific Nginx Configuration

### Create Laravel Site Configuration
```bash
sudo nano /etc/nginx/sites-available/laravel-site.conf
```

### Laravel Nginx Configuration Template
```nginx
server {
    listen 80;
    listen [::]:80;
    server_name example.com;
    root /srv/example.com/public;
 
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
 
    index index.php;
 
    charset utf-8;
 
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
 
    location = /favicon.ico { 
        access_log off; 
        log_not_found off; 
    }
    
    location = /robots.txt  { 
        access_log off; 
        log_not_found off; 
    }
 
    error_page 404 /index.php;
 
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
    }
 
    location ~ /\.(?!well-known).* {
        deny all;
    }
}
```

## SSL-Enabled Laravel Configuration

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name example.com;
    root /srv/example.com/public;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    
    # SSL Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    index index.php;
    charset utf-8;

    # Laravel Routes
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    # Optimize static files
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Block access to sensitive files
    location = /favicon.ico { 
        access_log off; 
        log_not_found off; 
    }
    
    location = /robots.txt  { 
        access_log off; 
        log_not_found off; 
    }

    # Error pages
    error_page 404 /index.php;

    # PHP handling
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
        
        # Laravel-specific FastCGI parameters
        fastcgi_param PHP_VALUE "upload_max_filesize=100M \n post_max_size=100M";
        fastcgi_buffer_size 128k;
        fastcgi_buffers 4 256k;
        fastcgi_busy_buffers_size 256k;
    }

    # Block access to hidden files
    location ~ /\.(?!well-known).* {
        deny all;
    }

    # Block access to Laravel-specific files
    location ~ /\.(env|git|gitignore|gitattributes|composer\.json|composer\.lock|package\.json|package-lock\.json|yarn\.lock) {
        deny all;
        access_log off;
        return 404;
    }
}
```

## Laravel Performance Optimizations

### PHP-FPM Pool Configuration for Laravel
```bash
sudo nano /etc/php/8.3/fpm/pool.d/laravel.conf
```

```ini
[laravel]
user = www-data
group = www-data
listen = /run/php/php8.3-fpm-laravel.sock
listen.owner = www-data
listen.group = www-data
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.process_idle_timeout = 10s
```

### Laravel Environment Configuration
```bash
# Set proper permissions for Laravel
sudo chown -R www-data:www-data /srv/example.com
sudo chmod -R 755 /srv/example.com
sudo chmod -R 775 /srv/example.com/storage
sudo chmod -R 775 /srv/example.com/bootstrap/cache
```

## Enable Laravel Site

```bash
# Test configuration
sudo nginx -t

# Enable the site
sudo ln -s /etc/nginx/sites-available/laravel-site.conf /etc/nginx/sites-enabled/

# Reload Nginx
sudo systemctl reload nginx
```

## Laravel-Specific Commands

### Clear Laravel Caches
```bash
cd /srv/example.com
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear
```

### Optimize Laravel for Production
```bash
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan optimize
```

## Troubleshooting Laravel Issues

### Common Laravel + Nginx Issues

1. **500 Internal Server Error**
   - Check Laravel logs: `tail -f storage/logs/laravel.log`
   - Check Nginx error logs: `sudo tail -f /var/log/nginx/error.log`

2. **Permission Issues**
   ```bash
   sudo chown -R www-data:www-data storage bootstrap/cache
   sudo chmod -R 775 storage bootstrap/cache
   ```

3. **Route Not Found**
   - Ensure `try_files` directive includes `/index.php?$query_string`
   - Clear route cache: `php artisan route:clear`

## Next Steps

Continue with [SSL Certificates with Certbot](./09-ssl-certbot.md) to secure your Laravel application.
