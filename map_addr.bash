#!/bin/bash

# You need to uncomment this line from /etc/sysctl.conf before running this script:
# net.ipv4.ip_forward = 1
# Then apply changes using
# $ sudo sysctl -p

function usage {
    echo "Simple utility to locally map one address:port combination to another using NGINX reverse-proxy functionality"
    echo "WARNING: this utility uses NGINX and is meant only for http/https connection mapping"
    echo "Available subcommands:"
    echo "    add    <old-address>:<old-port> <new-address>:<new-port> - add new mapping"
    echo "        Example: '$0 add 127.0.0.1:3000 lanraragi.lan:80' will redirect http://lanraragi.lan to 127.0.0.1:3000"
    echo "    remove <new-address>                                     - remove mapping for this address"
    echo "        Example: '$0 remove lanraragi.lan' will remove everything added to your config files with '$0 add'"
    exit 1
}

if ! command -v nginx &> /dev/null
then
    echo "nginx could not be found. Please install nginx first."
    exit 1
fi

function add_mapping {
    # Parse adresses and ports
    OLD_FULL_ADDR=$1
    NEW_FULL_ADDR=$2

    OLD_ADDR="${OLD_FULL_ADDR%:*}"
    OLD_PORT="${OLD_FULL_ADDR##*:}"
    NEW_ADDR="${NEW_FULL_ADDR%:*}"
    NEW_PORT="${NEW_FULL_ADDR##*:}"

    # Add address mapping to /etc/hosts
    if ! grep -q "$NEW_ADDR" /etc/hosts; then
        echo "Mapping $OLD_ADDR to $NEW_ADDR in /etc/hosts"
        echo "$OLD_ADDR  $NEW_ADDR" | sudo tee -a /etc/hosts > /dev/null
    else
        echo "$NEW_ADDR already exists in /etc/hosts"
    fi

    # Create Nginx configuration for reverse proxy
    NGINX_CONF="/etc/nginx/sites-available/$NEW_ADDR"
    if [[ ! -f "$NGINX_CONF" ]]; then
        echo "Creating Nginx config for $NEW_ADDR"
        sudo tee "$NGINX_CONF" > /dev/null <<EOT
server {
    listen $NEW_PORT;
    server_name $NEW_ADDR;

    location / {
        proxy_pass http://$OLD_FULL_ADDR;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOT
    # Enable config
        sudo ln -s "$NGINX_CONF" "/etc/nginx/sites-enabled/"
    else
        echo "Nginx config for $NEW_ADDR already exists"
    fi

    # Test Nginx configuration
    if ! sudo nginx -t; then
        echo "Nginx configuration test failed"
        exit 1
    fi

    echo "Reloading Nginx..."
    sudo systemctl restart nginx

    echo "Port mapping from $OLD_FULL_ADDR to $NEW_FULL_ADDR successfully applied."
}

function remove_mapping {
    NEW_ADDR=$1

    # Remove the entry from /etc/hosts
    if grep -q "$NEW_ADDR" /etc/hosts; then
        echo "Removing $NEW_ADDR from /etc/hosts"
        sudo sed -i "/$NEW_ADDR/d" /etc/hosts
    else
        echo "$NEW_ADDR not found in /etc/hosts"
    fi

    # Remove the Nginx config
    NGINX_CONF="/etc/nginx/sites-available/$NEW_ADDR"
    if [[ -f "$NGINX_CONF" ]]; then
        echo "Removing Nginx config for $NEW_ADDR"
        sudo rm "$NGINX_CONF"
        sudo rm "/etc/nginx/sites-enabled/$NEW_ADDR" 2>/dev/null
    else
        echo "Nginx config for $NEW_ADDR not found"
    fi

    # Test Nginx configuration
    if ! sudo nginx -t; then
        echo "Nginx configuration test failed"
        exit 1
    fi

    echo "Reloading Nginx..."
    sudo systemctl restart nginx

    echo "Port mapping for $NEW_ADDR successfully removed."
}

if [[ $# -lt 1 ]]; then
    usage
fi

case "$1" in
    add)
        if [[ $# -ne 3 ]]; then
            usage
        fi
        add_mapping "$2" "$3"
        ;;
    remove)
        if [[ $# -ne 2 ]]; then
            usage
        fi
        remove_mapping "$2"
        ;;
    *)
        usage
        ;;
esac
