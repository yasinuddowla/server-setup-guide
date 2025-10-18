# Nginx Configuration

Complete guide for installing and configuring Nginx web server.

## Install Nginx

```bash
# Only for application servers
sudo apt install nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

## Create Common Configuration Files

### Block Direct Access Configuration
```bash
sudo mkdir /etc/nginx/custom_conf
sudo nano /etc/nginx/custom_conf/block-direct-access.conf
```

Add this content:
```nginx
location ~* \.env$ {
    deny all;
    access_log off;
    return 404;
}
```

### PHP Common Configuration
```bash
sudo nano /etc/nginx/custom_conf/php-common.conf
```

Add this content:
```nginx
location ~ \.php$ {
   include fastcgi_params;
   fastcgi_param CI_ENV production;
   fastcgi_pass unix:/run/php/php8.1-fpm.sock;
   fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
}
```

## Domain Configuration

### Create Domain Config File
```bash
sudo nano /etc/nginx/sites-available/your_domain.conf
```

Basic domain configuration:
```nginx
server {
    listen 80;
    server_name example.com;
    root /var/www/example/;

    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include fastcgi.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
    }

    # Block hidden files (.env, .git, etc.)
    location ~ /\.(?!well-known).* {
        deny all;
        access_log off;
        return 404;
    }
    
    # Optional: block WP paths if not using WP
    location ~* /(wp-admin|wp-includes|wp-content)/ {
        deny all;
    }
    
    # Disable PHP execution in uploads or unexpected dirs
    location ~* /uploads/.*\.php$ {
        deny all;
    }
}
```

### Set Directory Permissions
```bash
# Create directory if it doesn't exist
cd /var/www
sudo mkdir {dir}

# Set proper permissions
sudo chown -R dev:www-data {dir}
sudo chmod -R 775 {dir}
```

## Enable Sites

```bash
# Test configuration
sudo nginx -t

# Disable default site
sudo unlink /etc/nginx/sites-enabled/default

# Enable your domain
sudo ln -s /etc/nginx/sites-available/your_domain.conf /etc/nginx/sites-enabled/

# Reload Nginx
sudo systemctl reload nginx
```

## Configuration for Large File Uploads

### Update Nginx Configuration
```bash
sudo nano /etc/nginx/sites-available/pasta.conf
```

Add inside server block:
```nginx
# Inside server block
client_max_body_size 100M;
```

Restart Nginx:
```bash
sudo systemctl reload nginx
```

## Next Steps

Continue with [PHP & PHP-FPM Setup](./04-php-setup.md) for PHP configuration.
