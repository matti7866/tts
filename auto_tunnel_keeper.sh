#!/bin/bash

# Auto Tunnel Keeper - Keeps your sn_cars tunnel running 24/7
# This script automatically restarts the tunnel if it disconnects

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
MAX_RETRIES=999  # Infinite retries
RETRY_DELAY=10   # Seconds to wait before retry
HEALTH_CHECK_INTERVAL=30  # Seconds between health checks
LOG_FILE="/tmp/sn_cars_tunnel_keeper.log"
URL_FILE="/tmp/sn_cars_current_url.txt"
PID_FILE="/tmp/sn_cars_tunnel.pid"

# Initialize log
echo "$(date): Auto Tunnel Keeper started" > "$LOG_FILE"

log_message() {
    local message="$1"
    echo "$(date): $message" >> "$LOG_FILE"
    echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} $message"
}

cleanup_old_processes() {
    log_message "🧹 Cleaning up old cloudflared processes..."
    pkill -f "cloudflared tunnel" 2>/dev/null || true
    rm -f "$PID_FILE" 2>/dev/null || true
    rm -f /tmp/tunnel_output.log 2>/dev/null || true
    sleep 2
}

check_xampp_services() {
    log_message "📋 Checking XAMPP services..."
    
    if ! pgrep -f httpd > /dev/null; then
        log_message "❌ Apache is not running! Please start XAMPP Apache."
        return 1
    fi
    
    if ! pgrep -f mysqld > /dev/null; then
        log_message "❌ MySQL is not running! Please start XAMPP MySQL."
        return 1
    fi
    
    # Test local access
    local response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/sn_cars/index.html 2>/dev/null)
    if [ "$response" != "200" ]; then
        log_message "❌ Local application not accessible (HTTP $response)"
        return 1
    fi
    
    log_message "✅ XAMPP services are running and app is accessible"
    return 0
}

start_tunnel() {
    log_message "🚀 Starting Cloudflare tunnel..."
    
    # Start cloudflared in background
    nohup cloudflared tunnel --url http://localhost:80 > /tmp/tunnel_output.log 2>&1 &
    local tunnel_pid=$!
    echo "$tunnel_pid" > "$PID_FILE"
    
    log_message "⏳ Tunnel started with PID: $tunnel_pid"
    
    # Wait for tunnel to establish
    local attempts=0
    local max_wait_attempts=20
    
    while [ $attempts -lt $max_wait_attempts ]; do
        sleep 3
        
        # Check if process is still running
        if ! kill -0 "$tunnel_pid" 2>/dev/null; then
            log_message "❌ Tunnel process died during startup"
            return 1
        fi
        
        # Try to get the URL
        if [ -f /tmp/tunnel_output.log ]; then
            local tunnel_url=$(grep -o 'https://.*\.trycloudflare\.com' /tmp/tunnel_output.log | head -1)
            if [ ! -z "$tunnel_url" ]; then
                echo "$tunnel_url" > "$URL_FILE"
                log_message "🎉 Tunnel established successfully!"
                log_message "🌐 URL: $tunnel_url"
                
                # Send notification (if you want to be notified)
                echo "SN Cars tunnel is online: $tunnel_url" | wall 2>/dev/null || true
                
                return 0
            fi
        fi
        
        attempts=$((attempts + 1))
        log_message "⏳ Waiting for tunnel... (attempt $attempts/$max_wait_attempts)"
    done
    
    log_message "❌ Failed to establish tunnel after $max_wait_attempts attempts"
    return 1
}

check_tunnel_health() {
    # Check if cloudflared process is running
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ! kill -0 "$pid" 2>/dev/null; then
            return 1  # Process is dead
        fi
    else
        return 1  # No PID file
    fi
    
    # Check if we have a current URL
    if [ ! -f "$URL_FILE" ]; then
        return 1  # No URL file
    fi
    
    # Test if the tunnel URL is actually working
    local current_url=$(cat "$URL_FILE" 2>/dev/null)
    if [ ! -z "$current_url" ]; then
        local response=$(curl -s -o /dev/null -w "%{http_code}" "$current_url/sn_cars/status.php" --max-time 10 2>/dev/null)
        if [ "$response" = "200" ]; then
            return 0  # Tunnel is healthy
        fi
    fi
    
    return 1  # Tunnel is not healthy
}

main_loop() {
    local retry_count=0
    
    log_message "🏁 Starting Auto Tunnel Keeper main loop..."
    log_message "⚙️  Health check interval: ${HEALTH_CHECK_INTERVAL}s"
    log_message "🔄 Max retries: $MAX_RETRIES"
    
    while [ $retry_count -lt $MAX_RETRIES ]; do
        # Check XAMPP services first
        if ! check_xampp_services; then
            log_message "⚠️  XAMPP services not ready, waiting..."
            sleep 30
            continue
        fi
        
        # Check if tunnel is healthy
        if check_tunnel_health; then
            # Tunnel is healthy, just sleep and check again
            sleep $HEALTH_CHECK_INTERVAL
            continue
        fi
        
        # Tunnel is down, restart it
        log_message "🔧 Tunnel appears to be down, restarting... (retry $((retry_count + 1))/$MAX_RETRIES)"
        
        cleanup_old_processes
        
        if start_tunnel; then
            log_message "✅ Tunnel restarted successfully!"
            retry_count=0  # Reset retry counter on success
            
            # Display current status
            if [ -f "$URL_FILE" ]; then
                local current_url=$(cat "$URL_FILE")
                log_message "🌐 Current tunnel URL: $current_url"
                log_message "📱 Access your app at: $current_url/sn_cars/"
            fi
        else
            retry_count=$((retry_count + 1))
            log_message "❌ Failed to restart tunnel (attempt $retry_count)"
            
            if [ $retry_count -lt $MAX_RETRIES ]; then
                log_message "⏳ Waiting ${RETRY_DELAY}s before next retry..."
                sleep $RETRY_DELAY
            fi
        fi
    done
    
    log_message "💀 Max retries exceeded. Tunnel keeper stopping."
}

# Signal handlers for graceful shutdown
cleanup_and_exit() {
    log_message "🛑 Received stop signal, cleaning up..."
    cleanup_old_processes
    log_message "👋 Auto Tunnel Keeper stopped"
    exit 0
}

trap cleanup_and_exit SIGTERM SIGINT

# Main execution
echo -e "${PURPLE}🚀 SN Cars Auto Tunnel Keeper${NC}"
echo -e "${YELLOW}This script will keep your tunnel running 24/7${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
echo ""

# Initial cleanup
cleanup_old_processes

# Check cloudflared installation
if ! command -v cloudflared &> /dev/null; then
    log_message "❌ cloudflared is not installed"
    echo -e "${RED}💡 Install with: brew install cloudflared${NC}"
    exit 1
fi

log_message "✅ Starting Auto Tunnel Keeper for SN Cars"

# Start main loop
main_loop

