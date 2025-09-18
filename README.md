# 🏢 SN Cars Labour Cards Database Search System

A modern, responsive web application for searching through labour cards databases with multi-database support and automatic tunnel management for remote access.

[![PHP](https://img.shields.io/badge/PHP-7.4+-777BB4?style=flat-square&logo=php)](https://php.net)
[![MySQL](https://img.shields.io/badge/MySQL-8.0+-4479A1?style=flat-square&logo=mysql)](https://mysql.com)
[![JavaScript](https://img.shields.io/badge/JavaScript-ES6+-F7DF1E?style=flat-square&logo=javascript)](https://developer.mozilla.org/en-US/docs/Web/JavaScript)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](LICENSE)

> **Live Demo**: Access the application via auto-generated Cloudflare tunnel for worldwide availability

## Features

- **Multi-field Search**: Search by name, date of birth, nationality, labour card number, and gender
- **Real-time Results**: Fast search with pagination (20 results per page)
- **Modern UI**: Clean, responsive design that works on all devices
- **Export Functionality**: Download search results as CSV files
- **Arabic Support**: Full support for Arabic names and text
- **Advanced Filtering**: Combine multiple search criteria

## Files Structure

### Core Application
- `index.html` - Main search interface
- `search.php` - Backend API for search functionality
- `export.php` - CSV export functionality
- `status.php` - System status checker
- `test_db.php` - Database connectivity tester

### Database
- `labour_cards_db.sql.zip` - Complete database export (28.5 MB)

### Tunnel Management
- `auto_tunnel_keeper.sh` - Auto-restart tunnel service
- `setup_auto_tunnel.sh` - One-click tunnel setup
- `start_tunnel.sh` - Manual tunnel starter
- `tunnel_status.sh` - Tunnel status checker

### Documentation
- `README.md` - Complete installation and usage guide
- `ONLINE_ACCESS.md` - Tunnel setup documentation

## 🚀 Quick Start

### Prerequisites
- **XAMPP** or **LAMP/WAMP** server
- **PHP 7.4+** with PDO extension
- **MySQL 8.0+**
- **Cloudflared** (for tunnel management)

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/matti786/tts.git
   cd tts
   ```

2. **Copy to web server**:
   ```bash
   # For XAMPP on macOS
   cp -r . /Applications/XAMPP/xamppfiles/htdocs/sn_cars/
   
   # For XAMPP on Windows
   copy . C:\xampp\htdocs\sn_cars\
   
   # For Linux Apache
   sudo cp -r . /var/www/html/sn_cars/
   ```

3. **Configure databases**:
   ```bash
   # Extract and import the included database
   unzip labour_cards_db.sql.zip
   mysql -u root -p < labour_cards_db.sql
   
   # Or use phpMyAdmin to import the SQL file
   ```
   - Update database credentials in `search.php` and `export.php` if needed
   - The included `labour_cards_db.sql.zip` contains sample data
   - Create the second database `dddd` with similar structure (missing `nameAr` column)

4. **Start XAMPP services**:
   - Start Apache and MySQL services
   - Verify access at `http://localhost/sn_cars/`

### 🌐 Public Access Setup

Set up automatic tunnel management for remote access:

```bash
cd /path/to/sn_cars
./setup_auto_tunnel.sh
```

This will:
- Install auto-tunnel service
- Generate public URL via Cloudflare
- Enable 24/7 automatic reconnection
- Configure system startup integration

## How to Use

### Basic Search
1. Enter any search criteria in the form fields:
   - **Name**: Search by English or Arabic name (partial matches supported)
   - **Date of Birth**: Select a specific date
   - **Nationality**: Choose from the dropdown list
   - **Labour Card Number**: Enter the card number (partial matches supported)
   - **Gender**: Select Male, Female, or All Genders

2. Click the "Search" button or press Enter

3. View results in the table below

### Advanced Search
- **Combine multiple criteria**: Use multiple fields to narrow down results
- **Partial name search**: Enter just part of a name to find matches
- **Clear form**: Use the "Clear" button to reset all fields

### Export Results
- After performing a search, click the "Export Results" button
- A CSV file will be downloaded with all matching records
- The file includes all search criteria in the filename

## Search Features

### Name Search
- Searches both English (`name`) and Arabic (`nameAr`) name fields
- Supports partial matches (e.g., "MOHAMMAD" will find "SYEED MOHAMMAD MERAJUDDIN MOHAMMAD")
- Case-insensitive search

### Date of Birth Search
- **Enhanced Date Picker**: Click the calendar icon for native date selection
- **Quick Date Buttons**: Instant selection for common dates:
  - Today
  - Yesterday
  - This Week (start of current week)
  - This Month (start of current month)
  - This Year (start of current year)
  - Clear (remove date filter)
- **User-Friendly Interface**: Fast date selection with visual feedback

### Nationality Search
- Dropdown with common nationalities from the database
- Includes: Bangladesh, Afghanistan, India, Syria, Sierra Leone, Egypt, Pakistan, Russia

### Labour Card Number Search
- Supports partial matches
- Searches the `labourCardNumber` field

### Gender Search
- Filter by Male (M) or Female (F)
- Select "All Genders" to include both

## Technical Details

### Database Connection
- Uses PDO for secure database connections
- Configured for XAMPP on macOS
- Socket connection to MySQL

### Security Features
- Prepared statements to prevent SQL injection
- Input validation and sanitization
- CORS headers for API access

### Performance
- Pagination to handle large result sets
- Optimized queries with proper indexing
- Memory-efficient data handling

## Browser Compatibility

- Chrome (recommended)
- Firefox
- Safari
- Edge
- Mobile browsers (responsive design)

## Auto Tunnel Management 🚀

**NEW**: Your tunnel will now stay online 24/7 automatically!

### Quick Setup (One-time)
```bash
cd /Applications/XAMPP/xamppfiles/htdocs/sn_cars
./setup_auto_tunnel.sh
```

### Features
- **🔄 Auto-Restart**: Automatically restarts if tunnel disconnects
- **🏠 Remote Access**: Works even when you're away from home
- **📱 Always Online**: Tunnel stays active 24/7
- **🔍 Health Monitoring**: Checks tunnel every 30 seconds
- **📊 Logging**: Full activity logs for troubleshooting

### Management Commands
```bash
# Check tunnel status
./tunnel_status.sh

# View live logs
tail -f /tmp/sn_cars_tunnel_keeper.log

# Get current tunnel URL
cat /tmp/sn_cars_current_url.txt

# Restart service manually
launchctl unload ~/Library/LaunchAgents/com.sncars.tunnelkeeper.plist
launchctl load ~/Library/LaunchAgents/com.sncars.tunnelkeeper.plist
```

### How It Works
1. **Auto-Start**: Service starts automatically when your Mac boots
2. **Health Checks**: Monitors tunnel connection every 30 seconds
3. **Auto-Recovery**: If tunnel fails, automatically restarts within 10 seconds
4. **Smart Retry**: Intelligent retry logic with exponential backoff
5. **XAMPP Integration**: Ensures XAMPP services are running before starting tunnel

## Troubleshooting

### Tunnel Issues
- **Check status**: `./tunnel_status.sh`
- **View logs**: `tail -f /tmp/sn_cars_tunnel_keeper.log`
- **Restart service**: Use management commands above
- **Manual test**: `./auto_tunnel_keeper.sh` (run manually)

### Database Connection Issues
- Ensure XAMPP MySQL service is running
- Check database credentials in PHP files
- Verify the `labour_cards_db` and `dddd` databases exist

### Search Not Working
- Check browser console for JavaScript errors
- Verify PHP error logs
- Ensure all files are in the correct directory

### Export Issues
- Check file permissions
- Ensure sufficient disk space
- Verify PHP has write permissions

## Multi-Database Support

The system now supports searching across **two databases simultaneously**:

### Database 1: `labour_cards_db`
- **Full feature set** with all columns including Arabic names
- **Table**: `members`
- **Columns**: `id`, `personCode`, `labourCardNumber`, `name`, `nameAr`, `dob`, `nationality`, `gender`, `datetime_created`

### Database 2: `dddd`
- **Similar structure** but **missing Arabic name column** (`nameAr`)
- **Table**: `members`
- **Columns**: `id`, `personCode`, `labourCardNumber`, `name`, `dob`, `nationality`, `gender`, `datetime_created`

### Multi-Database Features

1. **Unified Search Results**: Search queries are executed across both databases simultaneously
2. **Combined Results**: Results from both databases are merged and sorted by ID
3. **Database Identification**: Each result shows which database it came from (DB1 or DB2)
4. **Arabic Name Handling**: 
   - DB1 results show Arabic names when available
   - DB2 results show "N/A" for Arabic names (column doesn't exist)
5. **Smart Name Search**: 
   - For DB1: Searches both English (`name`) and Arabic (`nameAr`) fields
   - For DB2: Searches only English (`name`) field
6. **Export Support**: CSV exports include data from both databases with database source indication
7. **Statistics Display**: Shows total records from each database separately

### Visual Indicators

- **DB1 Badge**: Blue badge indicating records from `labour_cards_db`
- **DB2 Badge**: Orange badge indicating records from `dddd`
- **Results Count**: Shows breakdown of results from each database

## Database Schema

The `members` table contains:
- `id` (Primary Key)
- `personCode` (Unique identifier)
- `labourCardNumber` (Labour card number)
- `name` (English name)
- `nameAr` (Arabic name)
- `dob` (Date of birth)
- `nationality` (Country of origin)
- `gender` (M/F)
- `datetime_created` (Record creation timestamp)

## Support

For technical support or questions about the system, please check:
1. XAMPP logs for server issues
2. Browser developer tools for client-side errors
3. PHP error logs for backend issues
