# 🌐 Online Access Guide for Labour Cards System

## 🚀 Quick Start - Multiple Options Available!

Your Labour Cards Database Search System can be made accessible online using multiple tunneling solutions. Choose the option that works best for you!

### ✅ What's Ready

1. **Enhanced Scripts**: Professional setup scripts with error checking and monitoring
2. **Multiple Options**: Cloudflare Tunnel and ngrok support
3. **Interactive Menu**: Easy-to-use setup interface
4. **CORS Headers**: Properly configured for cross-origin requests
5. **Database**: Verified connection with 319,645 records

## 🎯 Recommended Approach

### Option 1: Interactive Setup Menu (Easiest)
```bash
./setup_online.sh
```

This opens an interactive menu where you can:
- Choose between Cloudflare or ngrok
- Check prerequisites
- Monitor tunnel status
- View documentation
- Stop tunnels when done

### Option 2: Direct Cloudflare Tunnel (Recommended for Production)
```bash
./start_tunnel.sh
```

**Advantages:**
- ✅ Free forever
- ✅ No rate limits  
- ✅ No time restrictions
- ✅ Fast and reliable
- ✅ No signup required

### Option 3: ngrok Tunnel (Good for Development)
```bash
./start_ngrok.sh
```

**Advantages:**
- ✅ Easy to use
- ✅ Web dashboard at http://localhost:4040
- ✅ Traffic inspection
- ⚠️ Free tier: 2-hour sessions
- ⚠️ Requires signup for auth token

## 📱 What You'll Get

### Cloudflare Tunnel URLs
```
🌐 Main Application: https://random-words-12345.trycloudflare.com/sn_cars/
📊 Search Interface: https://random-words-12345.trycloudflare.com/sn_cars/index.html
🔍 Status Check: https://random-words-12345.trycloudflare.com/sn_cars/status.php
💳 Pending Payments API: https://random-words-12345.trycloudflare.com/sn_cars/pendingPayments.php?companyNumber=123
```

### ngrok Tunnel URLs  
```
🌐 Main Application: https://abc123.ngrok-free.app/sn_cars/
📊 Dashboard: http://localhost:4040
🔍 Status Check: https://abc123.ngrok-free.app/sn_cars/status.php
💳 Pending Payments API: https://abc123.ngrok-free.app/sn_cars/pendingPayments.php?companyNumber=123
```

## 🔧 Prerequisites & Testing

### Before Starting
1. **XAMPP must be running**:
   ```bash
   # Check if services are running
   pgrep -f httpd    # Apache should return a process ID
   pgrep -f mysqld   # MySQL should return a process ID
   ```

2. **Local application must work**:
   ```bash
   # Test local access
   curl -I http://localhost/sn_cars/index.html
   # Should return: HTTP/1.1 200 OK
   ```

3. **Install tunnel tools**:
   ```bash
   # For Cloudflare (recommended)
   brew install cloudflared
   
   # For ngrok
   brew install ngrok/ngrok/ngrok
   # Then: ngrok authtoken YOUR_TOKEN
   ```

### Testing Your Online Setup

1. **Quick Test Script**:
   ```bash
   # Run the interactive menu
   ./setup_online.sh
   # Choose option 3: "Check Prerequisites"
   ```

2. **Manual Testing**:
   ```bash
   # Test local endpoints
   curl http://localhost/sn_cars/status.php
   curl http://localhost/sn_cars/test_db.php
   
   # After tunnel is running, test online
   curl https://your-tunnel-url.trycloudflare.com/sn_cars/status.php
   ```

### 🛠️ Troubleshooting

#### If you get "Network error":

1. **Check XAMPP**:
   - Make sure Apache and MySQL are running
   - Open XAMPP Control Panel and verify services are started

2. **Check Database**:
   - Database name: `labour_cards_db`
   - Username: `root`
   - Password: (empty)
   - Socket: `/Applications/XAMPP/xamppfiles/var/mysql/mysql.sock`

3. **Check Tunnel**:
   - Verify Cloudflare tunnel is running
   - Check the tunnel URL is accessible

4. **Test Step by Step**:
   ```bash
   # Test database connection
   curl http://localhost/sn_cars/test_db.php
   
   # Test search API
   curl -X POST http://localhost/sn_cars/search.php -d "name=test"
   ```

### 📊 System Status

- ✅ Database: Connected (319,645 records)
- ✅ Apache: Running
- ✅ PHP: 8.2.4
- ✅ CORS: Configured
- ✅ Search API: Working
- ✅ Export API: Working

### 🔒 Security Notes

- The application is configured for development use
- CORS is set to allow all origins (`*`)
- Database uses default XAMPP credentials
- Consider securing for production use

### 📞 Support

If you encounter issues:
1. Check the status page: `/sn_cars/status.php`
2. Review the troubleshooting section above
3. Check XAMPP error logs if needed

---

**Your Labour Cards System is now ready for online access! 🎉**


