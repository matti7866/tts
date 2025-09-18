<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET');
header('Access-Control-Allow-Headers: Content-Type');

// Database connection configuration
$host = 'localhost';
$dbname = 'labour_cards_db';
$username = 'root';
$password = '';
$socket = '/Applications/XAMPP/xamppfiles/var/mysql/mysql.sock';

try {
    // Create PDO connection
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;unix_socket=$socket", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Get POST data
    $input = json_decode(file_get_contents('php://input'), true);
    $labourCardNumber = $input['labourCardNumber'] ?? '';
    
    if (empty($labourCardNumber)) {
        echo json_encode([
            'success' => false,
            'message' => 'Labour card number is required'
        ]);
        exit;
    }
    
    // Query to get UID information
    $query = "SELECT id, personCode, labourCardNumber, name, nameAr, dob, nationality, gender, datetime_created 
              FROM members 
              WHERE labourCardNumber = ? 
              LIMIT 1";
    
    $stmt = $pdo->prepare($query);
    $stmt->execute([$labourCardNumber]);
    $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($results) > 0) {
        echo json_encode([
            'success' => true,
            'results' => $results
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'No UID information found for this labour card number'
        ]);
    }
    
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


