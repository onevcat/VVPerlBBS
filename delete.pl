#!/usr/bin/perl -w
BEGIN {require('libpath.pl')}
use strict;
use VVNetwork qw(connectDatabase selectOnePost parentPostTitle deletePost);
use VVFileOpreation qw(templateWithName imagesListFromString moveToContent);
use VVCGIGenerator qw(topicLink topicURL threadLink threadURL indexURL);
use VVUsers qw(canDelete);
use CGI;
use CGI::Session;

my $q = CGI->new;
$q->charset('utf-8');
my $session = CGI::Session->new;
my $userID = $session->param('userID');
my $admin = $session->param('admin');

my $postType = undef;
my $topicID = $q->param('topic'); #if defined($topicID), current post is a topic.
my $threadID = $q->param('thread'); #if defined($threadID), current post is a thread.
my $replyID = $q->param('reply'); #if defined($threadID), current post is a reply.

my $currentPost = undef;
my $currentPostUser = undef;
my $dbh = connectDatabase();

my $deleteID = undef;
if ($replyID) {
    $postType = VVNetwork::REPLY;
    $currentPost = selectOnePost($dbh,'reply','title,replyUser',$replyID);
    $currentPostUser = $currentPost->{'replyUser'};
    $deleteID = $replyID;
} elsif ($threadID) {
    $postType = VVNetwork::THREAD;
    $currentPost = selectOnePost($dbh,'thread','title,threadUser',$threadID);
    $currentPostUser = $currentPost->{'threadUser'};
    $deleteID = $threadID;
} else {
    $postType = VVNetwork::TOPIC;
    $currentPost = selectOnePost($dbh,'topic','title',$topicID);
    $deleteID = $topicID;
}

print $q->redirect(indexURL) if (!$currentPost);
print $q->redirect(indexURL) if (!$admin && $postType == VVNetwork::TOPIC);

my $isReadyToDelete = canDelete($userID,$currentPostUser,$admin);
my $errMsg = "";

my $topicTitle = undef;
my $threadTitle = undef;
if ($isReadyToDelete) {
    deletePost($dbh,$postType,$deleteID);
    $topicTitle = parentPostTitle($dbh,2,$topicID);
    $threadTitle = parentPostTitle($dbh,3,$threadID);
} else {
    $errMsg = "すみません、投稿を削除失敗しました。";
}

my $temp = templateWithName('delete');

$temp->param(
                isReadyToDelete => $isReadyToDelete,
                topicURL => topicLink($topicID,$topicTitle),
                threadURL => threadLink($threadID,$threadTitle),
                redirectURL => $threadID ? threadURL($threadID) : topicURL($topicID),
                errMsg => $errMsg,
            );

print $q->header(-charset=>'utf-8');
print $q->start_html(-title=>"投稿削除|OneV's Denの掲示板",
                     -style=>{'src'=>VVNetwork::CSS},
                    );
require('header.pl');
print $temp->output;
require('footer.pl');

