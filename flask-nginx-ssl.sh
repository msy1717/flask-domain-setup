#!/bin/bash

# 🚨 Prompt user for input
read -p "Enter full path to your Flask app directory: " APP_DIR
read -p "Enter domain name (e.g., demo.acexwin.com): " DOMAIN
read -p "Enter Flask app port (e.g., 6600): " PORT
read -p "Enter tmux session name (e.g., demo): " TMUX_SESSION
read -p "Enter email for SSL certificate: " EMAIL

VENV_DIR="$APP_DIR/venv"

# -------------------------------
# Step 0: Install prerequisites
# -------------------------------
sudo apt update
sudo apt install -y nginx nano certbot python3-certbot-nginx tmux

# -------------------------------
# Step 1: Configure Nginx
# -------------------------------
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"
sudo bash -c "cat > $NGINX_CONF" <<EOL
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# -------------------------------
# Step 2: Start Flask in tmux
# -------------------------------
tmux new-session -d -s $TMUX_SESSION "cd $APP_DIR && source $VENV_DIR/bin/activate && export FLASK_APP=app.py && flask run --host=0.0.0.0 --port=$PORT"

# -------------------------------
# Step 3: Setup SSL
# -------------------------------
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m $EMAIL --redirect

# -------------------------------
# Done
# -------------------------------
echo "✅ Flask app is live on https://$DOMAIN"
echo "Flask app running in tmux session '$TMUX_SESSION' on port $PORT"
echo "Use 'tmux attach -t $TMUX_SESSION' to view logs"
