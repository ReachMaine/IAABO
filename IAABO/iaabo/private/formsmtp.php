<?php ?>
<html>
<!-- 04605 ANALYTICS -->
<script>
  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

  ga('create', 'UA-44173895-1', '04605.info');
  ga('send', 'pageview');
</script>
</head>
<body>

<?php
require_once("spyc.php");

error_reporting(-1);
$from         = 'no-reply@iaabo111.org';
$to           = 'bhodgins@ellsworthamerican.com';
$subject      = 'IAABO Technical Foul form';


# The message:
$body =  "\r\nA new submission has been made on your Technical Foul form:\r\n\r\n";
$body .= Spyc::YAMLDump($_POST,4,60);


/* the following two are for redirects: */
$return_page  = 'http://iaabo111.org/form-thx.htm';
$form_page    = 'http://iaabo111.org/private/tech-foul.htm';
$refresh_time = 3;

$captcha_private_key = ''; # leave blank for no captcha validation

$smtp_host    = 'localhost';
$smtp_user    = 'no-reply@iaabo111.org';
$smtp_pass    = '.fT7a8l8TK1t92}O';
$smtp_port    = 25;

/* ------------ do not edit below this line! ------------ */

/* captcha stuff ... ew it's ugly, but blame the reCaptcha team! :D */

if ($captcha_private_key) {
  require_once('recaptchalib.php');
  $resp = recaptcha_check_answer ($captcha_private_key, $_SERVER["REMOTE_ADDR"], $_POST["recaptcha_challenge_field"], $_POST["recaptcha_response_field"]);
  
  if (!$resp->is_valid) {
    // What happens when the CAPTCHA was entered incorrectly
    header("Refresh: $refresh_time;url=$form_page");
    echo ("<h2 style='color: #DD0000;'>Validation Error</h2>The reCAPTCHA wasn't entered correctly. Please go back and correct this.");
    die;
  }
}

/* mailing stuff: */

require_once "Mail.php";
 
$headers = array ('From' => $from,
		  'To' => $to,
		  'Date'    => date('r', time()),
		  'Subject' => $subject);


if ($_POST['email']) {

   $headers['Reply-To'] = $_POST['email'];
}

else {

     $headers['Reply-To'] = 'no-reply@iaabo111.org';
}


$smtp = Mail::factory('smtp',
		      array ('host' => $smtp_host,
			     'auth' => true,
			     'username' => $smtp_user,
			     'password' => $smtp_pass));
 
$mail = $smtp->send($to, $headers, $body);
 
if (PEAR::isError($mail)) {
#header("Refresh: $refresh_time;url=$return_page");
  echo("<h2 style='color: DD0000;'>Unexpected Error</h2>Please contact the system administrator.");
  #echo("<p>" . $mail->getMessage() . "</p>"); # uncomment this to figure out what sort of errors are happening with the SMTP transfer
} else {
  header("Refresh: $refresh_time;url=$return_page");
  echo("Message successfully sent!\r\n\r\n");
}

?>
</body>
</html>
