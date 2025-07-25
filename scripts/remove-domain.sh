#!/bin/bash
# Remove domain from nginx sites-enabled and clean up SSL certificates

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display usage
show_usage() {
    echo -e "${BLUE}Domain Removal Script${NC}"
    echo "====================================="
    echo "Usage: $0 <domain_name>"
    echo
    echo "This script will:"
    echo "  1. Remove domain from nginx sites-enabled"
    echo "  2. Move sites-available config to trash directory"
    echo "  3. Remove SSL certificates for the domain"
    echo "  4. Reload nginx configuration"
    echo
    echo "Examples:"
    echo "  $0 example.com"
    echo "  $0 api.example.com"
    echo
    exit 1
}

# Check if script is run with correct arguments
if [ "$#" -ne 1 ]; then
    show_usage
fi

DOMAIN=$1

# Validate domain format (basic check)
if [[ ! "$DOMAIN" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
    echo -e "${RED}Error: Invalid domain format: $DOMAIN${NC}"
    exit 1
fi

echo -e "${BLUE}Domain Removal Tool${NC}"
echo "====================================="
echo -e "Domain to remove: ${YELLOW}$DOMAIN${NC}"
echo

# Check if running as root or with sudo
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Error: This script must be run as root or with sudo${NC}"
    echo "Usage: sudo $0 $DOMAIN"
    exit 1
fi

# Function to find nginx config files containing the domain
find_nginx_configs() {
    local domain=$1
    local configs=()
    
    for conf in /etc/nginx/sites-enabled/*; do
        if [ -f "$conf" ] && grep -q "server_name.*$domain" "$conf"; then
            configs+=("$conf")
        fi
    done
    
    printf '%s\n' "${configs[@]}"
}

# Function to backup nginx configuration
backup_nginx_config() {
    local backup_dir="/etc/nginx/backups"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$backup_dir"
    
    echo -e "${BLUE}Creating backup...${NC}"
    tar -czf "$backup_dir/nginx_backup_${timestamp}.tar.gz" /etc/nginx/sites-enabled/ /etc/nginx/sites-available/ 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Backup created: $backup_dir/nginx_backup_${timestamp}.tar.gz${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Warning: Backup creation failed, continuing anyway...${NC}"
        return 1
    fi
}

# Function to remove nginx configuration
remove_nginx_config() {
    local domain=$1
    local removed_files=()
    local trash_dir="/etc/nginx/trash"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    # Create trash directory if it doesn't exist
    mkdir -p "$trash_dir"
    
    echo -e "${BLUE}Searching for nginx configurations...${NC}"
    
    # Find and remove from sites-enabled
    mapfile -t configs < <(find_nginx_configs "$domain")
    
    if [ ${#configs[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠ No nginx configuration found for domain: $domain${NC}"
        return 1
    fi
    
    for config in "${configs[@]}"; do
        if [ -f "$config" ]; then
            echo -e "${YELLOW}Removing: $(basename "$config")${NC}"
            rm "$config"
            if [ $? -eq 0 ]; then
                removed_files+=("$(basename "$config")")
                echo -e "${GREEN}✓ Removed from sites-enabled: $(basename "$config")${NC}"
            else
                echo -e "${RED}✗ Failed to remove: $(basename "$config")${NC}"
                return 1
            fi
        fi
    done
    
    # Move corresponding files from sites-available to trash
    for config in "${configs[@]}"; do
        local available_config="/etc/nginx/sites-available/$(basename "$config")"
        if [ -f "$available_config" ]; then
            local trash_filename="$(basename "$config")_${domain}_${timestamp}"
            echo -e "${BLUE}Found corresponding file in sites-available${NC}"
            echo -e "${YELLOW}Moving to trash: sites-available/$(basename "$config")${NC}"
            
            mv "$available_config" "$trash_dir/$trash_filename"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ Moved to trash: $trash_dir/$trash_filename${NC}"
            else
                echo -e "${RED}✗ Failed to move to trash: $(basename "$config")${NC}"
            fi
        fi
    done
    
    echo -e "${BLUE}💡 Tip: Trashed configurations can be found in: $trash_dir${NC}"
    
    return 0
}

# Function to remove SSL certificates
remove_ssl_certificates() {
    local domain=$1
    
    echo -e "${BLUE}Checking for SSL certificates...${NC}"
    
    # Check if Let's Encrypt certificate exists
    local letsencrypt_dir="/etc/letsencrypt/live/$domain"
    
    if [ -d "$letsencrypt_dir" ]; then
        echo -e "${YELLOW}Found Let's Encrypt certificate for: $domain${NC}"
        echo "Certificate location: $letsencrypt_dir"
        
        read -p "Remove SSL certificate? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Use certbot to delete the certificate
            if command -v certbot >/dev/null 2>&1; then
                echo -e "${BLUE}Removing certificate using certbot...${NC}"
                certbot delete --cert-name "$domain" --non-interactive
                
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}✓ SSL certificate removed successfully${NC}"
                else
                    echo -e "${YELLOW}⚠ Certbot removal failed, trying manual removal...${NC}"
                    # Fallback to manual removal
                    rm -rf "/etc/letsencrypt/live/$domain"
                    rm -rf "/etc/letsencrypt/archive/$domain"
                    rm -f "/etc/letsencrypt/renewal/$domain.conf"
                    echo -e "${GREEN}✓ SSL certificate files removed manually${NC}"
                fi
            else
                echo -e "${YELLOW}⚠ Certbot not found, removing certificate files manually...${NC}"
                rm -rf "/etc/letsencrypt/live/$domain"
                rm -rf "/etc/letsencrypt/archive/$domain"
                rm -f "/etc/letsencrypt/renewal/$domain.conf"
                echo -e "${GREEN}✓ SSL certificate files removed manually${NC}"
            fi
        else
            echo -e "${BLUE}SSL certificate kept${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ No Let's Encrypt certificate found for: $domain${NC}"
    fi
}

# Function to test and reload nginx
reload_nginx() {
    echo -e "${BLUE}Testing nginx configuration...${NC}"
    
    nginx -t
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Nginx configuration test passed${NC}"
        
        echo -e "${BLUE}Reloading nginx...${NC}"
        systemctl reload nginx
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Nginx reloaded successfully${NC}"
            return 0
        else
            echo -e "${RED}✗ Failed to reload nginx${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ Nginx configuration test failed!${NC}"
        echo -e "${YELLOW}Please check your nginx configuration before manually reloading${NC}"
        return 1
    fi
}

# Function to show summary
show_summary() {
    local domain=$1
    local trash_dir="/etc/nginx/trash"
    
    echo
    echo -e "${BLUE}Removal Summary for: $domain${NC}"
    echo "====================================="
    
    # Check if domain still exists in nginx configs
    mapfile -t remaining_configs < <(find_nginx_configs "$domain")
    
    if [ ${#remaining_configs[@]} -eq 0 ]; then
        echo -e "${GREEN}✓ Domain removed from nginx configuration${NC}"
    else
        echo -e "${RED}✗ Domain still found in nginx configuration${NC}"
        for config in "${remaining_configs[@]}"; do
            echo -e "  - $(basename "$config")"
        done
    fi
    
    # Check SSL certificate status
    if [ -d "/etc/letsencrypt/live/$domain" ]; then
        echo -e "${YELLOW}⚠ SSL certificate still exists${NC}"
    else
        echo -e "${GREEN}✓ SSL certificate removed${NC}"
    fi
    
    # Check nginx status
    if systemctl is-active --quiet nginx; then
        echo -e "${GREEN}✓ Nginx is running${NC}"
    else
        echo -e "${RED}✗ Nginx is not running${NC}"
    fi
    
    # Show trash directory info
    if [ -d "$trash_dir" ] && [ "$(ls -A "$trash_dir" 2>/dev/null)" ]; then
        echo -e "${BLUE}📁 Backup configurations available in: $trash_dir${NC}"
        echo -e "${BLUE}💡 To restore: mv $trash_dir/[config_file] /etc/nginx/sites-available/ && ln -s /etc/nginx/sites-available/[config_file] /etc/nginx/sites-enabled/${NC}"
    fi
}

# Main execution
echo -e "${YELLOW}⚠ WARNING: This will permanently remove the domain configuration and SSL certificates!${NC}"
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Operation cancelled${NC}"
    exit 0
fi

echo
echo -e "${BLUE}Starting domain removal process...${NC}"
echo

# Step 1: Create backup
backup_nginx_config

# Step 2: Remove nginx configuration
if remove_nginx_config "$DOMAIN"; then
    echo
    
    # Step 3: Remove SSL certificates
    remove_ssl_certificates "$DOMAIN"
    echo
    
    # Step 4: Reload nginx
    if reload_nginx; then
        echo
        echo -e "${GREEN}✓ Domain removal completed successfully!${NC}"
    else
        echo
        echo -e "${YELLOW}⚠ Domain removed but nginx reload failed${NC}"
        echo -e "${YELLOW}Please check nginx configuration and reload manually${NC}"
    fi
else
    echo
    echo -e "${RED}✗ Failed to remove domain configuration${NC}"
    exit 1
fi

# Step 5: Show summary
show_summary "$DOMAIN"

echo
echo -e "${GREEN}Domain removal process completed!${NC}"
