#!/usr/bin/perl -w
BEGIN {require('libpath.pl')}
use strict;
use VVNetwork qw();
use VVCGIGenerator qw(messageLink regiterLink indexURL loginURL);
use VVFileOpreation qw(templateWithName);
use CGI;
use CGI::Session;

my $session = CGI::Session->new;
my $q = CGI->new;
$q->charset('utf-8');

my $userID = $session->param('userID');

my $temp = templateWithName('header');

$userID ? $temp->param(loggedInParam($q,$userID)) : $temp->param(gusetParam($q));
    
print $temp->output;

sub loggedInParam {
    my ($q,$userID) = @_;
    my %param = (
        userLoggedIn => 1,
        headerLogOutBtn => $q->submit({-name => "logout",-class => "submit",-value => "ログアウト"}),
        welcomeURL => messageLink($userID,$userID),
        headerLogoutFormStart => $q->start_form({-action => indexURL(),-method => "GET"}),
        headerLogoutFormEnd => $q->end_form(),
        )
}

sub gusetParam {
    my $q = shift @_;
    my %param = (
        userLoggedIn => undef,
        headerIdTextField => $q->textfield({-name => 'headerIdTextField', -value => ''}),
        headerPwdTextField =>$q->password_field({-name => 'headerPwdTextField', -override =>1, -value => ''}),
        headerSubmitBtn => $q->submit({-name => "login",-class => "submit",-value => "ログイン"}),
        headerKeepLoginCheck => $q->checkbox({-name => 'keep',-value => 'yes',-checked => 1,-label => ''}),
        headerRegisterLink => regiterLink("会員登録"),
        headerLoginFormStart => $q->start_form({-method => "POST",-action => loginURL()}),
        headerLoginFormEnd => $q->end_form(),
        headerLoginFromPage => $q->hidden({-name => 'url',-value => $q->url(-relative=>1)}),
        );
}