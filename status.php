<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

$status = array(
    'status' => 'success',
    'message' => 'SN Cars Labour Cards Database System is online',
    'timestamp' => date('Y-m-d H:i:s'),
    'system_info' => array(
        'php_version' => phpversion(),
        'server_software' => $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown',
        'document_root' => $_SERVER['DOCUMENT_ROOT'] ?? 'Unknown',
        'server_name' => $_SERVER['SERVER_NAME'] ?? 'localhost',
        'request_uri' => $_SERVER['REQUEST_URI'] ?? 'Unknown'
    ),
    'application_info' => array(
        'name' => 'Labour Cards Database Search System',
        'version' => '2.0',
        'description' => 'Modern web application for searching labour cards database',
        'total_records' => '319,645+',
        'features' => array(
            'Multi-field search',
            'Real-time results',
            'Export functionality',
            'Arabic support',
            'Responsive design'
        )
    )
);

// Test database connection if possible
try {
    $host = '127.0.0.1';
    $dbname = 'labour_cards_db';
    $username = 'root';
    $password = '';
    $socket = '/Applications/XAMPP/xamppfiles/var/mysql/mysql.sock';
    
    $dsn = "mysql:host=$host;dbname=$dbname;unix_socket=$socket;charset=utf8mb4";
    $pdo = new PDO($dsn, $username, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
    ]);
    
    // Quick count query
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM members LIMIT 1");
    $result = $stmt->fetch();
    
    $status['database'] = array(
        'status' => 'connected',
        'host' => $host,
        'database' => $dbname,
        'total_records' => number_format($result['total']),
        'connection_time' => date('Y-m-d H:i:s')
    );
    
} catch (PDOException $e) {
    $status['database'] = array(
        'status' => 'error',
        'message' => 'Database connection failed',
        'error' => $e->getMessage()
    );
}

// Check if main files exist
$files_to_check = array(
    'index.html' => 'Main search interface',
    'search.php' => 'Search API endpoint',
    'pendingPayments.php' => 'Pending payments API',
    'export.php' => 'Export functionality',
    'simple_html_dom.php' => 'HTML parser library'
);

$file_status = array();
foreach ($files_to_check as $file => $description) {
    $file_status[$file] = array(
        'description' => $description,
        'exists' => file_exists($file),
        'readable' => file_exists($file) && is_readable($file),
        'size' => file_exists($file) ? filesize($file) : 0
    );
}

$status['files'] = $file_status;

// Check for active tunnels
$tunnel_info = array();

// Check for Cloudflare tunnel
if (file_exists('/tmp/sn_cars_tunnel_url.txt')) {
    $cloudflare_url = trim(file_get_contents('/tmp/sn_cars_tunnel_url.txt'));
    if (!empty($cloudflare_url)) {
        $tunnel_info['cloudflare'] = array(
            'status' => 'active',
            'url' => $cloudflare_url,
            'type' => 'Cloudflare Tunnel'
        );
    }
}

// Check for ngrok tunnel
if (file_exists('/tmp/sn_cars_ngrok_url.txt')) {
    $ngrok_url = trim(file_get_contents('/tmp/sn_cars_ngrok_url.txt'));
    if (!empty($ngrok_url)) {
        $tunnel_info['ngrok'] = array(
            'status' => 'active',
            'url' => $ngrok_url,
            'type' => 'ngrok Tunnel',
            'dashboard' => 'http://localhost:4040'
        );
    }
}

if (empty($tunnel_info)) {
    $tunnel_info['none'] = array(
        'status' => 'inactive',
        'message' => 'No active tunnels detected',
        'suggestion' => 'Run ./setup_online.sh to start a tunnel'
    );
}

$status['tunnels'] = $tunnel_info;

// Available endpoints
$status['endpoints'] = array(
    'GET /' => 'Main search interface (index.html)',
    'POST /search.php' => 'Search labour cards database',
    'GET /pendingPayments.php?companyNumber=X' => 'Get pending payments for company',
    'POST /export.php' => 'Export search results to CSV',
    'GET /status.php' => 'This status endpoint',
    'GET /test_db.php' => 'Database connection test'
);

echo json_encode($status, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
?>