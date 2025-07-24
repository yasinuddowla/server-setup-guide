#!/bin/bash

# Ensure script is run with three arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <db_name> <user_name> <user_password>"
    echo "Example: $0 myapp_db myapp_user mySecurePassword123"
    exit 1
fi

DB_NAME=$1
USER_NAME=$2
USER_PASSWORD=$3

# Prompt for MySQL root password
read -sp "Enter MySQL root password: " MYSQL_ROOT_PASS
echo

# Execute MySQL commands
mysql -u root -p"$MYSQL_ROOT_PASS" <<EOF
-- Create the database
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;

-- Create the user with the specified password
CREATE USER IF NOT EXISTS '$USER_NAME'@'localhost' IDENTIFIED BY '$USER_PASSWORD';

-- Grant all privileges on the database to the user
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$USER_NAME'@'localhost';

-- Flush privileges to ensure changes take effect
FLUSH PRIVILEGES;
EOF

# Check if the MySQL commands were successful
if [ $? -eq 0 ]; then
    echo "Successfully created:"
    echo "  - Database: '$DB_NAME'"
    echo "  - User: '$USER_NAME' with specified password"
    echo "  - Granted all privileges on '$DB_NAME' to '$USER_NAME'"
else
    echo "Error: Failed to create database or user. Please check your MySQL root password and try again."
    exit 1
fi
