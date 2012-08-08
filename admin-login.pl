#!/usr/bin/perl -w
BEGIN {require('libpath.pl')}

use VVNetwork qw();
use VVFileOpreation qw(templateWithName);
use CGI::Session;
use CGI;
my $q = CGI->new;
$q->charset('utf-8');
my $session = CGI::Session->new;
my $userID = $session->param('userID');

$session->clear();
$session->delete();
$session->flush();

my $temp = templateWithName('admin-login');
$temp->param(userLoggedIn => $userID);

print $q->header(-charset=>'utf-8');
print $q->start_html(-title=>"管理者ログイン|OneV's Denの掲示板",
                     -style=>{'src'=>VVNetwork::CSS},
                    );
require 'header.pl';
print $temp->output;
