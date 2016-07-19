#!/usr/bin/env perl

use warnings;
use strict;

use Net::SMTP;
use YAML::Tiny;
use DateTime;
use CGI qw/:standard/;


my %config = (

    message => {

	# Edit the following data to customize your message. Interestingly
	# enough, the following keys actually match the headers that are sent-
	# so you can do some nifty stuff with it:

	# Where is the mail going to?:
	'To'             => ['bhodgins@ellsworthamerican.com'],

	# Who's the mail from?:
	'From'           => 'info@iaabo111.com',

	# The current date. You probably won't change this:
	'Date'           => DateTime->now->ymd,

	# The subject of the mail:
	'Subject'        => 'Technical Foul form submission',

	# Should be the same as 'From'
	'Return-Path'    => 'info@iaabo111.com',

	# Where should clients be directed to reply to?:
	'Reply-To'       => '',

    },

    # Advanced configuration settings:

    # Where do you want the page to redirect after the mail has been sent?:
    'redirect'           => 'http://iaabo111.org/',

    # your PRIVATE recaptcha key. Leave blank for no recaptcha:
    'recaptcha_key'      => '',

    # Your PUBLIC GnuPg key for encryption. <-- NOT YET SUPPORTED!:
    'gnupg_key'          => '',
    
    # Die and report on sensitive input/output (recommended):
    'strict'             => 1,

    );

# Edit the following to restrict fields that shouldn't come through:
my @blacklist = qw[B1];




# --------------- DO NOT EDIT BELOW THIS LINE! ---------------


my $initialized    = 0;
our $VERSION       = '2013120304';

my $q = CGI->new;
my @params = $q->param;

# Load recaptcha if we can:
eval
{
    require Captcha::reCAPTCHA;
    Captcha::reCAPTCHA->import;
} if $config{'message'}{'recaptcha_key'};

# If the recaptcha lib is not available, disable it:
$config{'recaptcha_key'} = '' if $@;
error($@) if $config{'strict'} and $@;

# Validate the captcha:
if ($config{'recaptcha_key'}) {
    my $result;

    eval {
	$result = Captcha::reCAPTCHA->new->check_answer(
	    $config{'recaptcha_key'},
	    $ENV{'REMOTE_ADDR'},
	    $q->param('recaptcha_challenge_field'),
	    $q->param('recaptcha_response_field'),
	    );
    };

    error("captcha failed. Please click back and try again.\n")
	unless $result->{is_valid};
}

# Generate YAML output:
my $yaml = YAML::Tiny->new;

foreach my $param (@params) {
    
    # Add all of the parameters:
    $yaml->[0]->{$param} = $q->param($param);
}

# Get the output:
my $content = $yaml->write_string;

# If Email is blank, check for an email field and use its value but only if
# Reply-To is not set:
if (grep /^email$/, @params) {
    
    $config{'message'}{'Reply-To'} = $q->param('email')
	unless $config{'message'}{'Reply-To'};
}

# Set Reply-To if it has not been set:
unless ($config{'message'}{'Reply-To'}) {
    
    $config{'message'}{'Reply-To'} = $config{'message'}{'From'};
}

# Send the Email(s):
foreach my $to ( @{$config{'message'}{'To'}} ) {
    
    my $host = (split '@', $to)[1];
    my $smtp = Net::SMTP->new($host, Timeout => 10)
	or die error("Can't connect to $host!\n");
    
    print "Sending message to: $to\n";
    $smtp->mail($to);
    $smtp->to($to);
    
    $smtp->data; # Prepare data transaction
    foreach my $key ( keys %{ $config{message} } ) {
	
	if ($key eq 'To') {

	    # We have to put in this hack to ensure SMTP To is correct:
	    $smtp->datasend("To: $to\n");
	    next;
	}

	$smtp->datasend("$key: $config{message}{$key}\n");
    }
    
    $smtp->datasend("\n");
    $smtp->datasend("Below are the results of the submission:\n\n");
    $smtp->datasend($content);
    $smtp->datasend; # send message
    $smtp->quit;
}


# Redirect somewhere. Maybe a thank you page or something:
print $q->redirect( -uri => $config{'redirect'} );
#print "Status: 302 Found\r\n";
#print "Location: " . $config{'redirect'} . "\r\n\r\n";


# Just a simple error function:
sub error {
    return unless @_;
    my $message = shift;

    # Initialize if we haven't:
    unless ($initialized) {

	print "Content-Type: text/html\r\n\r\n";
	$initialized = 1;
	
	print '<h2 style="color: red;">ERROR.</h2><br /><h3>Please contact the system administrator.</h3>';
    }

    print $message;
}
