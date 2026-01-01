#!/bin/bash

# Configuration
SERVICE_NAME="reset-traffic"
INSTALL_PATH="/usr/local/bin/$SERVICE_NAME"
SYSTEMD_PATH="/etc/systemd/system/$SERVICE_NAME.service"
REPO="itning/reset-s-ui-traffic"

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)."
  exit 1
fi

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        BINARY_NAME="reset-traffic-linux-amd64"
        ;;
    aarch64|arm64)
        BINARY_NAME="reset-traffic-linux-arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

install_service() {
    echo "1. Fetching latest release info..."
    # Get the latest release tagging
    LATEST_TAG=$(curl -s https://api.github.com/repos/$REPO/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [ -z "$LATEST_TAG" ]; then
        echo "Error: Could not fetch latest release tag. Please check your network or GitHub API limits."
        exit 1
    fi
    
    DOWNLOAD_URL="https://github.com/$REPO/releases/download/$LATEST_TAG/$BINARY_NAME"
    echo "2. Downloading binary: $BINARY_NAME ($LATEST_TAG)..."
    
    # Download to a temporary location
    TMP_BINARY="/tmp/$BINARY_NAME"
    curl -L "$DOWNLOAD_URL" -o "$TMP_BINARY"
    
    if [ $? -ne 0 ] || [ ! -s "$TMP_BINARY" ]; then
        echo "Error: Download failed or file is empty."
        exit 1
    fi

    echo "3. Installing binary to $INSTALL_PATH..."
    mv "$TMP_BINARY" "$INSTALL_PATH"
    chmod +x "$INSTALL_PATH"

    # 4. Create Systemd service file
    echo "4. Creating Systemd service..."
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

[Install]
WantedBy=multi-user.target
EOF

    # 5. Reload and start
    echo "5. Starting service..."
    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"
    systemctl restart "$SERVICE_NAME"

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

# Run install directly if any argument "install" is passed, otherwise show menu
if [ "$1" == "install" ]; then
    install_service
    exit 0
fi

# Menu
echo "=========================================="
echo "    $SERVICE_NAME One-Click Installer"
echo "=========================================="
echo "1) Install/Update Service (Download Latest)"
echo "2) Uninstall Service"
echo "3) Exit"
read -p "Please choose [1-3]: " choice

case $choice in
    1) install_service ;;
    2) uninstall_service ;;
    3) exit 0 ;;
    *) echo "Invalid choice." ;;
esac
