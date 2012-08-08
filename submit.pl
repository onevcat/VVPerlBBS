#!/usr/bin/perl -w
BEGIN {require('libpath.pl')}
use strict;
use VVNetwork qw(connectDatabase parentPostTitle sendPost);
use VVTextUtility qw(checkTitle checkContent);
use VVFileOpreation qw(templateWithName imagesListFromString moveToContent);
use VVCGIGenerator qw(topicLink threadLink threadURL indexURL);
use CGI;
use CGI::Session;

my $q = CGI->new;
$q->charset('utf-8');
my $session = CGI::Session->new;
my $userID = $session->param('userID');
my $admin = $session->param('admin');

my $postType = undef;
my $topicID = $q->param('topic'); #if defined($topicID), current post is a thread.
my $threadID = $q->param('thread'); #if defined($threadID), current post is a reply.
if ($threadID) {
    $postType = VVNetwork::REPLY;
} elsif ($topicID) {
    $postType = VVNetwork::THREAD;
} else {
    $postType = VVNetwork::TOPIC;
}

print $q->redirect(indexURL) if (!$admin && $postType == 1);

my $isTitleOK = undef;
my $isContentOK = undef;
my $isSubmitted = $q->param('submit'); 

my $title = $q->param('title'); 
my $content = $q->param('content');

my $imageString = $q->param('tempImageStrings');

if ($isSubmitted) {    
    $isTitleOK = checkTitle($title,$postType);
    $isContentOK = checkContent($content,$postType);
}

my $isReadyToSubmit = $isTitleOK && $isContentOK;
my $errMsg = "";

my $dbh = connectDatabase();
my $topicTitle = parentPostTitle($dbh,VVNetwork::THREAD,$topicID);
my $threadTitle = parentPostTitle($dbh,VVNetwork::REPLY,$threadID);
if ($isReadyToSubmit) {
    if ($postType == VVNetwork::TOPIC) {
        sendPost({dbh => $dbh,
                  title => $title,
                  type => VVNetwork::TOPIC});
    } elsif ($postType == VVNetwork::THREAD) {
        moveImages($imageString);
        $threadID = sendPost({dbh => $dbh,
                              title => $title,
                              content => $content,
                              imageString => $imageString,
                              userID => $userID,
                              topicID => $topicID,
                              type => VVNetwork::THREAD});
        $threadTitle = $title;
    } elsif ($postType == VVNetwork::REPLY) {
        moveImages($imageString);
        sendPost({dbh => $dbh,
                  title => $title,
                  content => $content,
                  imageString => $imageString,
                  userID => $userID,
                  threadID => $threadID,
                  type => VVNetwork::REPLY});
    }
} else {
    $errMsg = "すみません、入力されが正しくないようです。";
}


my $temp = templateWithName('submit');

$temp->param(submitParam($topicID,$topicTitle,$threadID,$threadTitle,$isReadyToSubmit,$errMsg));

print $q->header(-charset=>'utf-8');
print $q->start_html(-title=>"投稿完了 | OneV's Denの掲示板",
                     -style=>{'src'=>VVNetwork::CSS},
                    );
require('header.pl');
print $temp->output;
require('footer.pl');

sub submitParam {
    my ($topicID,$topicTitle,$threadID,$threadTitle,$isReadyToSubmit,$errMsg) = @_;
    my %param = (
        isReadyToSubmit => $isReadyToSubmit,
        topicURL => topicLink($topicID,$topicTitle),
        threadURL => threadLink($threadID,$threadTitle),
        redirectURL => threadURL($threadID),
        errMsg => $errMsg,
        );
}

sub moveImages {
    my $imageString = shift @_;
    foreach (imagesListFromString($imageString)) {
        moveToContent($_)    
    }
}
