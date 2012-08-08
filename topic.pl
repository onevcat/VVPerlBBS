#!/usr/bin/perl -w
BEGIN {require('libpath.pl')}
use strict;
use VVNetwork qw(connectDatabase selectOnePost fetchReply fetchTopic totalPageNumber fetchPosts);
use VVFileOpreation qw(templateWithName newBannerPath);
use VVCGIGenerator qw(userLink topicURL topicLink threadLink indexURL indexLink pager);
use CGI;
use CGI::Session;

my $q = CGI->new;
$q->charset('utf-8');

my $session = CGI::Session->new;

my $topicID = $q->param("id");
my $dbh = connectDatabase();
my $topicCheck = fetchTopic($dbh,$topicID);
print $q->redirect(indexURL) if !$topicCheck->rows;

my $page = $q->param('page') ? $q->param('page') : 1;
my $totalPage = totalPageNumber($dbh,VVNetwork::THREAD,$topicID);
print $q->redirect(topicURL($topicID)) if ($totalPage < $page);

my $topic = selectOnePost($dbh,'topic','title',$topicID);
my $topicTitle = $q->escapeHTML($topic->{title});
$dbh->disconnect();

my $temp = templateWithName('topic');
$temp->param(
    threads => [getThreads($page,$dbh,$q,$topicID)],
    topicTitle => $topicTitle,
    
    newThreadFormStart => $q->start_form({-action => "newpost.pl",-method => "POST"}),
    newThreadInTopic => $q->hidden({-name => 'topic',-value => $topicID}),
    newThreadSubmit => $q->submit({-name => "new",-class => "submit",-value => "このトピックに投稿",}),
    newThreadFormEnd => $q->end_form,

    canDeleteTopic => $session->param('admin'),
    deleteFormStart => $q->start_form({-action => "delete.pl",-method => "POST"}),
    hiddenTopicID => $q->hidden({-name => 'topic',-value => $topicID}),
    deleteFormSubmit => $q->submit({-name => "delete",-class => "submit",-value => "トピックを削除する"}),
    deleteFormEnd => $q->end_form,

    homeURL => indexLink("トピック"),
    currentPage => $page."/".$totalPage,
    previousPage => pager($page,$totalPage,-1,VVNetwork::THREAD,$topicID),
    nextPage => pager($page,$totalPage,1,VVNetwork::THREAD,$topicID),
    );

print $q->header(-charset=>'utf-8');
print $q->start_html(-title=>"$topicTitle | OneV's Denの掲示板",
                     -style=>{'src'=>VVNetwork::CSS},
                    );
require('header.pl');
print $temp->output;
require('footer.pl');

sub getThreads {
    my ($page,$dbh,$q,$topicID) = @_;
    my @threads = ();
    my $threadFetch = fetchPosts($dbh,VVNetwork::THREAD,$topicID,$page);
    while (my $result = $threadFetch->fetchrow_hashref()) {
        push @threads,prepareThread($q,$result);
    }
    return @threads;
}

sub prepareThread {
    my ($q, $result) = @_;

    my %thread = ();
    $thread{threadURL} = threadLink($result->{id},$result->{title});
    $thread{threadUser} = userLink($result->{threadUser});
    $thread{threadTime} = localtime($result->{time});
    my $recentTimeInSecond = $result->{mostRecentTime};
    $thread{recentUpdatedImage} = $q->img({src=>newBannerPath()}) if ((time() - 86400) < $recentTimeInSecond);
    my $recentTime = localtime($recentTimeInSecond);
    $thread{mostRecentReplyTime} = $recentTime;
    my $replyID = $result->{mostRecentReply};
    if (defined $replyID) {
        my $reply = fetchReply($dbh,$replyID);
        $thread{mostRecentReplyUser} = userLink($reply->{replyUser});
        $thread{mostRecentReplyTime} = $recentTime;
        $thread{mostRecentIsReply} = 1;
    }
    return \%thread;
}