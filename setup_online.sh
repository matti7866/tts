#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

clear

echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║                                                              ║${NC}"
echo -e "${PURPLE}║          🌐 SN Cars - Online Access Setup Tool 🌐           ║${NC}"
echo -e "${PURPLE}║                                                              ║${NC}"
echo -e "${PURPLE}║            Labour Cards Database Search System               ║${NC}"
echo -e "${PURPLE}║                                                              ║${NC}"
echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}This tool will help you make your Labour Cards Database accessible online.${NC}"
echo -e "${YELLOW}Choose your preferred tunneling method:${NC}"
echo ""

# Menu options
echo -e "${GREEN}1) 🌤️  Cloudflare Tunnel (Recommended)${NC}"
echo -e "   • Free forever"
echo -e "   • No rate limits"
echo -e "   • Fast and reliable"
echo -e "   • No signup required"
echo ""

echo -e "${GREEN}2) 🚇 ngrok Tunnel${NC}"
echo -e "   • Easy to use"
echo -e "   • Web dashboard"
echo -e "   • Free tier: 2-hour sessions"
echo -e "   • Requires signup for auth token"
echo ""

echo -e "${GREEN}3) 🔍 Check Prerequisites${NC}"
echo -e "   • Verify XAMPP is running"
echo -e "   • Test local application"
echo -e "   • Check tunnel tools installation"
echo ""

echo -e "${GREEN}4) 📊 System Status${NC}"
echo -e "   • Show current tunnel status"
echo -e "   • Display active URLs"
echo -e "   • Check running processes"
echo ""

echo -e "${GREEN}5) 🛑 Stop All Tunnels${NC}"
echo -e "   • Stop Cloudflare tunnel"
echo -e "   • Stop ngrok tunnel"
echo -e "   • Clean up processes"
echo ""

echo -e "${GREEN}6) 📖 View Documentation${NC}"
echo -e "   • Setup instructions"
echo -e "   • Troubleshooting guide"
echo -e "   • API endpoints"
echo ""

echo -e "${RED}0) ❌ Exit${NC}"
echo ""

read -p "$(echo -e ${YELLOW}Please select an option [0-6]: ${NC})" choice

case $choice in
    1)
        echo -e "\n${BLUE}🌤️  Starting Cloudflare Tunnel...${NC}"
        echo -e "${YELLOW}💡 This will run the enhanced Cloudflare tunnel script${NC}"
        echo ""
        read -p "Press Enter to continue..."
        ./start_tunnel.sh
        ;;
    2)
        echo -e "\n${BLUE}🚇 Starting ngrok Tunnel...${NC}"
        echo -e "${YELLOW}💡 This will run the ngrok tunnel script${NC}"
        echo ""
        read -p "Press Enter to continue..."
        ./start_ngrok.sh
        ;;
    3)
        echo -e "\n${BLUE}🔍 Checking Prerequisites...${NC}"
        echo ""
        
        # Check XAMPP
        echo -e "${BLUE}📋 XAMPP Status:${NC}"
        if pgrep -f httpd > /dev/null; then
            echo -e "${GREEN}  ✅ Apache: Running${NC}"
        else
            echo -e "${RED}  ❌ Apache: Not running${NC}"
        fi
        
        if pgrep -f mysqld > /dev/null; then
            echo -e "${GREEN}  ✅ MySQL: Running${NC}"
        else
            echo -e "${RED}  ❌ MySQL: Not running${NC}"
        fi
        
        # Check local access
        echo -e "\n${BLUE}🌐 Local Application:${NC}"
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/sn_cars/index.html 2>/dev/null)
        if [ "$RESPONSE" = "200" ]; then
            echo -e "${GREEN}  ✅ Accessible at: http://localhost/sn_cars/${NC}"
        else
            echo -e "${RED}  ❌ Not accessible (HTTP $RESPONSE)${NC}"
        fi
        
        # Check tunnel tools
        echo -e "\n${BLUE}🛠️  Tunnel Tools:${NC}"
        if command -v cloudflared &> /dev/null; then
            VERSION=$(cloudflared --version 2>&1 | head -1)
            echo -e "${GREEN}  ✅ Cloudflare: $VERSION${NC}"
        else
            echo -e "${RED}  ❌ Cloudflare: Not installed${NC}"
            echo -e "${YELLOW}     Install: brew install cloudflared${NC}"
        fi
        
        if command -v ngrok &> /dev/null; then
            VERSION=$(ngrok version 2>&1 | head -1)
            echo -e "${GREEN}  ✅ ngrok: $VERSION${NC}"
        else
            echo -e "${RED}  ❌ ngrok: Not installed${NC}"
            echo -e "${YELLOW}     Install: brew install ngrok/ngrok/ngrok${NC}"
        fi
        
        echo ""
        read -p "Press Enter to continue..."
        ;;
    4)
        echo -e "\n${BLUE}📊 System Status...${NC}"
        echo ""
        
        # Check running tunnels
        echo -e "${BLUE}🌐 Active Tunnels:${NC}"
        
        # Check Cloudflare
        if pgrep -f cloudflared > /dev/null; then
            echo -e "${GREEN}  ✅ Cloudflare tunnel: Running${NC}"
            if [ -f /tmp/sn_cars_tunnel_url.txt ]; then
                URL=$(cat /tmp/sn_cars_tunnel_url.txt)
                echo -e "${GREEN}     URL: $URL/sn_cars/${NC}"
            fi
        else
            echo -e "${YELLOW}  ⭕ Cloudflare tunnel: Not running${NC}"
        fi
        
        # Check ngrok
        if pgrep -f ngrok > /dev/null; then
            echo -e "${GREEN}  ✅ ngrok tunnel: Running${NC}"
            if [ -f /tmp/sn_cars_ngrok_url.txt ]; then
                URL=$(cat /tmp/sn_cars_ngrok_url.txt)
                echo -e "${GREEN}     URL: $URL/sn_cars/${NC}"
            fi
            echo -e "${BLUE}     Dashboard: http://localhost:4040${NC}"
        else
            echo -e "${YELLOW}  ⭕ ngrok tunnel: Not running${NC}"
        fi
        
        echo ""
        read -p "Press Enter to continue..."
        ;;
    5)
        echo -e "\n${BLUE}🛑 Stopping All Tunnels...${NC}"
        echo ""
        
        # Stop Cloudflare
        if pgrep -f cloudflared > /dev/null; then
            echo -e "${YELLOW}Stopping Cloudflare tunnel...${NC}"
            pkill -f cloudflared
            echo -e "${GREEN}✅ Cloudflare tunnel stopped${NC}"
        else
            echo -e "${YELLOW}⭕ No Cloudflare tunnel running${NC}"
        fi
        
        # Stop ngrok
        if pgrep -f ngrok > /dev/null; then
            echo -e "${YELLOW}Stopping ngrok tunnel...${NC}"
            pkill -f ngrok
            echo -e "${GREEN}✅ ngrok tunnel stopped${NC}"
        else
            echo -e "${YELLOW}⭕ No ngrok tunnel running${NC}"
        fi
        
        # Clean up temp files
        rm -f /tmp/sn_cars_tunnel_url.txt /tmp/sn_cars_ngrok_url.txt /tmp/tunnel_output.log /tmp/ngrok_output.log
        echo -e "${GREEN}✅ Cleanup completed${NC}"
        
        echo ""
        read -p "Press Enter to continue..."
        ;;
    6)
        echo -e "\n${BLUE}📖 Documentation...${NC}"
        echo ""
        
        if [ -f "ONLINE_ACCESS.md" ]; then
            echo -e "${GREEN}📄 Opening ONLINE_ACCESS.md...${NC}"
            if command -v open &> /dev/null; then
                open ONLINE_ACCESS.md
            else
                echo -e "${YELLOW}💡 View the file: ONLINE_ACCESS.md${NC}"
            fi
        fi
        
        echo -e "${BLUE}📊 Quick Reference:${NC}"
        echo ""
        echo -e "${GREEN}Main Application Files:${NC}"
        echo -e "  • index.html - Search interface"
        echo -e "  • search.php - Search API"
        echo -e "  • pendingPayments.php - Payments API"
        echo -e "  • export.php - Export functionality"
        echo ""
        echo -e "${GREEN}Setup Scripts:${NC}"
        echo -e "  • ./setup_online.sh - This menu"
        echo -e "  • ./start_tunnel.sh - Cloudflare tunnel"
        echo -e "  • ./start_ngrok.sh - ngrok tunnel"
        echo ""
        echo -e "${GREEN}Local URLs:${NC}"
        echo -e "  • http://localhost/sn_cars/ - Main app"
        echo -e "  • http://localhost/sn_cars/status.php - Status check"
        echo ""
        
        read -p "Press Enter to continue..."
        ;;
    0)
        echo -e "\n${GREEN}👋 Goodbye!${NC}"
        echo -e "${YELLOW}💡 To start online access later, run: ./setup_online.sh${NC}"
        exit 0
        ;;
    *)
        echo -e "\n${RED}❌ Invalid option. Please try again.${NC}"
        sleep 2
        exec "$0"
        ;;
esac

echo ""
echo -e "${BLUE}🔄 Returning to main menu...${NC}"
sleep 2
exec "$0"


