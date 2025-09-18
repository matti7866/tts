<?php
header('Content-Type: application/json');
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
    $page = max(1, intval($_POST['page'] ?? 1));
    $limit = 20;
    $offset = ($page - 1) * $limit;
    
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
    $totalCount = 0;
    $db1_total = 0;
    $db2_total = 0;
    
    // Database 1: labour_cards_db (has nameAr column)
    try {
        $pdo1 = new PDO("mysql:host=$host;dbname=$db1_name;unix_socket=$socket", $username, $password);
        $pdo1->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        
        list($whereClause1, $params1) = buildWhereConditions($name, $dob, $nationality, $labourCardNumber, $gender, true);
        
        // Count query for DB1
        $countQuery1 = "SELECT COUNT(*) as total FROM members $whereClause1";
        $countStmt1 = $pdo1->prepare($countQuery1);
        $countStmt1->execute($params1);
        $db1_total = $countStmt1->fetch(PDO::FETCH_ASSOC)['total'];
        
        // Results query for DB1
        $query1 = "SELECT id, personCode, labourCardNumber, name, nameAr, dob, nationality, gender, datetime_created, 
                          '$db1_name' as database_source
                   FROM members $whereClause1 
                   ORDER BY id DESC";
        
        $stmt1 = $pdo1->prepare($query1);
        $stmt1->execute($params1);
        $results1 = $stmt1->fetchAll(PDO::FETCH_ASSOC);
        
        $allResults = array_merge($allResults, $results1);
    } catch(PDOException $e) {
        // If DB1 fails, continue with DB2
        error_log("Database 1 ($db1_name) error: " . $e->getMessage());
    }
    
    // Database 2: dddd (missing nameAr column)
    try {
        $pdo2 = new PDO("mysql:host=$host;dbname=$db2_name;unix_socket=$socket", $username, $password);
        $pdo2->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        
        list($whereClause2, $params2) = buildWhereConditions($name, $dob, $nationality, $labourCardNumber, $gender, false);
        
        // Count query for DB2
        $countQuery2 = "SELECT COUNT(*) as total FROM members $whereClause2";
        $countStmt2 = $pdo2->prepare($countQuery2);
        $countStmt2->execute($params2);
        $db2_total = $countStmt2->fetch(PDO::FETCH_ASSOC)['total'];
        
        // Results query for DB2 (add NULL as nameAr since column doesn't exist)
        $query2 = "SELECT id, personCode, labourCardNumber, name, NULL as nameAr, dob, nationality, gender, datetime_created, 
                          '$db2_name' as database_source
                   FROM members $whereClause2 
                   ORDER BY id DESC";
        
        $stmt2 = $pdo2->prepare($query2);
        $stmt2->execute($params2);
        $results2 = $stmt2->fetchAll(PDO::FETCH_ASSOC);
        
        $allResults = array_merge($allResults, $results2);
    } catch(PDOException $e) {
        // If DB2 fails, continue with existing results
        error_log("Database 2 ($db2_name) error: " . $e->getMessage());
    }
    
    // Sort all results by ID descending
    usort($allResults, function($a, $b) {
        return $b['id'] - $a['id'];
    });
    
    // Calculate totals
    $totalCount = $db1_total + $db2_total;
    
    // Apply pagination to combined results
    $paginatedResults = array_slice($allResults, $offset, $limit);
    
    // Return JSON response
    echo json_encode([
        'success' => true,
        'total' => $totalCount,
        'page' => $page,
        'limit' => $limit,
        'results' => $paginatedResults,
        'database_stats' => [
            'db1_total' => $db1_total,
            'db2_total' => $db2_total,
            'db1_name' => $db1_name,
            'db2_name' => $db2_name
        ]
    ]);
    
} catch(PDOException $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $e->getMessage()
    ]);
} catch(Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ]);
}
?>
