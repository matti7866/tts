<?php
header('Content-Type: text/csv');
header('Content-Disposition: attachment; filename="labour_cards_export_' . date('Y-m-d') . '.csv"');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-Requested-With');
header('Access-Control-Max-Age: 86400');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Database connection configuration
$host = 'localhost';
$username = 'root';
$password = '';
$socket = '/Applications/XAMPP/xamppfiles/var/mysql/mysql.sock';

// Database names
$db1_name = 'labour_cards_db';
$db2_name = 'dddd';

try {
    // Get search parameters
    $name = $_POST['name'] ?? '';
    $dob = $_POST['dob'] ?? '';
    $nationality = $_POST['nationality'] ?? '';
    $labourCardNumber = $_POST['labourCardNumber'] ?? '';
    $gender = $_POST['gender'] ?? '';
    
    // Function to build WHERE conditions
    function buildWhereConditions($name, $dob, $nationality, $labourCardNumber, $gender, $hasArabicName = true) {
        $whereConditions = [];
        $params = [];
        
        if (!empty($name)) {
            if ($hasArabicName) {
                $whereConditions[] = "(name LIKE ? OR nameAr LIKE ?)";
                $params[] = "%$name%";
                $params[] = "%$name%";
            } else {
                $whereConditions[] = "name LIKE ?";
                $params[] = "%$name%";
            }
        }
        
        if (!empty($dob)) {
            $whereConditions[] = "dob = ?";
            $params[] = $dob;
        }
        
        if (!empty($nationality)) {
            $whereConditions[] = "nationality = ?";
            $params[] = $nationality;
        }
        
        if (!empty($labourCardNumber)) {
            $whereConditions[] = "labourCardNumber LIKE ?";
            $params[] = "%$labourCardNumber%";
        }
        
        if (!empty($gender)) {
            $whereConditions[] = "gender = ?";
            $params[] = $gender;
        }
        
        $whereClause = '';
        if (!empty($whereConditions)) {
            $whereClause = 'WHERE ' . implode(' AND ', $whereConditions);
        }
        
        return [$whereClause, $params];
    }
    
    // Search in both databases
    $allResults = [];
    
    // Database 1: labour_cards_db (has nameAr column)
    try {
        $pdo1 = new PDO("mysql:host=$host;dbname=$db1_name;unix_socket=$socket", $username, $password);
        $pdo1->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        
        list($whereClause1, $params1) = buildWhereConditions($name, $dob, $nationality, $labourCardNumber, $gender, true);
        
        $query1 = "SELECT id, personCode, labourCardNumber, name, nameAr, dob, nationality, gender, datetime_created, 
                          '$db1_name' as database_source
                   FROM members $whereClause1 
                   ORDER BY id DESC";
        
        $stmt1 = $pdo1->prepare($query1);
        $stmt1->execute($params1);
        $results1 = $stmt1->fetchAll(PDO::FETCH_ASSOC);
        
        $allResults = array_merge($allResults, $results1);
    } catch(PDOException $e) {
        error_log("Database 1 ($db1_name) error in export: " . $e->getMessage());
    }
    
    // Database 2: dddd (missing nameAr column)
    try {
        $pdo2 = new PDO("mysql:host=$host;dbname=$db2_name;unix_socket=$socket", $username, $password);
        $pdo2->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        
        list($whereClause2, $params2) = buildWhereConditions($name, $dob, $nationality, $labourCardNumber, $gender, false);
        
        $query2 = "SELECT id, personCode, labourCardNumber, name, NULL as nameAr, dob, nationality, gender, datetime_created, 
                          '$db2_name' as database_source
                   FROM members $whereClause2 
                   ORDER BY id DESC";
        
        $stmt2 = $pdo2->prepare($query2);
        $stmt2->execute($params2);
        $results2 = $stmt2->fetchAll(PDO::FETCH_ASSOC);
        
        $allResults = array_merge($allResults, $results2);
    } catch(PDOException $e) {
        error_log("Database 2 ($db2_name) error in export: " . $e->getMessage());
    }
    
    // Sort all results by ID descending
    usort($allResults, function($a, $b) {
        return $b['id'] - $a['id'];
    });
    
    $results = $allResults;
    
    // Create CSV output
    $output = fopen('php://output', 'w');
    
    // Add BOM for UTF-8
    fprintf($output, chr(0xEF).chr(0xBB).chr(0xBF));
    
    // CSV headers
    fputcsv($output, [
        'ID', 'Person Code', 'Labour Card Number', 'Name (English)', 
        'Name (Arabic)', 'Date of Birth', 'Nationality', 'Gender', 'Created Date', 'Database Source'
    ]);
    
    // CSV data
    foreach ($results as $row) {
        fputcsv($output, [
            $row['id'],
            $row['personCode'] ?? '',
            $row['labourCardNumber'] ?? '',
            $row['name'] ?? '',
            $row['nameAr'] ?? 'N/A',
            $row['dob'] ?? '',
            $row['nationality'] ?? '',
            $row['gender'] === 'M' ? 'Male' : ($row['gender'] === 'F' ? 'Female' : ''),
            $row['datetime_created'] ? date('Y-m-d', strtotime($row['datetime_created'])) : '',
            $row['database_source'] ?? 'Unknown'
        ]);
    }
    
    fclose($output);
    
} catch(PDOException $e) {
    http_response_code(500);
    echo "Database error: " . $e->getMessage();
} catch(Exception $e) {
    http_response_code(500);
    echo "Error: " . $e->getMessage();
}
?>
