# Load Balancer Configuration

Setting up Nginx as a load balancer for distributing traffic across multiple servers or applications.

## Basic Load Balancer Setup

### Upstream Configuration
```nginx
# Define upstream servers
upstream backend {
    server 192.168.1.10:3000;
    server 192.168.1.11:3000;
    server 192.168.1.12:3000;
}

server {
    listen 80;
    server_name example.com;

    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Advanced Load Balancing Methods

### Weighted Round Robin
```nginx
upstream backend {
    server 192.168.1.10:3000 weight=3;
    server 192.168.1.11:3000 weight=2;
    server 192.168.1.12:3000 weight=1;
}
```

### IP Hash (Session Persistence)
```nginx
upstream backend {
    ip_hash;
    server 192.168.1.10:3000;
    server 192.168.1.11:3000;
    server 192.168.1.12:3000;
}
```

### Least Connections
```nginx
upstream backend {
    least_conn;
    server 192.168.1.10:3000;
    server 192.168.1.11:3000;
    server 192.168.1.12:3000;
}
```

## Kube Load Balancer Example

### Load Balancer Configuration
```nginx
# Staging environment
upstream staging {
    server 18.169.153.145:9009;
}

server {
    listen 80;
    server_name staging.kube.money;

    location / {
        proxy_pass http://staging;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### Port Mapping for Multiple Services
```nginx
# Main application
upstream main_app {
    server 192.168.1.10:3000;
}

# API service
upstream api_service {
    server 192.168.1.10:9001;
}

# Assets service
upstream assets_service {
    server 192.168.1.10:9002;
}

# Console service
upstream console_service {
    server 192.168.1.10:9003;
}

# Main domain
server {
    listen 80;
    server_name kube.money;
    
    location / {
        proxy_pass http://main_app;
        include /etc/nginx/proxy_params;
    }
}

# API subdomain
server {
    listen 80;
    server_name api.kube.money;
    
    location / {
        proxy_pass http://api_service;
        include /etc/nginx/proxy_params;
    }
}

# Assets subdomain
server {
    listen 80;
    server_name assets.kube.money;
    
    location / {
        proxy_pass http://assets_service;
        include /etc/nginx/proxy_params;
    }
}

# Console subdomain
server {
    listen 80;
    server_name console.kube.money;
    
    location / {
        proxy_pass http://console_service;
        include /etc/nginx/proxy_params;
    }
}
```

## Proxy Parameters Configuration

### Create Common Proxy Configuration
```bash
sudo nano /etc/nginx/proxy_params
```

Add these parameters:
```nginx
proxy_set_header Host $http_host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_buffering off;
```

## Health Checks and Failover

### Server Health Monitoring
```nginx
upstream backend {
    server 192.168.1.10:3000 max_fails=3 fail_timeout=30s;
    server 192.168.1.11:3000 max_fails=3 fail_timeout=30s;
    server 192.168.1.12:3000 backup;  # Backup server
}
```

### Custom Health Check Location
```nginx
server {
    listen 80;
    server_name example.com;

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    location / {
        proxy_pass http://backend;
        include /etc/nginx/proxy_params;
    }
}
```

## SSL Load Balancer Configuration

### HTTPS Load Balancer
```nginx
upstream backend {
    server 192.168.1.10:3000;
    server 192.168.1.11:3000;
}

server {
    listen 80;
    server_name example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## WebSocket Support

### WebSocket Proxy Configuration
```nginx
upstream websocket {
    server 192.168.1.10:3001;
}

server {
    listen 80;
    server_name ws.example.com;

    location / {
        proxy_pass http://websocket;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## Rate Limiting

### Basic Rate Limiting
```nginx
http {
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    
    server {
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            proxy_pass http://backend;
        }
    }
}
```

## Monitoring and Logging

### Enable Detailed Logging
```nginx
http {
    log_format upstream_time '$remote_addr - $remote_user [$time_local] '
                           '"$request" $status $body_bytes_sent '
                           '"$http_referer" "$http_user_agent"'
                           'rt=$request_time uct="$upstream_connect_time" '
                           'uht="$upstream_header_time" urt="$upstream_response_time"';
    
    access_log /var/log/nginx/upstream.log upstream_time;
}
```

## Troubleshooting Load Balancer

### Check Upstream Status
```bash
# Test upstream servers individually
curl -I http://192.168.1.10:3000/health
curl -I http://192.168.1.11:3000/health
```

### Monitor Connection Status
```bash
# Check nginx status
sudo systemctl status nginx

# View error logs
sudo tail -f /var/log/nginx/error.log

# Check active connections
sudo netstat -tlnp | grep nginx
```

### Performance Tuning
```nginx
worker_processes auto;
worker_connections 1024;

# In http block
keepalive_timeout 65;
keepalive_requests 100;

# In upstream block
upstream backend {
    keepalive 32;
    server 192.168.1.10:3000;
    server 192.168.1.11:3000;
}
```

## Next Steps

Continue with [Debugging & Logs](./11-debugging.md) for comprehensive troubleshooting techniques.
