# Python & Gunicorn Setup

Installation and configuration of Python with Gunicorn WSGI HTTP Server.

## Python Installation

### Update System
```bash
sudo apt update
sudo apt upgrade
```

### Install Python 3 and Required Dependencies
```bash
# Install Python 3 and pip
sudo apt install -y python3 python3-pip python3-venv python3-dev

# Install build essentials (required for some Python packages)
sudo apt install -y build-essential

# Verify installation
python3 --version
pip3 --version
```

### Upgrade pip
```bash
# Upgrade pip to latest version
python3 -m pip install --upgrade pip
```

## Virtual Environment Setup

### Create Virtual Environment
```bash
# Navigate to your project directory
cd /path/to/your/project

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Install project dependencies
pip install -r requirements.txt
```

### Deactivate Virtual Environment
```bash
# When done working, deactivate
deactivate
```

## Gunicorn Global Installation

### Install Gunicorn Globally
```bash
# Install Gunicorn globally using pip3
sudo pip3 install gunicorn

# Verify installation
gunicorn --version
```

### Alternative: Install Gunicorn in Virtual Environment
```bash
# Activate your virtual environment first
source venv/bin/activate

# Install Gunicorn in virtual environment
pip install gunicorn

# Verify installation
gunicorn --version
```

## Gunicorn Basic Usage

### Run Application with Gunicorn
```bash
# Basic usage (from project directory)
gunicorn app:app

# Specify host and port
gunicorn app:app --bind 0.0.0.0:8000

# Run with multiple workers
gunicorn app:app --bind 0.0.0.0:8000 --workers 4

# Run with specific worker class
gunicorn app:app --bind 0.0.0.0:8000 --workers 4 --worker-class gevent

# Run with timeout settings
gunicorn app:app --bind 0.0.0.0:8000 --workers 4 --timeout 120
```

### Common Gunicorn Options
```bash
# Full example with common options
gunicorn app:app \
  --bind 0.0.0.0:8000 \
  --workers 4 \
  --worker-class sync \
  --timeout 120 \
  --keep-alive 5 \
  --max-requests 1000 \
  --max-requests-jitter 50 \
  --log-level info \
  --access-logfile - \
  --error-logfile -
```

## Gunicorn Configuration File

### Create Gunicorn Config File
```bash
# Create configuration file
nano /path/to/your/project/gunicorn_config.py
```

Add configuration:
```python
# Gunicorn configuration file
import multiprocessing

# Server socket
bind = "127.0.0.1:8000"
backlog = 2048

# Worker processes
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = "sync"
worker_connections = 1000
timeout = 120
keepalive = 5

# Logging
accesslog = "/var/log/gunicorn/access.log"
errorlog = "/var/log/gunicorn/error.log"
loglevel = "info"
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s"'

# Process naming
proc_name = "my_python_app"

# Server mechanics
daemon = False
pidfile = "/var/run/gunicorn.pid"
umask = 0
user = None
group = None
tmp_upload_dir = None

# SSL (if needed)
# keyfile = "/path/to/keyfile"
# certfile = "/path/to/certfile"
```

### Run with Configuration File
```bash
# Run Gunicorn using configuration file
gunicorn app:app -c gunicorn_config.py
```

## Systemd Service Setup

### Create Systemd Service File
```bash
sudo nano /etc/systemd/system/my-python-app.service
```

Add service configuration:
```ini
[Unit]
Description=Gunicorn instance to serve my Python application
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/path/to/your/project
Environment="PATH=/path/to/your/project/venv/bin"
ExecStart=/path/to/your/project/venv/bin/gunicorn \
          --workers 4 \
          --bind unix:/path/to/your/project/myapp.sock \
          app:app

[Install]
WantedBy=multi-user.target
```

### Alternative: Using Global Gunicorn Installation
```ini
[Unit]
Description=Gunicorn instance to serve my Python application
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/path/to/your/project
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
ExecStart=/usr/local/bin/gunicorn \
          --workers 4 \
          --bind unix:/path/to/your/project/myapp.sock \
          app:app

[Install]
WantedBy=multi-user.target
```

### Manage Systemd Service
```bash
# Reload systemd daemon
sudo systemctl daemon-reload

# Start service
sudo systemctl start my-python-app

# Enable service to start on boot
sudo systemctl enable my-python-app

# Check status
sudo systemctl status my-python-app

# Restart service
sudo systemctl restart my-python-app

# Stop service
sudo systemctl stop my-python-app

# View logs
sudo journalctl -u my-python-app -f
```

## Nginx Integration

### Create Log Directory
```bash
# Create log directory for Gunicorn
sudo mkdir -p /var/log/gunicorn
sudo chown www-data:www-data /var/log/gunicorn
```

### Nginx Configuration for Python App
```bash
sudo nano /etc/nginx/sites-available/python-app.conf
```

Add Nginx configuration:
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        include proxy_params;
        proxy_pass http://unix:/path/to/your/project/myapp.sock;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static {
        alias /path/to/your/project/static;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    location /media {
        alias /path/to/your/project/media;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
```

### Enable Nginx Site
```bash
# Create symbolic link
sudo ln -s /etc/nginx/sites-available/python-app.conf /etc/nginx/sites-enabled/

# Test Nginx configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

## Common Python Web Frameworks

### Flask Application
```bash
# Example Flask app structure
# app.py
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello, World!'

if __name__ == '__main__':
    app.run()

# Run with Gunicorn
gunicorn app:app --bind 0.0.0.0:8000
```

### Django Application
```bash
# Run Django with Gunicorn
gunicorn myproject.wsgi:application --bind 0.0.0.0:8000

# With settings module
gunicorn myproject.wsgi:application \
  --bind 0.0.0.0:8000 \
  --env DJANGO_SETTINGS_MODULE=myproject.settings.production
```

### FastAPI Application
```bash
# Run FastAPI with Gunicorn
gunicorn main:app --bind 0.0.0.0:8000 --worker-class uvicorn.workers.UvicornWorker

# Install uvicorn workers
pip install uvicorn[standard]
```

## Troubleshooting

### Check Gunicorn Status
```bash
# Check if Gunicorn is running
ps aux | grep gunicorn

# Check socket file
ls -l /path/to/your/project/myapp.sock

# Test socket connection
curl --unix-socket /path/to/your/project/myapp.sock http://localhost/
```

### View Logs
```bash
# Systemd service logs
sudo journalctl -u my-python-app -n 50

# Gunicorn access logs
sudo tail -f /var/log/gunicorn/access.log

# Gunicorn error logs
sudo tail -f /var/log/gunicorn/error.log

# Application logs (if configured)
tail -f /path/to/your/project/logs/app.log
```

### Permission Issues
```bash
# Fix socket file permissions
sudo chown www-data:www-data /path/to/your/project/myapp.sock
sudo chmod 666 /path/to/your/project/myapp.sock

# Fix project directory permissions
sudo chown -R www-data:www-data /path/to/your/project
```

### Restart Services
```bash
# Restart Gunicorn service
sudo systemctl restart my-python-app

# Restart Nginx
sudo systemctl restart nginx

# Restart both
sudo systemctl restart my-python-app nginx
```

### Check Port Conflicts
```bash
# Check if port is in use
sudo netstat -tlnp | grep :8000
sudo lsof -i :8000
```

## Performance Tuning

### Worker Configuration
```bash
# Calculate optimal workers: (2 x CPU cores) + 1
# Example: 4 CPU cores = 9 workers
gunicorn app:app --workers 9 --bind 0.0.0.0:8000
```

### Worker Classes
```bash
# Sync workers (default)
gunicorn app:app --worker-class sync

# Gevent workers (for async I/O)
pip install gevent
gunicorn app:app --worker-class gevent --worker-connections 1000

# Eventlet workers
pip install eventlet
gunicorn app:app --worker-class eventlet
```

### Resource Limits
```bash
# Set timeout for long-running requests
gunicorn app:app --timeout 300

# Limit memory per worker
gunicorn app:app --max-requests 1000 --max-requests-jitter 50
```

## Next Steps

Continue with [SSL Certificates with Certbot](./09-ssl-certbot.md) for HTTPS setup, or [Load Balancer Configuration](./10-load-balancer.md) for multi-server deployment.

