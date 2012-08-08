#!/usr/bin/perl -w
BEGIN {require('libpath.pl')}
use strict;
use VVNetwork qw(connectDatabase totalPageNumber fetchPosts fetchThread fetchReply totalPageNumber);
use VVFileOpreation qw(templateWithName newBannerPath);
use VVCGIGenerator qw(userLink topicLink threadLink indexLink indexURL pager);
use CGI;
use CGI::Session;

my $q = CGI->new;
$q->charset('utf-8');

my $session = CGI::Session->new;

# Logout
if ($q->param('logout')) {
    $session->clear();
    $session->delete();
    $session->flush();
}

my $userID = $session->param('userID');
my $admin = $session->param('admin');

my $page = $q->param('page') ? $q->param('page') : 1;

my $dbh = connectDatabase();
my $totalPage = totalPageNumber($dbh,VVNetwork::TOPIC,1);
print $q->redirect(indexURL) if ($totalPage < $page);

$dbh->disconnect();

my $temp = templateWithName('index');
$temp->param(
    topics => [getTopics($page,$dbh,$q)],
    searchFormStart => $q->start_form({-method => "GET",-action => 'search.pl'}),
    searchTextField => $q->textfield({-name => 'keyword', -value => ''}),
    searchTextSubmit => $q->submit({-name => "search",-class => "submit",-value => "検索"}),
    searchFormEnd => $q->end_form,
    currentPage => $page."/".$totalPage,
    previousPage => pager($page,$totalPage,-1,VVNetwork::TOPIC),
    nextPage => pager($page,$totalPage,1,VVNetwork::TOPIC),
    );

if ($admin) {
    $temp->param(
        canAddTopic => 1,
        addTopicFormStart => $q->start_form({-action => "newpost.pl",-method => "POST"}),
        addTopicFormSubmit => $q->submit({-name => "newtopic",-class => "submit",-value => "トピックを作成する",}),
        addTopicFormEnd => $q->end_form,
        );
}
print $q->header(-charset=>'utf-8');
print $q->start_html(-title=>"OneV's Denの掲示板",
                     -style=>{'src'=>VVNetwork::CSS},
                    );
require('header.pl');
print $temp->output;
require('footer.pl');

sub getTopics {
    my ($page,$dbh,$q) = @_;
    my @topics = ();
    my $topicFetch = fetchPosts($dbh,VVNetwork::TOPIC,1,$page);
    while (my $result = $topicFetch->fetchrow_hashref()) {
        push @topics,prepareTopic($q,$result);
    }
    return @topics;
}

sub prepareTopic {
    my ($q, $result) = @_;
    my %topic = ();
    $topic{topicURL} = topicLink($result->{id},$result->{title});
    $topic{recentUpdatedImage} = $q->img({src=>newBannerPath()}) if ((time() - 86400) < $result->{mostRecentTime});
    my $threadID = $result->{mostRecentThread};
    if (defined $threadID) {
        my $user = undef;
        my $thread = fetchThread($dbh,$threadID);

        my $replyID = $thread->{mostRecentReply} if $thread;
        if (defined $replyID) {
            my $reply = fetchReply($dbh, $replyID);
            $topic{mostRecentPostUser} = userLink($reply->{replyUser});
            $topic{mostPostIsReply} = 1;
        }
        else {
            $topic{mostRecentPostUser} = userLink($thread->{threadUser});
        }
        $topic{mostRecentThreadURL} = threadLink($thread->{id},$thread->{title});
        $topic{mostRecentThreadTime} = localtime($result->{mostRecentTime});
    }
    return \%topic;
}

