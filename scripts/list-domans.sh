#!/bin/bash
# List all configured domain names

echo "Configured domains:"
echo "==================="

# Parse nginx configurations and extract domain names
for conf in /etc/nginx/sites-enabled/*; do
    if [ -f "$conf" ]; then
        # Extract server_name values, remove semicolons, and filter out default/localhost
        grep "server_name" "$conf" | \
        sed 's/.*server_name\s*//' | \
        sed 's/;//' | \
        tr ' ' '\n' | \
        grep -v "^$" | \
        grep -v "default_server" | \
        grep -v "localhost" | \
        grep -v "_" | \
        sort -u
    fi
done | sort -u