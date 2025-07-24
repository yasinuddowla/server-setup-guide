# Node.js & PM2 Setup

Installation and configuration of Node.js with PM2 process manager.

## Node.js Installation

### Update System
```bash
sudo apt update
sudo apt upgrade
```

### Install Required Dependencies
```bash
sudo apt install -y curl
```

### Install Node.js (Version 20)
```bash
# Download Node.js setup script
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# Install Node.js
sudo apt install -y nodejs

# Verify installation
node --version
npm --version
```

## PM2 Installation and Setup

### Install PM2 Globally
```bash
sudo npm install pm2 -g
```

### Configure PM2 for System Startup
```bash
# Configure PM2 to start on system boot
pm2 startup

# Follow the instructions provided by the command above
```

## PM2 Commands

### Basic Process Management
```bash
# Start an application
pm2 start app.js

# Start with a custom name
pm2 start app.js --name "my-app"

# Start with environment variables
pm2 start app.js --name "my-app" --env production
```

### Process Control
```bash
# Restart application
pm2 restart app_name

# Reload application (zero-downtime)
pm2 reload app_name

# Stop application
pm2 stop app_name

# Delete application from PM2
pm2 delete app_name
```

### Monitoring and Logs
```bash
# List all processes
pm2 list

# Monitor processes in real-time
pm2 monit

# View logs
pm2 logs
pm2 logs app_name

# View specific number of log lines
pm2 logs --lines 200
```

### Save and Restore
```bash
# Save current PM2 configuration
pm2 save

# Update PM2
pm2 update
```

## PM2 Ecosystem File

Create `ecosystem.config.js` for advanced configuration:

```javascript
module.exports = {
  apps: [{
    name: 'my-app',
    script: 'app.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'development'
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 3000
    }
  }]
};
```

Start with ecosystem file:
```bash
pm2 start ecosystem.config.js --env production
```

## Load Balancer Integration

When using with Nginx load balancer:

1. **Start Nginx first**
2. **Then start PM2 processes**

### Example Nginx Upstream Configuration
```nginx
upstream staging {
    server 18.169.153.145:9009;
}

server {
    listen 80;
    server_name staging.example.com;

    location / {
        proxy_pass http://staging;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

## Troubleshooting

### Check PM2 Status
```bash
pm2 status
pm2 info app_name
```

### Resource Usage
```bash
pm2 monit
```

### Restart All Processes
```bash
pm2 restart all
```

## Next Steps

Continue with [Laravel Configuration](./08-laravel-nginx.md) for PHP framework setup.
