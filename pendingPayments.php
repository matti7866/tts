<?php

require 'simple_html_dom.php';

function response_json($output = array())
{
  header("Content-Type: application/json");
  echo json_encode($output);
  exit;
}



$companyNumber = isset($_GET['companyNumber']) ? $_GET['companyNumber'] : '';

if ($companyNumber == "") {
  response_json(['status' => "error", 'message' => "Company Number not provided"]);
}



$url = "https://inquiry.mohre.gov.ae/";

// Initialize cURL session
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HEADER, false);
curl_setopt($ch, CURLOPT_COOKIEJAR, dirname(__FILE__) . "/cookies-pendingPayments.txt"); // Save cookies here
//curl_setopt($ch, CURLOPT_COOKIEFILE, "cookies-pendingPayments.txt"); // Read cookies from here
$response = curl_exec($ch);
curl_close($ch);



$html = str_get_html($response);

// check if unable to find request 
if (!$html) {
  response_json(['status' => 'error', 'message' => 'Sorry! unable to serve you at this time']);
}

$otp = $html->find("input[name=OTP]", 0)->getAttribute("value");
$otpURL = $html->find('input[name=OTPURL]', 0)->getAttribute("value");
$verificationToken = $html->find('input[name=__RequestVerificationToken]', 0)->getAttribute("value");






$formData = array(
  'inquiryCode' => 'PP',
  'InputData' => $companyNumber,
  'OTP' => $otp,
  'OTPURL' => $otpURL,
  'InputOTP' => $otp,
  '__RequestVerificationToken' => $verificationToken,
  'InputLanguge' => 'en',
  'PersonCodeViolation' => '',
  'Emirates' => '000000001',
  'CompCode' => '',
  'StartDate' => '',
  'EndDate' => '',
  'permitType' => 0,
  'TransactionNo' => '',
  'PersonCode' => '',
  'PersonDateOfBirth' => ''
);


$finalURL = $url . "TransactionInquiry/OnProtectData";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $finalURL);
curl_setopt($ch, CURLOPT_HEADER, true);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, TRUE);
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'POST');
curl_setopt($ch, CURLOPT_POSTFIELDS, $formData);
curl_setopt($ch, CURLOPT_COOKIEFILE, dirname(__FILE__) . '/cookies-pendingPayments.txt');
$a = curl_exec($ch);
$httpcode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

$final_url = curl_getinfo($ch, CURLINFO_EFFECTIVE_URL);



$data = file_get_contents($final_url);


if (strpos($data, 'Payment information not available for the given company number') !== false) {
  response_json(['status' => 'error', 'message' => 'Payment information not available for the given company number']);
}

$html = str_get_html($data);

// get first table data
$table = $html->find('table', 0);
$number = $table->find('tr', 0)->find('td', 1)->plaintext;
$companyName = $table->find('tr', 1)->find('td', 1)->plaintext;

$table2 = $html->find('table', 1);

$payments = [];

if ($table2) {
  $rows = $table2->find('tbody', 0)->find('tr');
  if ($rows) {
    foreach ($rows as $row) {
      $payment = [];
      $payment['trxNumber'] = $row->find('td', 0)->plaintext;
      $payment['name'] = $row->find('td', 1)->plaintext;
      $payment['payCardNumber'] = $row->find('td', 2)->plaintext;
      $payment['labourCardNumber'] = $row->find('td', 3)->plaintext;
      $payment['cardExpiryDate'] = $row->find('td', 4)->plaintext;

      $payments[] = $payment;
    }
  }
}

response_json(['status' => 'success', 'companyName' => $companyName, 'companyNumber' => $number, 'payments' => $payments]);
