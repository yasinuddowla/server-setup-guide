# Docker Deployment

Complete guide for Docker and Docker Compose setup and deployment.

## Prerequisites

- Server with Ubuntu/Debian
- Non-root user with sudo privileges
- Code uploaded to server

## Upload Code to Server

```bash
rsync -avz ./ user@ip:~/docker-test/
```

## Install Docker

### Update System
```bash
sudo apt update && sudo apt upgrade -y
```

### Install Docker
```bash
sudo apt install docker.io -y
```

### Install Docker Compose
```bash
sudo apt install docker-compose -y
```

### Enable Docker Service
```bash
sudo systemctl enable docker
sudo systemctl start docker
```

### Add User to Docker Group
```bash
sudo usermod -aG docker $USER
```

**Note:** Log out and log back in, or run `newgrp docker` to apply group changes.

## Deploy Application

### Run Docker Compose
```bash
cd ~/docker-test
docker-compose up -d
```

### Check Running Containers
```bash
docker ps
docker-compose logs
```

## SSL Setup with Certbot

**Important:** Enable port 443 on AWS/cloud provider first.

```bash
docker run -it --rm \
  --network docker-test_app-network \
  -v "$(pwd)/app:/var/www/html" \
  -v "$(pwd)/certbot/conf:/etc/letsencrypt" \
  -v "$(pwd)/certbot/logs:/var/log/letsencrypt" \
  certbot/certbot certonly \
  --webroot \
  --webroot-path=/var/www/html \
  --email yasinuddowla@gmail.com \
  --agree-tos \
  --no-eff-email \
  -d test.yasinuddowla.com
```

## Common Docker Commands

### Container Management
```bash
# Stop all containers
docker-compose down

# Restart containers
docker-compose restart

# View logs
docker-compose logs -f [service_name]

# Execute commands in container
docker-compose exec [service_name] bash
```

### Cleanup
```bash
# Remove unused containers
docker container prune

# Remove unused images
docker image prune

# Remove unused volumes
docker volume prune
```

## Docker Compose Example

Basic `docker-compose.yml` structure:
```yaml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "80:80"
    volumes:
      - ./app:/var/www/html
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
```

## Troubleshooting

### Check Container Status
```bash
docker ps -a
docker logs [container_id]
```

### Network Issues
```bash
docker network ls
docker network inspect [network_name]
```

## Next Steps

For traditional server setup without Docker, continue with [Node.js & PM2 Setup](./07-nodejs-pm2.md).
