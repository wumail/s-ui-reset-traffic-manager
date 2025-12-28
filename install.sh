#!/bin/bash

# Configuration
SERVICE_NAME="reset-traffic"
BINARY_SOURCE="./reset-traffic-linux-amd64" # 这是 build.ps1 生成的文件名，请确保上传时一致
INSTALL_PATH="/usr/local/bin/$SERVICE_NAME"
SYSTEMD_PATH="/etc/systemd/system/$SERVICE_NAME.service"

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)."
  exit 1
fi

install_service() {
    echo "Starting installation..."

    # 1. Check if binary exists locally
    if [ ! -f "$BINARY_SOURCE" ]; then
        echo "Error: Binary '$BINARY_SOURCE' not found in current directory."
        echo "Please make sure you have uploaded the compiled linux-amd64 binary."
        exit 1
    fi

    # 2. Copy binary to system path
    cp "$BINARY_SOURCE" "$INSTALL_PATH"
    chmod +x "$INSTALL_PATH"
    echo "Copied binary to $INSTALL_PATH"

    # 3. Create Systemd service file
    cat <<EOF > "$SYSTEMD_PATH"
[Unit]
Description=S-UI Traffic Reset Service (Monthly & HTTP)
After=network.target

[Service]
Type=simple
User=root
ExecStart=$INSTALL_PATH
Restart=on-failure
WorkingDirectory=/usr/local/bin
# 环境变量设置数据库路径 (可选)
# Environment=SUI_DB_PATH=/usr/local/s-ui/db/s-ui.db

[Install]
WantedBy=multi-user.target
EOF

    echo "Created Systemd service at $SYSTEMD_PATH"

    # 4. Reload and start
    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"
    systemctl start "$SERVICE_NAME"

    echo "------------------------------------------------"
    echo "Installation successful!"
    echo "Service Status: $(systemctl is-active $SERVICE_NAME)"
    echo "To check logs, use: journalctl -u $SERVICE_NAME -f"
    echo "HTTP API is now running (default port 52893)."
}

uninstall_service() {
    echo "Starting uninstallation..."

    if [ ! -f "$SYSTEMD_PATH" ]; then
        echo "Service '$SERVICE_NAME' is not installed."
        exit 0
    fi

    systemctl stop "$SERVICE_NAME"
    systemctl disable "$SERVICE_NAME"
    rm "$SYSTEMD_PATH"
    systemctl daemon-reload
    
    if [ -f "$INSTALL_PATH" ]; then
        rm "$INSTALL_PATH"
    fi

    echo "Service '$SERVICE_NAME' has been removed."
}

# Menu
echo "=========================================="
echo "    $SERVICE_NAME Management Script"
echo "=========================================="
echo "1) Install Service"
echo "2) Uninstall Service"
echo "3) Exit"
read -p "Please choose [1-3]: " choice

case $choice in
    1) install_service ;;
    2) uninstall_service ;;
    3) exit 0 ;;
    *) echo "Invalid choice." ;;
esac
