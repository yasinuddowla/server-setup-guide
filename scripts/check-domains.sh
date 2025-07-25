#!/bin/bash
# Check status of all configured domains dynamically from nginx sites-enabled

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Domain Status Checker${NC}"
echo "====================================="
echo

# Function to extract domains from nginx config files
extract_domains() {
    local domains=()
    
    # Parse nginx configurations and extract domain names
    for conf in /etc/nginx/sites-enabled/*; do
        if [ -f "$conf" ]; then
            # Extract server_name values, remove semicolons, and filter out default/localhost
            while IFS= read -r domain; do
                if [[ -n "$domain" && "$domain" != "default_server" && "$domain" != "localhost" && "$domain" != "_" ]]; then
                    domains+=("$domain")
                fi
            done < <(grep "server_name" "$conf" | \
                    sed 's/.*server_name\s*//' | \
                    sed 's/;//' | \
                    tr ' ' '\n' | \
                    grep -v "^$" | \
                    grep -v "default_server" | \
                    grep -v "localhost" | \
                    grep -v "_")
        fi
    done
    
    # Remove duplicates and sort
    printf '%s\n' "${domains[@]}" | sort -u
}

# Function to check HTTP status
check_http_status() {
    local domain=$1
    local status
    
    # Try HTTPS first, then HTTP
    status=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 --max-time 30 "https://$domain" 2>/dev/null)
    
    if [[ "$status" == "000" ]]; then
        # HTTPS failed, try HTTP
        status=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 --max-time 30 "http://$domain" 2>/dev/null)
        echo "$status (HTTP only)"
    else
        if [[ "$status" =~ ^2[0-9][0-9]$ ]]; then
            echo "$status"
        elif [[ "$status" =~ ^3[0-9][0-9]$ ]]; then
            echo "$status (Redirect)"
        else
            echo "$status (Error)"
        fi
    fi
}

# Function to check SSL certificate
check_ssl_certificate() {
    local domain=$1
    local expiry
    local days_until_expiry
    
    # Get SSL certificate expiration date
    expiry=$(echo | timeout 10 openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | \
             openssl x509 -noout -dates 2>/dev/null | \
             grep notAfter | cut -d= -f2)
    
    if [[ -n "$expiry" ]]; then
        # Calculate days until expiration
        if command -v gdate >/dev/null 2>&1; then
            # macOS with GNU coreutils
            expiry_epoch=$(gdate -d "$expiry" +%s 2>/dev/null)
            current_epoch=$(gdate +%s)
        else
            # Linux or macOS with BSD date
            expiry_epoch=$(date -j -f "%b %d %T %Y %Z" "$expiry" +%s 2>/dev/null || date -d "$expiry" +%s 2>/dev/null)
            current_epoch=$(date +%s)
        fi
        
        if [[ -n "$expiry_epoch" && -n "$current_epoch" ]]; then
            days_until_expiry=$(( (expiry_epoch - current_epoch) / 86400 ))
            echo "$days_until_expiry days"
        else
            echo "Valid"
        fi
    else
        echo "No SSL"
    fi
}

# Function to check DNS resolution
check_dns() {
    local domain=$1
    local ip
    
    ip=$(dig +short "$domain" A 2>/dev/null | head -1)
    
    if [[ -n "$ip" && "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "$ip"
    else
        echo "Failed"
    fi
}

# Function to format and print table row
print_table_row() {
    local domain=$1
    local dns=$2
    local http=$3
    local ssl=$4
    
    # Color coding based on status
    local dns_color=""
    local http_color=""
    local ssl_color=""
    
    # DNS coloring
    if [[ "$dns" == "Failed" ]]; then
        dns_color="${RED}"
    else
        dns_color="${GREEN}"
    fi
    
    # HTTP coloring
    if [[ "$http" == *"Error"* ]] || [[ "$http" == "000"* ]]; then
        http_color="${RED}"
    elif [[ "$http" == *"Redirect"* ]] || [[ "$http" == *"HTTP only"* ]]; then
        http_color="${YELLOW}"
    else
        http_color="${GREEN}"
    fi
    
    # SSL coloring
    if [[ "$ssl" == "No SSL" ]]; then
        ssl_color="${RED}"
    elif [[ "$ssl" =~ ^[0-9]+.*days$ ]]; then
        local days=$(echo "$ssl" | grep -o '^[0-9]*')
        if [[ $days -gt 30 ]]; then
            ssl_color="${GREEN}"
        elif [[ $days -gt 7 ]]; then
            ssl_color="${YELLOW}"
        else
            ssl_color="${RED}"
        fi
    else
        ssl_color="${GREEN}"
    fi
    
    printf "| %-40s | ${dns_color}%-15s${NC} | ${http_color}%-20s${NC} | ${ssl_color}%-15s${NC} |\n" \
           "$domain" "$dns" "$http" "$ssl"
}

# Main execution
echo "Extracting domains from nginx configuration..."
echo

# Get unique domains from nginx configs
mapfile -t domains < <(extract_domains)

if [[ ${#domains[@]} -eq 0 ]]; then
    echo -e "${RED}No domains found in nginx configuration!${NC}"
    echo "Make sure nginx sites are enabled in /etc/nginx/sites-enabled/"
    exit 1
fi

echo -e "Found ${#domains[@]} domain(s) to check"
echo

# Print table header
echo -e "${BLUE}Domain Status Report${NC}"
printf "+------------------------------------------+-----------------+----------------------+-----------------+\n"
printf "| %-40s | %-15s | %-20s | %-15s |\n" "Domain" "DNS" "HTTP Status" "SSL Expiry"
printf "+------------------------------------------+-----------------+----------------------+-----------------+\n"

# Check each domain and display results immediately
for domain in "${domains[@]}"; do
    # Get all status information
    dns_status=$(check_dns "$domain")
    http_status=$(check_http_status "$domain")
    ssl_status=$(check_ssl_certificate "$domain")
    
    # Display result immediately
    print_table_row "$domain" "$dns_status" "$http_status" "$ssl_status"
done

printf "+------------------------------------------+-----------------+----------------------+-----------------+\n"
echo
echo -e "${GREEN}Domain check completed!${NC}"
