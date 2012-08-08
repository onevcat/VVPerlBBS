#!/usr/bin/perl -w
BEGIN {require('libpath.pl')}
use strict;
use VVNetwork qw(connectDatabase selectOnePost totalPageNumber canDelete fetchPosts);
use VVUsers qw(canDelete);
use VVTextUtility qw(convertViewContent);
use VVFileOpreation qw(templateWithName fullPathOfUserFile imagesListFromString);
use VVCGIGenerator qw(userLink topicLink threadURL threadLink indexURL indexLink pager);
use CGI;
use CGI::Session;

my $q = CGI->new;
$q->charset('utf-8');

my $threadID = $q->param("id");
my $dbh = connectDatabase();
my $thread = selectOnePost($dbh,'thread','*',$threadID);
print $q->redirect(indexURL) if (!$thread);

my $page = $q->param('page') ? $q->param('page') : 1;
my $totalPage = totalPageNumber($dbh,VVNetwork::REPLY,$threadID);
print $q->redirect(threadURL($threadID)) if ($totalPage < $page);


my $topic = selectOnePost($dbh,'topic','title',$thread->{belongTopic});
print $q->redirect(indexURL) if (!$topic);


my $threadContent = convertViewContent($q->escapeHTML($thread->{content}));

# Fill the template
my $temp = templateWithName('thread');
my $threadTime = localtime($thread->{time});

my $session = CGI::Session->new;
$temp->param(
    threadTitle => $q->escapeHTML($thread->{title}),
    topicURL => topicLink($thread->{belongTopic},$topic->{title}),
    homeURL => indexLink("トピック"),
    threadID => $threadID,
    threadUser => userLink($thread->{threadUser}),
    threadTime => $threadTime,
    threadContent => $threadContent,
    replies => [getReplies($page,$dbh,$q,$threadID)],
    replyFormStart => $q->start_form({-action => "newpost.pl", -method => "POST"}),
    hiddenTopicID => $q->hidden({-name => 'topic',-value => $thread->{belongTopic}}),
    hiddenThreadID => $q->hidden({-name => 'thread',-value => $threadID}),
    replyFormSubmit => $q->submit({-name => "submit",-class => "submit",-value => "返信"}),
    replyFormEnd => $q->end_form,
    canDeleteThread => canDelete($session->param('userID'), $thread->{threadUser}, $session->param('admin')),
    deleteFormStart => $q->start_form({-action => "delete.pl", -method => "POST"}),
    deleteFormSubmit => $q->submit({-name => "delete",-class => "submit",-value => "スレッドを削除する"}),
    deleteFormEnd => $q->end_form,
    threadImages => [getThreadImages($q,$thread->{attach})],
    threadIsDeleted => $thread->{deleted},
    currentPage => $page."/".$totalPage,
    previousPage => pager($page,$totalPage,-1,VVNetwork::REPLY,$threadID),
    nextPage => pager($page,$totalPage,1,VVNetwork::REPLY,$threadID),
    );

$dbh->disconnect();

print $q->header(-charset=>'utf-8');
print $q->start_html(-title=>"$thread->{title} | OneV's Denの掲示板",
                     -style=>{'src'=>VVNetwork::CSS},
                    );
require('header.pl');
print $temp->output;
require('footer.pl');

sub getThreadImages {
    my ($q,$imageString) = @_;
    my @threadImages = ();
    foreach my $image (imagesListFromString($imageString)) {
        my %imageDetail = ();
        $imageDetail{threadImageURL} = $q->img({src=>fullPathOfUserFile($image,0)});
        push @threadImages, \%imageDetail;
    }
    return @threadImages;
}
# $result->{attach}
sub getReplyImages {
    my ($q,$imageString) = @_;
    my @replyImages = ();
    foreach my $image (imagesListFromString($imageString)) {
        my %imageDetail = ();
        $imageDetail{replyImageURL} = $q->img({src=>fullPathOfUserFile($image,0)});
        push @replyImages, \%imageDetail;
    }
    return @replyImages;
}

sub getReplies {
    my ($page,$dbh,$q,$threadID) = @_;
    my @replies = ();
    my $replyFetch = fetchPosts($dbh,VVNetwork::REPLY,$threadID,$page);
    while (my $result = $replyFetch->fetchrow_hashref()) {
        push @replies,prepareReply($q,$result);
    }
    return @replies;
}

sub prepareReply {
    my ($q, $result) = @_;
    my $session = CGI::Session->new;
    my %reply = ();
    $reply{replyID} = $result->{id};
    $reply{replyTitle} = $q->escapeHTML($result->{title});
    $reply{replyUser} = userLink($result->{replyUser});
    $reply{replyTime} = localtime($result->{time});
    $reply{replyImages} = [getReplyImages($q,$result->{attach})],
    $reply{replyContent} = convertViewContent($q->escapeHTML($result->{content}));
    my $canDeleteReply = canDelete($session->param('userID'), $result->{replyUser},$session->param('admin'));

    $reply{canDeleteReply} = $canDeleteReply;
    if ($canDeleteReply) {
        $reply{deleteFormStart} = $q->start_form({-action => "delete.pl", -method => "POST"}),
        $reply{hiddenTopicID} = $q->hidden({-name => 'topic',-value => $thread->{belongTopic}}),
        $reply{hiddenThreadID} = $q->hidden({-name => 'thread',-value => $threadID}),
        $reply{hiddenReplyID} = $q->hidden({-name => 'reply',-value => $result->{id}}),
        $reply{deleteFormSubmit} = $q->submit({-name => "delete",-class => "submit",-value => "返信を削除する"}),
        $reply{deleteFormEnd} = $q->end_form,
    }
    return \%reply;
}
