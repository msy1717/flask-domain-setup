#!/bin/bash

echo "🚀 Cloudflare Tunnel Auto Setup"

# ===== USER INPUT =====
read -p "Enter Flask app directory (e.g. /home/ubuntu/app): " APP_DIR
read -p "Enter Flask port (e.g. 7000): " PORT
read -p "Enter domain (e.g. demo.example.com): " DOMAIN
read -p "Enter tunnel name (e.g. flask-app): " TUNNEL_NAME

VENV_DIR="$APP_DIR/venv"

# ===== INSTALL CLOUDLFARED =====
if ! command -v cloudflared &> /dev/null
then
    echo "📦 Installing cloudflared..."
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
    chmod +x cloudflared-linux-amd64
    sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
fi

# ===== LOGIN CHECK =====
if [ ! -f "$HOME/.cloudflared/cert.pem" ]; then
    echo "🔑 Login to Cloudflare..."
    cloudflared tunnel login
fi

# ===== CREATE TUNNEL =====
if ! cloudflared tunnel list | grep -q "$TUNNEL_NAME"; then
    echo "🌐 Creating tunnel..."
    cloudflared tunnel create $TUNNEL_NAME
fi

# ===== GET TUNNEL ID =====
TUNNEL_ID=$(cloudflared tunnel list | grep $TUNNEL_NAME | awk '{print $1}')

echo "Tunnel ID: $TUNNEL_ID"

# ===== CREATE CONFIG =====
CONFIG_FILE="$HOME/.cloudflared/config.yml"

echo "⚙️ Creating config.yml..."

cat > $CONFIG_FILE <<EOL
tunnel: $TUNNEL_ID
credentials-file: $HOME/.cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: $DOMAIN
    service: http://localhost:$PORT
  - service: http_status:404
EOL

# ===== CREATE DNS ROUTE =====
echo "🌍 Linking domain..."
cloudflared tunnel route dns $TUNNEL_NAME $DOMAIN

# ===== START FLASK IN TMUX =====
echo "🐍 Starting Flask..."

tmux kill-session -t flask 2>/dev/null

tmux new -d -s flask "
cd $APP_DIR
source $VENV_DIR/bin/activate
python3.11 main.py
"

# ===== START TUNNEL IN TMUX =====
echo "🌐 Starting Tunnel..."

tmux kill-session -t tunnel 2>/dev/null

tmux new -d -s tunnel "
cloudflared tunnel run $TUNNEL_NAME
"

echo ""
echo "✅ SETUP COMPLETE!"
echo "🌍 URL: https://$DOMAIN"
echo ""
echo "Use: tmux attach -t flask   (Flask logs)"
echo "Use: tmux attach -t tunnel  (Tunnel logs)"
