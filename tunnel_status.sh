#!/bin/bash

# Quick tunnel status checker for SN Cars

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🌐 SN Cars Tunnel Status${NC}"
echo "=========================="

# Check if service is running
if launchctl list | grep -q com.sncars.tunnelkeeper; then
    echo -e "${GREEN}✅ Tunnel Keeper Service: RUNNING${NC}"
else
    echo -e "${RED}❌ Tunnel Keeper Service: STOPPED${NC}"
fi

# Check for tunnel URL
if [ -f "/tmp/sn_cars_current_url.txt" ]; then
    TUNNEL_URL=$(cat /tmp/sn_cars_current_url.txt)
    echo -e "${GREEN}✅ Tunnel URL: $TUNNEL_URL${NC}"
    echo -e "${BLUE}📱 Access your app: $TUNNEL_URL/sn_cars/${NC}"
    
    # Test if URL is actually working
    echo -e "${YELLOW}⏳ Testing tunnel connection...${NC}"
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$TUNNEL_URL/sn_cars/status.php" --max-time 10 2>/dev/null)
    if [ "$RESPONSE" = "200" ]; then
        echo -e "${GREEN}✅ Tunnel is ONLINE and working!${NC}"
    else
        echo -e "${RED}❌ Tunnel URL exists but not responding (HTTP $RESPONSE)${NC}"
    fi
else
    echo -e "${RED}❌ No tunnel URL found${NC}"
fi

# Check XAMPP services
echo ""
echo -e "${BLUE}🖥️  XAMPP Services Status${NC}"
echo "========================="

if pgrep -f httpd > /dev/null; then
    echo -e "${GREEN}✅ Apache: RUNNING${NC}"
else
    echo -e "${RED}❌ Apache: STOPPED${NC}"
fi

if pgrep -f mysqld > /dev/null; then
    echo -e "${GREEN}✅ MySQL: RUNNING${NC}"
else
    echo -e "${RED}❌ MySQL: STOPPED${NC}"
fi

# Test local access
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/sn_cars/index.html 2>/dev/null)
if [ "$RESPONSE" = "200" ]; then
    echo -e "${GREEN}✅ Local App: ACCESSIBLE${NC}"
else
    echo -e "${RED}❌ Local App: NOT ACCESSIBLE (HTTP $RESPONSE)${NC}"
fi

echo ""
echo -e "${BLUE}📊 Recent Activity${NC}"
echo "================="

# Show last 5 log entries if available
if [ -f "/tmp/sn_cars_tunnel_keeper.log" ]; then
    echo -e "${YELLOW}Last 5 tunnel keeper events:${NC}"
    tail -n 5 /tmp/sn_cars_tunnel_keeper.log | while read line; do
        echo "  $line"
    done
else
    echo -e "${YELLOW}No tunnel keeper logs found${NC}"
fi

echo ""
echo -e "${BLUE}💡 Useful Commands${NC}"
echo "=================="
echo -e "${YELLOW}View live logs:${NC} tail -f /tmp/sn_cars_tunnel_keeper.log"
echo -e "${YELLOW}Restart service:${NC} launchctl unload ~/Library/LaunchAgents/com.sncars.tunnelkeeper.plist && launchctl load ~/Library/LaunchAgents/com.sncars.tunnelkeeper.plist"
echo -e "${YELLOW}Stop service:${NC} launchctl unload ~/Library/LaunchAgents/com.sncars.tunnelkeeper.plist"
echo -e "${YELLOW}Manual run:${NC} /Applications/XAMPP/xamppfiles/htdocs/sn_cars/auto_tunnel_keeper.sh"

