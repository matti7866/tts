<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET');
header('Access-Control-Allow-Headers: Content-Type');

// Include simple_html_dom.php
require_once 'simple_html_dom.php';

function response_json($output = array()) {
    echo json_encode($output);
    exit;
}

// Get POST data
$input = json_decode(file_get_contents('php://input'), true);
$labourCardNumber = $input['labourCardNumber'] ?? '';
$personCode = $input['personCode'] ?? '';
$nationality = $input['nationality'] ?? '';

if (empty($labourCardNumber)) {
    response_json(['success' => false, 'message' => 'Labour card number is required']);
}

$url = "https://inquiry.mohre.gov.ae/";

// Initialize cURL session with unique cookie file
$cookieFile = sys_get_temp_dir() . '/cookies-uid-' . uniqid() . '.txt';

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HEADER, false);
curl_setopt($ch, CURLOPT_COOKIEJAR, $cookieFile);
curl_setopt($ch, CURLOPT_COOKIEFILE, $cookieFile);
curl_setopt($ch, CURLOPT_USERAGENT, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36');
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
$response = curl_exec($ch);
curl_close($ch);

$html = str_get_html($response);

// Check if unable to find request 
if (!$html) {
    response_json(['success' => false, 'message' => 'Sorry! unable to serve you at this time']);
}

// Extract form tokens
$otp = $html->find("input[name=OTP]", 0);
$otpURL = $html->find('input[name=OTPURL]', 0);
$verificationToken = $html->find('input[name=__RequestVerificationToken]', 0);

if (!$otp || !$otpURL || !$verificationToken) {
    response_json(['success' => false, 'message' => 'Unable to get required form tokens from MOHRE']);
}

$otpValue = $otp->getAttribute("value");
$otpURLValue = $otpURL->getAttribute("value");
$verificationTokenValue = $verificationToken->getAttribute("value");

// Debug: Log the tokens
error_log("Tokens - OTP: $otpValue, OTPURL: " . substr($otpURLValue, 0, 50) . ", Token: " . substr($verificationTokenValue, 0, 50));

// Prepare form data for EWPI inquiry
$formData = array(
    'inquiryCode' => 'EWPI', // UID inquiry code
    'InputData' => $labourCardNumber,
    'OTP' => $otpValue,
    'OTPURL' => $otpURLValue,
    'InputOTP' => $otpValue,
    '__RequestVerificationToken' => $verificationTokenValue,
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

$finalURL = $url . "TransactionInquiry/OnProtectData";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $finalURL);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $formData);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
curl_setopt($ch, CURLOPT_COOKIEFILE, $cookieFile);
curl_setopt($ch, CURLOPT_COOKIEJAR, $cookieFile);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
curl_setopt($ch, CURLOPT_HEADER, false);
curl_setopt($ch, CURLOPT_USERAGENT, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36');
$data = curl_exec($ch);
$httpcode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$final_url = curl_getinfo($ch, CURLINFO_EFFECTIVE_URL);
$curl_error = curl_error($ch);
curl_close($ch);

// Debug: Log what we got
error_log("MOHRE EWPI Response - HTTP: $httpcode, URL: $final_url, Length: " . strlen($data) . ", Error: $curl_error");

// Check for error messages
if (strpos($data, 'No information available') !== false || 
    strpos($data, 'not found') !== false || 
    strpos($data, 'error') !== false) {
    response_json([
        'success' => true, 
        'status' => 'no_data',
        'message' => 'No MOHRE information available for this labour card number'
    ]);
}



// Parse the HTML response to extract information
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

// Improved regex patterns to extract data from HTML tables
// Look for transaction number - multiple patterns
$transactionPatterns = [
    '/Transaction\s*Number[:\s]*<\/td>\s*<td[^>]*>([^<]+)/i',
    '/MB[0-9]+[A-Z]{2}/i',
    '/[A-Z]{2}[0-9]+[A-Z]{2}/i'
];

foreach ($transactionPatterns as $pattern) {
    if (preg_match($pattern, $data, $matches)) {
        if (isset($matches[1])) {
            $mohreData['transactionNumber'] = trim($matches[1]);
        } else {
            $mohreData['transactionNumber'] = trim($matches[0]);
        }
        break;
    }
}

// Extract employee name
if (preg_match('/Name[:\s]*<\/td>\s*<td[^>]*colspan[^>]*>([^<]+)/i', $data, $matches)) {
    $mohreData['employeeName'] = trim($matches[1]);
}

// Extract designation
if (preg_match('/Designation[:\s]*<\/td>\s*<td[^>]*>([^<]+)/i', $data, $matches)) {
    $mohreData['designation'] = trim($matches[1]);
}

// Extract expiry date
if (preg_match('/Expiry\s*Date[:\s]*<\/td>\s*<td[^>]*>([^<]+)/i', $data, $matches)) {
    $mohreData['expiryDate'] = trim($matches[1]);
}

// Extract permit type
if (preg_match('/Electronic\s*Work\s*Permit\s*Type[:\s]*<\/td>\s*<td[^>]*>([^<]+)/i', $data, $matches)) {
    $mohreData['permitType'] = trim($matches[1]);
}

// Extract permit status
if (preg_match('/Electronic\s*Work\s*Permit\s*Active[:\s]*<\/td>\s*<td[^>]*>([^<]+)/i', $data, $matches)) {
    $mohreData['permitStatus'] = trim($matches[1]);
    $mohreData['status'] = trim($matches[1]);
}

// Extract payment number
if (preg_match('/Payment\s*Number[:\s]*<\/td>\s*<td[^>]*>([^<]+)/i', $data, $matches)) {
    $mohreData['paymentNumber'] = trim($matches[1]);
}

// Extract paycard number
if (preg_match('/Paycard\s*Number[:\s]*<\/td>\s*<td[^>]*>([^<]+)/i', $data, $matches)) {
    $mohreData['paycardNumber'] = trim($matches[1]);
}

// Extract person code from MOHRE response
if (preg_match('/Person\s*Code[:\s]*<\/td>\s*<td[^>]*>([^<]+)/i', $data, $matches)) {
    $mohreData['personCode'] = trim($matches[1]);
}

// If no data found, try alternative parsing method
if ($mohreData['transactionNumber'] === 'N/A') {
    // Look for any MB pattern in the entire response
    if (preg_match('/MB[0-9]+[A-Z]{2}/', $data, $matches)) {
        $mohreData['transactionNumber'] = $matches[0];
    }
}

// Clean up extracted data
foreach ($mohreData as $key => $value) {
    if ($value !== 'N/A') {
        $mohreData[$key] = trim(strip_tags($value));
    }
}



response_json([
    'success' => true,
    'status' => 'success',
    'mohreData' => $mohreData,
    'rawResponse' => substr($data, 0, 500), // First 500 chars for debugging
    'dataLength' => strlen($data),
    'finalUrl' => $final_url
]);
?>
