#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting online access for sn_cars Labour Cards Database...${NC}"
echo -e "${YELLOW}This will make your application accessible online via Cloudflare tunnel.${NC}"
echo ""

# Check if XAMPP is running
echo -e "${BLUE}📋 Checking XAMPP status...${NC}"
if ! pgrep -f httpd > /dev/null; then
    echo -e "${RED}❌ Apache is not running! Please start XAMPP first.${NC}"
    echo -e "${YELLOW}💡 Open XAMPP Control Panel and start Apache + MySQL${NC}"
    exit 1
fi

if ! pgrep -f mysqld > /dev/null; then
    echo -e "${RED}❌ MySQL is not running! Please start XAMPP MySQL.${NC}"
    echo -e "${YELLOW}💡 Open XAMPP Control Panel and start MySQL${NC}"
    exit 1
fi

echo -e "${GREEN}✅ XAMPP services are running${NC}"

# Test local access first
echo -e "${BLUE}🔍 Testing local application...${NC}"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/sn_cars/index.html)
if [ "$RESPONSE" = "200" ]; then
    echo -e "${GREEN}✅ Local application is accessible${NC}"
else
    echo -e "${RED}❌ Local application not accessible (HTTP $RESPONSE)${NC}"
    echo -e "${YELLOW}💡 Check that files are in: /Applications/XAMPP/xamppfiles/htdocs/sn_cars/${NC}"
    exit 1
fi

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    echo -e "${RED}❌ cloudflared is not installed${NC}"
    echo -e "${YELLOW}💡 Install with: brew install cloudflared${NC}"
    echo -e "${YELLOW}💡 Or download from: https://github.com/cloudflare/cloudflared/releases${NC}"
    exit 1
fi

echo -e "${GREEN}✅ cloudflared is installed${NC}"
echo ""

# Start the tunnel in the background
echo -e "${BLUE}🌐 Starting Cloudflare tunnel...${NC}"
cloudflared tunnel --url http://localhost:80 > /tmp/tunnel_output.log 2>&1 &
TUNNEL_PID=$!

echo -e "${BLUE}⏳ Tunnel started with PID: $TUNNEL_PID${NC}"
echo -e "${BLUE}⏳ Waiting for tunnel to establish...${NC}"

# Wait a few seconds for the tunnel to establish
sleep 8

# Try to extract the URL from the log
if [ -f /tmp/tunnel_output.log ]; then
    echo -e "${BLUE}📋 Tunnel Output:${NC}"
    cat /tmp/tunnel_output.log
    echo ""
    
    # Look for the tunnel URL with multiple attempts
    TUNNEL_URL=""
    for i in {1..3}; do
        TUNNEL_URL=$(grep -o 'https://.*\.trycloudflare\.com' /tmp/tunnel_output.log | head -1)
        if [ ! -z "$TUNNEL_URL" ]; then
            break
        fi
        echo -e "${YELLOW}⏳ Attempt $i: Waiting for tunnel URL...${NC}"
        sleep 3
    done
    
    if [ ! -z "$TUNNEL_URL" ]; then
        echo -e "${GREEN}🎉 SUCCESS! Your Labour Cards Database is now accessible online!${NC}"
        echo ""
        echo -e "${GREEN}🌐 Main Application:${NC}"
        echo -e "   ${TUNNEL_URL}/sn_cars/"
        echo ""
        echo -e "${GREEN}📊 Direct Access URLs:${NC}"
        echo -e "   • Search Interface: ${TUNNEL_URL}/sn_cars/index.html"
        echo -e "   • Status Check: ${TUNNEL_URL}/sn_cars/status.php"
        echo -e "   • Database Test: ${TUNNEL_URL}/sn_cars/test_db.php"
        echo -e "   • Pending Payments API: ${TUNNEL_URL}/sn_cars/pendingPayments.php?companyNumber=12345"
        echo ""
        echo -e "${BLUE}💡 Tips:${NC}"
        echo -e "   • Share the main URL with others for access"
        echo -e "   • The tunnel will stay active until you stop it"
        echo -e "   • Test all features to ensure they work online"
        echo ""
        echo -e "${YELLOW}🛑 To stop the tunnel:${NC}"
        echo -e "   pkill cloudflared"
        
        # Create a quick access file
        echo "$TUNNEL_URL" > /tmp/sn_cars_tunnel_url.txt
        echo -e "${GREEN}✅ Tunnel URL saved to: /tmp/sn_cars_tunnel_url.txt${NC}"
        
    else
        echo -e "${YELLOW}⚠️  Tunnel is running but URL not found in logs.${NC}"
        echo -e "${YELLOW}💡 Check the output above for the tunnel URL.${NC}"
        echo -e "${YELLOW}💡 Sometimes it takes a moment to appear in the logs.${NC}"
    fi
else
    echo -e "${RED}❌ Tunnel log file not found.${NC}"
fi

echo ""
echo -e "${GREEN}✅ Tunnel is running in the background.${NC}"
echo -e "${YELLOW}💡 Press Ctrl+C to stop this script (tunnel will continue running)${NC}"
echo -e "${BLUE}🔄 To restart the tunnel, run this script again${NC}"

# Keep the script running to monitor
trap 'echo -e "\n${YELLOW}Script terminated. Tunnel continues running in background.${NC}"; exit 0' INT

while true; do
    if ! kill -0 $TUNNEL_PID 2>/dev/null; then
        echo -e "${RED}❌ Tunnel process died unexpectedly${NC}"
        exit 1
    fi
    sleep 10
done

