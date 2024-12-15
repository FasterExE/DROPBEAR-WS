#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Ask the user for the desired port for ws.service
read -p "Enter the port you want for Websocket: " port

# Validate the port (should be a number between 1 and 65535)
if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
  echo "Invalid port number. Please enter a number between 1 and 65535."
  exit 1
fi
sudo mkdir /etc/ilyass
sudo mkdir /etc/ilyass/ws
# Update and install Dropbear
echo "Updating package list and installing Dropbear and Node..."
apt update -y && apt install dropbear -y && apt install nodejs -y

# Configure Dropbear
echo "Configuring Dropbear..."
DROPBEAR_CFG="/etc/default/dropbear"

if [ -f "$DROPBEAR_CFG" ]; then
  sed -i 's/^NO_START=1/NO_START=0/' "$DROPBEAR_CFG"
  sed -i 's/^DROPBEAR_EXTRA_ARGS=.*/DROPBEAR_EXTRA_ARGS="-p 143"/' "$DROPBEAR_CFG"
else
  echo "Configuration file not found, creating a new one..."
  cat <<EOL > "$DROPBEAR_CFG"
NO_START=0
DROPBEAR_EXTRA_ARGS="-p 143"
DROPBEAR_PORT=22
DROPBEAR_BANNER=""
DROPBEAR_RECEIVE_WINDOW=65536
EOL
fi

# Enable and start Dropbear service
echo "Enabling and starting Dropbear service..."
systemctl enable dropbear
systemctl restart dropbear

# Verify Dropbear is running
echo "Verifying Dropbear is running on port 143..."
netstat -tuln | grep 143

# Create ws.service file
echo "Creating ws.service..."
WS_SERVICE="/etc/systemd/system/ws.service"
wget -O /etc/ilyass/ws/ws.js https://github.com/FasterExE/DROPBEAR-WS/raw/refs/heads/main/ws.js
cat <<EOL > "$WS_SERVICE"
[Unit]
Description=FREE PALESTINE
Documentation=https://ilyass.xyz/
Documentation=https://t.me/IlyassExE
After=network.target nss-lookup.target

[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/bin/node --expose-gc /etc/ilyass/ws/ws.js -dhost 127.0.0.1 -dport 143 -mport $port
Restart=on-failure
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd and enable ws.service
echo "Reloading systemd and enabling ws.service..."
systemctl daemon-reload
systemctl enable ws.service

# Start ws.service
echo "Starting ws.service..."
systemctl start ws.service

# Verify ws.service is running
echo "Verifying ws.service is running..."

echo "Script execution completed! Dropbear and Websocket are configured."
