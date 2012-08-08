#!/usr/bin/perl -w
BEGIN {require('libpath.pl')}
use strict;
use VVNetwork qw(connectDatabase selectOnePost fetchSearch totalSearchPage);
use VVTextUtility qw(convertViewContent highlightKeyText);
use VVFileOpreation qw(templateWithName fullPathOfUserFile imagesListFromString);
use VVCGIGenerator qw(userLink indexURL indexLink pager);
use CGI;
use CGI::Session;

my $q = CGI->new;
$q->charset('utf-8');
my $keyword = $q->param("keyword");
my $searchType = $q->param("type");
my $validType = ($searchType eq 'thread') || ($searchType eq 'reply');
print $q->redirect(indexURL) if ($keyword =~ /^\s*$/ || !$validType);

my $dbh = connectDatabase();

my $page = $q->param('page') ? $q->param('page') : 1;
my $totalPage = totalSearchPage($keyword,$searchType,$dbh);
print $q->redirect(indexURL) if ($totalPage < $page);

my $searchThreadLink = "";
my $searchReplyLink = "";

my @posts = ();
if ($searchType eq 'thread') {
    $searchThreadLink = "スレッド";
    $searchReplyLink = $q->a({-href => "search.pl?keyword=".$keyword."&type=reply"},"返信");
} else {
    $searchThreadLink = $q->a({-href => "search.pl?keyword=".$keyword."&type=thread"},"スレッド");
    $searchReplyLink = "返信";
}

$dbh->disconnect();

# Fill the template
my $temp = templateWithName('search');
$temp->param(
    posts => [getPosts($searchType,$keyword,$page,$dbh,$q)],
    homeURL => indexLink("トピック"),
    searchKey => $keyword,
    searchThreadLink => $searchThreadLink,
    searchReplyLink => $searchReplyLink,
    currentPage => $page."/".$totalPage,
    previousPage => pager($page,$totalPage,-1,VVNetwork::SEARCH,$keyword,$searchType),
    nextPage => pager($page,$totalPage,1,VVNetwork::SEARCH,$keyword,$searchType),
    );

print $q->header(-charset=>'utf-8');
print $q->start_html(-title=>"$keyword 検索| OneV's Denの掲示板",
                     -style=>{'src'=>VVNetwork::CSS},
                    );
require('header.pl');
print $temp->output;
require('footer.pl');

sub getPosts {
    my ($field,$keyword,$page,$dbh,$q) = @_;
    my @posts = ();
    my $postFetch = fetchSearch($dbh,$field,$keyword,$page);
    while (my $result = $postFetch->fetchrow_hashref()) {
        push @posts,preparePost($q,$result,$field,$keyword);
    }
    return @posts;
}

sub preparePost {
    my ($q,$result,$field,$keyword) = @_;
    my %post = ();
    if ($field eq 'thread') {
        $post{postID} = $result->{id};
        $post{postTitle} = highlightKeyText($result->{title},$keyword);
        $post{postUser} = userLink($result->{threadUser});
        $post{postTime} = localtime($result->{time});
        $post{postImages} = [prepareImage($q,$result->{attach})],
        $post{postContent} = highlightKeyText(convertViewContent($result->{content}),$keyword);
        push @posts,\%post;
    } elsif ($field eq 'reply') {
        $post{postID} = $result->{belongThread};
        $post{postTitle} = highlightKeyText($result->{title},$keyword);
        $post{postUser} = userLink($result->{replyUser});
        $post{postTime} = localtime($result->{time});
        $post{postImages} = [prepareImage($q,$result->{attach})],
        $post{postContent} = highlightKeyText(convertViewContent($result->{content}),$keyword);
        push @posts,\%post;
    }
    return \%post;
}

sub prepareImage {
    my ($q,$imageString) = @_;
    my @postImages = ();
    foreach my $image (imagesListFromString($imageString)) {
        my %imageDetail = ();
        $imageDetail{postImageURL} = $q->img({src=>fullPathOfUserFile($image,0)});
        push @postImages, \%imageDetail;
    }
    return @postImages
}
