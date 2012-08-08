#!/usr/bin/perl -w
BEGIN {require('libpath.pl')}
use strict;
use VVNetwork qw(connectDatabase);
use VVUsers qw(checkLoginInfo);
use VVFileOpreation qw(templateWithName);
use VVCGIGenerator qw(indexURL);
use CGI;
use CGI::Session;


my $session = CGI::Session->new;
my $userID = $session->param('userID');
my $temp = templateWithName('login');
my $q = CGI->new;
$q->charset('utf-8');
my $isSubmitted = $q->param();

my $userLoggedIn = $userID ? 1 : undef;

unless ($userLoggedIn) {
    my $inputUserID = $q->param('headerIdTextField');
    my $inputPasswd = $q->param('headerPwdTextField');
    my $requestAdmin = $q->param('url') eq 'admin-login.pl';
    
    my $dbh = connectDatabase();
    $userLoggedIn = checkLoginInfo($inputUserID,$inputPasswd,$dbh,$requestAdmin);

    $dbh->disconnect();
}

#Forms...
if ($userLoggedIn == 1 || $userLoggedIn == 999) {
    $temp->param(loginSucParam($isSubmitted));
} elsif ($userLoggedIn == 100) {
    $temp->param(databaseFailParam($isSubmitted));
} elsif ($userLoggedIn == 200) {
    $temp->param(loginFailParam($isSubmitted));
} else {
    $temp->param(loginFailParam($isSubmitted));
}

$session->clear();

if ($userLoggedIn == 1) {
    ($q->param('keep') eq 'yes') ? $session->expire("1y") : $session->expire(0);
    $session->param('userID',$q->param('headerIdTextField'));
    print $session->header(-charset=>'utf-8');
} elsif ($userLoggedIn == 999) {
    $session->param('userID',$q->param('headerIdTextField'));
    $session->param('admin',1);
    print $session->header(-charset=>'utf-8');
} else {
    print $q->header(-charset=>'utf-8');
}
print $q->start_html(-title=>"ログイン|OneV's Denの掲示板",
                     -style=>{'src'=>VVNetwork::CSS},
                    );
require 'header.pl';
print $temp->output;
require('footer.pl');

sub loginSucParam {
    my %param = (
        isSubmitted => shift @_,
        loginSuc => 1,
        url => indexURL,
        );
}

sub loginFailParam {
    my %param = (
        isSubmitted => shift @_,
        loginSuc => undef,
        loginErrorMessage => 'ログイン: すみません、失敗しました。会員IDまたはパスワードが正しくありません。',
        );
}

sub databaseFailParam {
    my %param = (
        isSubmitted => shift @_,
        loginSuc => undef,
        loginErrorMessage => 'Database error. Please contact the administrator!',
        );
}
