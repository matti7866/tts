#!/bin/bash

# Setup script for Auto Tunnel Keeper
# This will set up your SN Cars tunnel to run automatically and recover from disconnections

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🚀 SN Cars Auto Tunnel Setup${NC}"
echo -e "${YELLOW}This will set up automatic tunnel management for your SN Cars application${NC}"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}❌ Please don't run this script as root/sudo${NC}"
    exit 1
fi

# Get current directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo -e "${BLUE}📋 Setup Steps:${NC}"
echo "1. Make scripts executable"
echo "2. Install LaunchAgent for auto-start"
echo "3. Start the tunnel keeper service"
echo ""

# Step 1: Make scripts executable
echo -e "${BLUE}Step 1: Making scripts executable...${NC}"
chmod +x "$SCRIPT_DIR/auto_tunnel_keeper.sh"
chmod +x "$SCRIPT_DIR/start_tunnel.sh"
echo -e "${GREEN}✅ Scripts are now executable${NC}"

# Step 2: Install LaunchAgent
echo -e "${BLUE}Step 2: Installing LaunchAgent...${NC}"
LAUNCHAGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_FILE="com.sncars.tunnelkeeper.plist"

# Create LaunchAgents directory if it doesn't exist
mkdir -p "$LAUNCHAGENTS_DIR"

# Copy the plist file
cp "$SCRIPT_DIR/$PLIST_FILE" "$LAUNCHAGENTS_DIR/"
echo -e "${GREEN}✅ LaunchAgent installed${NC}"

# Step 3: Load and start the service
echo -e "${BLUE}Step 3: Starting tunnel keeper service...${NC}"

# Stop any existing service first
launchctl unload "$LAUNCHAGENTS_DIR/$PLIST_FILE" 2>/dev/null || true
sleep 2

# Load the new service
if launchctl load "$LAUNCHAGENTS_DIR/$PLIST_FILE"; then
    echo -e "${GREEN}✅ Tunnel keeper service started${NC}"
else
    echo -e "${RED}❌ Failed to start service${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Setup Complete!${NC}"
echo ""
echo -e "${BLUE}What happens now:${NC}"
echo "• Your tunnel will start automatically when your Mac boots"
echo "• If the tunnel disconnects, it will automatically reconnect"
echo "• The system monitors your tunnel every 30 seconds"
echo "• Logs are saved to /tmp/sn_cars_tunnel_keeper.log"
echo ""
echo -e "${BLUE}🔧 Management Commands:${NC}"
echo -e "${YELLOW}Check status:${NC} launchctl list | grep sncars"
echo -e "${YELLOW}Stop service:${NC} launchctl unload ~/Library/LaunchAgents/$PLIST_FILE"
echo -e "${YELLOW}Start service:${NC} launchctl load ~/Library/LaunchAgents/$PLIST_FILE"
echo -e "${YELLOW}View logs:${NC} tail -f /tmp/sn_cars_tunnel_keeper.log"
echo -e "${YELLOW}Manual run:${NC} $SCRIPT_DIR/auto_tunnel_keeper.sh"
echo ""
echo -e "${BLUE}📱 Monitor your tunnel:${NC}"
echo "• Current URL: cat /tmp/sn_cars_current_url.txt"
echo "• Service logs: tail -f /tmp/sn_cars_tunnel_service.log"
echo ""

# Wait a moment and check if service is running
sleep 5
if launchctl list | grep -q com.sncars.tunnelkeeper; then
    echo -e "${GREEN}✅ Service is running!${NC}"
    
    # Wait a bit more for tunnel to establish
    echo -e "${BLUE}⏳ Waiting for tunnel to establish...${NC}"
    sleep 15
    
    if [ -f "/tmp/sn_cars_current_url.txt" ]; then
        TUNNEL_URL=$(cat /tmp/sn_cars_current_url.txt)
        echo -e "${GREEN}🌐 Your SN Cars app is now accessible at:${NC}"
        echo -e "${YELLOW}$TUNNEL_URL/sn_cars/${NC}"
        echo ""
        echo -e "${GREEN}💡 Save this URL - it will automatically reconnect if it goes down!${NC}"
    else
        echo -e "${YELLOW}⏳ Tunnel is starting up... Check the URL in a few minutes with:${NC}"
        echo -e "${YELLOW}cat /tmp/sn_cars_current_url.txt${NC}"
    fi
else
    echo -e "${RED}❌ Service doesn't appear to be running. Check the logs:${NC}"
    echo -e "${YELLOW}tail /tmp/sn_cars_tunnel_service_error.log${NC}"
fi

echo ""
echo -e "${PURPLE}🏠 Perfect for remote access! Your tunnel will stay online even when you're away from home.${NC}"

