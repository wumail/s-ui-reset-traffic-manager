#!/bin/bash

# One-Click Deployment Script
# Downloads the reset-traffic-sui management tool

REPO="wumail/s-ui-reset-traffic-manager"
SCRIPT_URL="https://raw.githubusercontent.com/$REPO/master/reset-traffic-sui.sh"
INSTALL_SCRIPT="/usr/local/bin/reset-traffic-sui"

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)."
  exit 1
fi

echo "=========================================="
echo "  S-UI Traffic Deployment Script"
echo "=========================================="
echo ""
echo "Downloading management tool..."

# Download the management script to permanent location
if ! curl -L "$SCRIPT_URL" -o "$INSTALL_SCRIPT"; then
    echo "Error: Failed to download management tool."
    exit 1
fi

if [ ! -s "$INSTALL_SCRIPT" ]; then
    echo "Error: Downloaded file is empty."
    exit 1
fi

chmod +x "$INSTALL_SCRIPT"

echo ""
echo "✓ Management tool installed successfully!"
echo ""
echo "Location: $INSTALL_SCRIPT"
echo ""
echo "To manage the service, run:"
echo "  sudo reset-traffic-sui"
echo ""
echo "Available options:"
echo "  1. Install reset-traffic service"
echo "  2. Update reset-traffic service"
echo "  3. Uninstall reset-traffic service"
echo "  4-8. Configuration and management"
