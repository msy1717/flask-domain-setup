#!/bin/bash

echo "🚀 Starting Firewall Setup..."

# Update system
sudo apt update -y

# Install UFW if not installed
sudo apt install ufw -y

# Reset old rules (optional)
sudo ufw --force reset

# Default rules
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (IMPORTANT)
sudo ufw allow 22/tcp

# Allow common ports
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Predefined ports
sudo ufw allow 3000/tcp
sudo ufw allow 5000/tcp
sudo ufw allow 6000/tcp
sudo ufw allow 7000/tcp
sudo ufw allow 7777/tcp
sudo ufw allow 8080/tcp

# UDP default
sudo ufw allow 6000/udp
sudo ufw allow 7000/udp

echo ""
echo "============================"
echo "🔧 Custom Port Setup"
echo "============================"

# Ask user for custom ports
read -p "Enter custom ports (comma separated, e.g. 6600,9000) or press Enter to skip: " PORTS

if [ -n "$PORTS" ]; then
    read -p "Protocol (tcp/udp/both): " PROTOCOL

    # Split ports
    IFS=',' read -ra PORT_ARRAY <<< "$PORTS"

    for PORT in "${PORT_ARRAY[@]}"; do
        PORT=$(echo $PORT | xargs)  # trim spaces

        if [ "$PROTOCOL" == "tcp" ]; then
            sudo ufw allow $PORT/tcp
            echo "✅ Allowed TCP port $PORT"

        elif [ "$PROTOCOL" == "udp" ]; then
            sudo ufw allow $PORT/udp
            echo "✅ Allowed UDP port $PORT"

        elif [ "$PROTOCOL" == "both" ]; then
            sudo ufw allow $PORT/tcp
            sudo ufw allow $PORT/udp
            echo "✅ Allowed TCP & UDP port $PORT"

        else
            echo "❌ Invalid protocol for port $PORT (skipped)"
        fi
    done
else
    echo "⚠️ No custom ports added"
fi

# Enable firewall
sudo ufw --force enable

# Show status
sudo ufw status verbose

echo "✅ Firewall setup complete!"
