#!/bin/bash

# Ensure script is run with two arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <db_name> <user_name>"
    exit 1
fi

DB_NAME=$1
USER_NAME=$2

# Prompt for MySQL root password
read -sp "Enter MySQL root password: " MYSQL_ROOT_PASS

# Execute MySQL commands
mysql -u root -p"$MYSQL_ROOT_PASS" <<EOF
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$USER_NAME'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "Database '$DB_NAME' has been created and assigned to user '$USER_NAME'."