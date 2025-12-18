# MySQL Database Setup

Installation and configuration of MySQL database server.

## Install MySQL

```bash
sudo apt install mysql-server
```

## Install MySQL Client

```bash
# Only for application servers
sudo apt install mysql-client
```

## Initial MySQL Setup

### Set Root Password
```bash
sudo mysql
```

Run these commands in MySQL:
```sql
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';
FLUSH PRIVILEGES;
exit;
```

### Secure Installation
```bash
sudo mysql_secure_installation
```

## Create Database and User

```bash
sudo mysql -u root -p
```

Database and user creation:
```sql
CREATE DATABASE db_name;
CREATE USER 'user'@'localhost' IDENTIFIED BY 'pass';
GRANT ALL ON db_name.* TO 'user'@'localhost';
FLUSH PRIVILEGES;
exit;
```

## Configure Remote MySQL Access

### Edit MySQL Configuration
```bash
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
```

Update the bind-address setting to allow remote connections:
```ini
bind-address = 0.0.0.0
```

### Restart MySQL
```bash
sudo systemctl restart mysql.service
```

### Test Remote Connection
```bash
# Test remote connection
sudo mysql -u remote_admin -h [IP_ADDRESS] -p 
```

## Import Database

For large SQL files (30MB+), this might take more than 10 minutes:
```bash
mysql -u username -p database_name < backup.sql
```

## Security Notes

1. Open port `3306` for DB server
2. Use strong passwords for database users
3. Limit remote access to specific IP addresses when possible
4. Regularly backup your databases

## Next Steps

Continue with [Docker Deployment](./06-docker-deployment.md) for containerized application deployment.
