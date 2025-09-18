<?php
header('Content-Type: application/json');

// Get POST data
$input = json_decode(file_get_contents('php://input'), true);
$labourCardNumber = $input['labourCardNumber'] ?? '';
$personCode = $input['personCode'] ?? '';
$nationality = $input['nationality'] ?? '';

if (empty($labourCardNumber)) {
    echo json_encode(['success' => false, 'message' => 'Labour card number is required']);
    exit;
}

$url = "https://inquiry.mohre.gov.ae/";
$cookieFile = sys_get_temp_dir() . '/mohre-cookies-' . uniqid() . '.txt';

// Step 1: Get initial page
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_COOKIEJAR, $cookieFile);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
$response = curl_exec($ch);
curl_close($ch);

// Extract tokens using regex (more reliable than simple_html_dom)
preg_match('/<input[^>]*name=["\']OTP["\'][^>]*value=["\']([^"\']*)["\'][^>]*>/i', $response, $otpMatches);
preg_match('/<input[^>]*name=["\']OTPURL["\'][^>]*value=["\']([^"\']*)["\'][^>]*>/i', $response, $otpURLMatches);
preg_match('/<input[^>]*name=["\']__RequestVerificationToken["\'][^>]*value=["\']([^"\']*)["\'][^>]*>/i', $response, $tokenMatches);

$otp = $otpMatches[1] ?? '';
$otpURL = $otpURLMatches[1] ?? '';
$token = $tokenMatches[1] ?? '';

if (empty($otp) || empty($otpURL) || empty($token)) {
    echo json_encode(['success' => false, 'message' => 'Unable to get required form tokens from MOHRE']);
    exit;
}

// Step 2: Submit EWPI inquiry
$formData = array(
    'inquiryCode' => 'EWPI',
    'InputData' => $labourCardNumber,
    'OTP' => $otp,
    'OTPURL' => $otpURL,
    'InputOTP' => $otp,
    '__RequestVerificationToken' => $token,
    'InputLanguge' => 'en',
    'PersonCodeViolation' => '',
    'Emirates' => '000000001',
    'CompCode' => '',
    'StartDate' => '',
    'EndDate' => '',
    'permitType' => 0,
    'TransactionNo' => '',
    'PersonCode' => $personCode,
    'PersonDateOfBirth' => ''
);

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url . "TransactionInquiry/OnProtectData");
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $formData);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
curl_setopt($ch, CURLOPT_COOKIEFILE, $cookieFile);
curl_setopt($ch, CURLOPT_COOKIEJAR, $cookieFile);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
curl_setopt($ch, CURLOPT_HEADER, false);
$data = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$finalUrl = curl_getinfo($ch, CURLINFO_EFFECTIVE_URL);
curl_close($ch);

// Clean up cookie file
@unlink($cookieFile);

// Initialize mohreData
$mohreData = array(
    'transactionNumber' => 'N/A',
    'labourCardNumber' => $labourCardNumber,
    'personCode' => $personCode,
    'nationality' => $nationality,
    'status' => 'Active',
    'lastUpdated' => date('Y-m-d H:i:s'),
    'source' => 'MOHRE EWPI',
    'employeeName' => 'N/A',
    'designation' => 'N/A',
    'expiryDate' => 'N/A',
    'permitType' => 'N/A',
    'permitStatus' => 'N/A',
    'paymentNumber' => 'N/A',
    'paycardNumber' => 'N/A'
);

// Check if we got data
if (strlen($data) > 100) {
    // Parse the response using regex
    if (preg_match('/Transaction\s*Number[:\s]*<\/td>\s*<td[^>]*>([^<]+)/i', $data, $matches)) {
        $mohreData['transactionNumber'] = trim($matches[1]);
    } elseif (preg_match('/MB[0-9]+[A-Z]{2}/', $data, $matches)) {
        $mohreData['transactionNumber'] = $matches[0];
    }
    
    if (preg_match('/Name[:\s]*<\/td>\s*<td[^>]*colspan[^>]*>([^<]+)/i', $data, $matches)) {
        $mohreData['employeeName'] = trim($matches[1]);
    }
    
    if (preg_match('/Designation[:\s]*<\/td>\s*<td[^>]*>([^<]+)/i', $data, $matches)) {
        $mohreData['designation'] = trim($matches[1]);
    }
    
    if (preg_match('/Expiry\s*Date[:\s]*<\/td>\s*<td[^>]*>([^<]+)/i', $data, $matches)) {
        $mohreData['expiryDate'] = trim($matches[1]);
    }
    
    if (preg_match('/Electronic\s*Work\s*Permit\s*Type[:\s]*<\/td>\s*<td[^>]*>([^<]+)/i', $data, $matches)) {
        $mohreData['permitType'] = trim($matches[1]);
    }
    
    if (preg_match('/Electronic\s*Work\s*Permit\s*Active[:\s]*<\/td>\s*<td[^>]*>([^<]+)/i', $data, $matches)) {
        $mohreData['permitStatus'] = trim($matches[1]);
        $mohreData['status'] = trim($matches[1]);
    }
    
    if (preg_match('/Payment\s*Number[:\s]*<\/td>\s*<td[^>]*>([^<]+)/i', $data, $matches)) {
        $mohreData['paymentNumber'] = trim($matches[1]);
    }
    
    if (preg_match('/Paycard\s*Number[:\s]*<\/td>\s*<td[^>]*>([^<]+)/i', $data, $matches)) {
        $paycardNumber = trim($matches[1]);
        // Remove any extra content after the paycard number
        $mohreData['paycardNumber'] = preg_replace('/\s+.*/', '', $paycardNumber);
    }
    
    if (preg_match('/Person\s*Code[:\s]*<\/td>\s*<td[^>]*>([^<]+)/i', $data, $matches)) {
        $mohreData['personCode'] = trim($matches[1]);
    }
}

echo json_encode([
    'success' => true,
    'status' => 'success',
    'mohreData' => $mohreData
]);
?>


