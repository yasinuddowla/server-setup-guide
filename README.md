# Server Setup Guide

A comprehensive guide for setting up and configuring servers with various technologies.

## Table of Contents

### Core Server Setup
- [Initial Server Setup](./01-initial-server-setup.md) - User creation, SSH security, and basic configuration
- [Ubuntu System Management](./02-ubuntu-system.md) - System updates, timezone, and essential tools

### Web Server Stack
- [Nginx Configuration](./03-nginx-setup.md) - Installation, configuration, and domain setup
- [PHP & PHP-FPM Setup](./04-php-setup.md) - PHP installation and configuration
- [MySQL Database Setup](./05-mysql-setup.md) - Database installation and configuration

### Application Deployment
- [Docker Deployment](./06-docker-deployment.md) - Docker and Docker Compose setup
- [Node.js & PM2 Setup](./07-nodejs-pm2.md) - Node.js installation and process management
- [Python & Gunicorn Setup](./13-python-setup.md) - Python installation and Gunicorn WSGI server
- [Laravel Configuration](./08-laravel-nginx.md) - Laravel-specific Nginx configuration

### Security & SSL
- [SSL Certificates with Certbot](./09-ssl-certbot.md) - SSL setup and automation
- [Load Balancer Configuration](./10-load-balancer.md) - Load balancing setup

### Troubleshooting & Maintenance
- [Debugging & Logs](./11-debugging.md) - Common debugging techniques and log locations
- [Domain Management](./12-domain-management.md) - DNS and domain configuration examples

---

## Quick Start

For a basic LAMP stack setup, follow these guides in order:
1. [Initial Server Setup](./01-initial-server-setup.md)
2. [Ubuntu System Management](./02-ubuntu-system.md)
3. [Nginx Configuration](./03-nginx-setup.md)
4. [PHP & PHP-FPM Setup](./04-php-setup.md)
5. [MySQL Database Setup](./05-mysql-setup.md)
6. [SSL Certificates with Certbot](./09-ssl-certbot.md)

## Contributing

We welcome contributions from developers who want to improve this server setup guide! Here's how you can contribute:

### How to Contribute

1. **Fork the Repository**
   - Fork this repository to your GitHub account
   - Clone your fork locally: `git clone https://github.com/your-username/server-setup-guide.git`

2. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-contribution-name
   ```

3. **Make Your Changes**
   - Follow the existing documentation structure and formatting
   - Test your configurations on a clean server environment when possible
   - Ensure commands are compatible with Ubuntu/Debian systems

### Types of Contributions Welcome

- **New Technology Guides**: Add setup guides for new technologies (Redis, PostgreSQL, etc.)
- **Security Improvements**: Enhanced security configurations and best practices
- **Performance Optimizations**: Server performance tuning and optimization guides
- **Troubleshooting**: Common issues and their solutions
- **Alternative Configurations**: Different approaches for existing setups
- **Bug Fixes**: Corrections to existing documentation or commands

### Documentation Standards

- **File Naming**: Use descriptive names with numbers for ordering (e.g., `13-redis-setup.md`)
- **Structure**: Follow the existing format with clear headings and step-by-step instructions
- **Code Blocks**: Use proper syntax highlighting for shell commands
- **Testing**: Verify all commands and configurations work as documented
- **Cross-references**: Link to related sections when applicable

### Submission Guidelines

1. **Update the README**: Add your new guide to the Table of Contents
2. **Commit Messages**: Use clear, descriptive commit messages
3. **Pull Request**: 
   - Provide a clear description of your changes
   - Include testing information if applicable
   - Reference any related issues

### Code Style

- Use consistent formatting for shell commands
- Include explanations for complex configurations
- Add comments in configuration files where helpful
- Use proper markdown formatting

### Getting Help

- Open an issue for questions or suggestions
- Check existing documentation before adding duplicate content
- Feel free to discuss major changes before implementing them

Thank you for helping make this guide better for the entire community!
