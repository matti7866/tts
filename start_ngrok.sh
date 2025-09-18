#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting online access for sn_cars Labour Cards Database via ngrok...${NC}"
echo -e "${YELLOW}This will create a secure tunnel to make your application accessible online.${NC}"
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

# Check if ngrok is installed
if ! command -v ngrok &> /dev/null; then
    echo -e "${RED}❌ ngrok is not installed${NC}"
    echo -e "${YELLOW}💡 Install options:${NC}"
    echo -e "${YELLOW}   • Homebrew: brew install ngrok/ngrok/ngrok${NC}"
    echo -e "${YELLOW}   • Download from: https://ngrok.com/download${NC}"
    echo -e "${YELLOW}   • npm: npm install -g ngrok${NC}"
    echo ""
    echo -e "${YELLOW}💡 After installation, you may need to authenticate:${NC}"
    echo -e "${YELLOW}   ngrok authtoken YOUR_AUTH_TOKEN${NC}"
    exit 1
fi

echo -e "${GREEN}✅ ngrok is installed${NC}"

# Check ngrok authentication
echo -e "${BLUE}🔍 Checking ngrok authentication...${NC}"
if ngrok config check &> /dev/null; then
    echo -e "${GREEN}✅ ngrok is properly configured${NC}"
else
    echo -e "${YELLOW}⚠️  ngrok may not be authenticated${NC}"
    echo -e "${YELLOW}💡 Sign up at https://ngrok.com and get your auth token${NC}"
    echo -e "${YELLOW}💡 Then run: ngrok authtoken YOUR_AUTH_TOKEN${NC}"
    echo -e "${YELLOW}💡 Continuing with free tier (may have limitations)...${NC}"
fi

echo ""

# Start ngrok tunnel
echo -e "${BLUE}🌐 Starting ngrok tunnel on port 80...${NC}"
echo -e "${YELLOW}💡 Note: This will open a new terminal window for ngrok${NC}"
echo ""

# Kill any existing ngrok processes
pkill -f ngrok 2>/dev/null || true

# Start ngrok in background and capture output
ngrok http 80 --log=stdout > /tmp/ngrok_output.log 2>&1 &
NGROK_PID=$!

echo -e "${BLUE}⏳ ngrok started with PID: $NGROK_PID${NC}"
echo -e "${BLUE}⏳ Waiting for tunnel to establish...${NC}"

# Wait for ngrok to start up
sleep 10

# Get the tunnel URL from ngrok API
echo -e "${BLUE}🔍 Retrieving tunnel information...${NC}"

# Try to get tunnel info from ngrok's local API
TUNNEL_URL=""
for i in {1..5}; do
    if command -v jq &> /dev/null; then
        # Using jq if available
        TUNNEL_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url' 2>/dev/null)
    else
        # Fallback without jq
        TUNNEL_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"https://[^"]*' | head -1 | cut -d'"' -f4)
    fi
    
    if [ ! -z "$TUNNEL_URL" ] && [ "$TUNNEL_URL" != "null" ]; then
        break
    fi
    echo -e "${YELLOW}⏳ Attempt $i: Waiting for tunnel URL...${NC}"
    sleep 3
done

if [ ! -z "$TUNNEL_URL" ] && [ "$TUNNEL_URL" != "null" ]; then
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
    echo -e "${BLUE}📊 ngrok Dashboard:${NC}"
    echo -e "   http://localhost:4040"
    echo ""
    echo -e "${BLUE}💡 Tips:${NC}"
    echo -e "   • Share the main URL with others for access"
    echo -e "   • Free tier has 2-hour sessions and rate limits"
    echo -e "   • Monitor traffic at the ngrok dashboard"
    echo -e "   • The tunnel will stay active until you stop it"
    echo ""
    echo -e "${YELLOW}🛑 To stop the tunnel:${NC}"
    echo -e "   pkill -f ngrok"
    
    # Create a quick access file
    echo "$TUNNEL_URL" > /tmp/sn_cars_ngrok_url.txt
    echo -e "${GREEN}✅ Tunnel URL saved to: /tmp/sn_cars_ngrok_url.txt${NC}"
    
else
    echo -e "${YELLOW}⚠️  Could not retrieve tunnel URL from ngrok API${NC}"
    echo -e "${YELLOW}💡 Check the ngrok dashboard at: http://localhost:4040${NC}"
    echo -e "${YELLOW}💡 The tunnel might still be working, check the logs:${NC}"
    echo ""
    if [ -f /tmp/ngrok_output.log ]; then
        echo -e "${BLUE}📋 ngrok Output:${NC}"
        tail -20 /tmp/ngrok_output.log
    fi
fi

echo ""
echo -e "${GREEN}✅ ngrok tunnel is running in the background.${NC}"
echo -e "${YELLOW}💡 Press Ctrl+C to stop this script (tunnel will continue running)${NC}"
echo -e "${BLUE}🔄 To restart the tunnel, run this script again${NC}"
echo -e "${BLUE}📊 Visit http://localhost:4040 for tunnel dashboard${NC}"

# Keep the script running to monitor
trap 'echo -e "\n${YELLOW}Script terminated. Tunnel continues running in background.${NC}"; exit 0' INT

while true; do
    if ! kill -0 $NGROK_PID 2>/dev/null; then
        echo -e "${RED}❌ ngrok process died unexpectedly${NC}"
        exit 1
    fi
    sleep 10
done


