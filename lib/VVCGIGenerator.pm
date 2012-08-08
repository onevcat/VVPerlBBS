package  VVCGIGenerator;
require  Exporter;

use CGI qw/:standard/;
use VVNetwork qw();

@ISA=qw(Exporter);
@EXPORT=qw(userLink guestName topicURL topicLink 
           threadURL threadLink indexLink indexURL 
           messageURL messageLink pager regiterLink loginURL);

sub userLink {
    my $userID = shift @_;
    my $link = $userID ? a({-href => "user.pl?userID=".$userID},$userID) : guestName();
    return $link;
}


sub guestName {
    return "guest";
}

sub topicLink {
    my ($topicID,$topicTitle,$page) = @_;
    charset('utf-8');
    my $link = $page ? a({-href => topicURL($topicID)."&page=".$page},escapeHTML($topicTitle))
                     : a({-href => topicURL($topicID)},escapeHTML($topicTitle));
    return $link;
}

sub topicURL {
    my $topicID = shift @_;
    return "topic.pl?id=".$topicID;
}

sub threadLink {
    my ($threadID,$threadTitle,$page) = @_;
    charset('utf-8');
    my $link = $page ? a({-href => threadURL($threadID)."&page=".$page},escapeHTML($threadTitle))
                     : a({-href => threadURL($threadID)},escapeHTML($threadTitle));
    return $link;
}

sub threadURL {
    my $threadID = shift @_;
    return "thread.pl?id=".$threadID;
}

sub indexLink {
    my ($indexTitle,$page) = @_;
    charset('utf-8');
    my $link = $page ? a({-href => indexURL()."?page=".$page},escapeHTML($indexTitle))
                     : a({-href => indexURL()},escapeHTML($indexTitle));
    return $link;
}

sub indexURL {
    return "index.pl";
}

sub messageLink {
    my ($userID,$title,$page) = @_;
    charset('utf-8');
    my $link = $page ? a({-href => messageURL($userID)."&page=".$page},escapeHTML($title))
                     : a({-href => messageURL($userID)},escapeHTML($title));
    return $link;
}

sub messageURL {
    my $userID = shift @_;
    return "user.pl?userID=".$userID;
}

sub searchLink {
    my ($keyword,$title,$page,$searchType) = @_;
    charset('utf-8');
    my $link = $page ? a({-href => searchURL($keyword,$searchType)."&page=".$page},escapeHTML($title))
                     : a({-href => searchURL($keyword,$searchType)},escapeHTML($title));
    return $link;
}

sub searchURL {
    my ($keyword, $type) = @_;
    return "search.pl?keyword=".$keyword."&type=".$type;
}

sub regiterURL {
    return "registration.pl";
}

sub regiterLink {
    my ($title) = @_;
    charset('utf-8');
    my $link = a({-href => regiterURL()},$title);
    return $link;
}

sub loginURL {
    return "login.pl";
}

sub pager {
    my ($currentPage,$totalPage,$next,$type,$id,$searchType) = @_;
    if ($next == -1) {
        if ($currentPage == 1) {
            return "前のページ";
        } else {
            if ($type == VVNetwork::TOPIC) {
                return indexLink("前のページ",$currentPage - 1);
            } elsif ($type == VVNetwork::THREAD) {
                return topicLink($id,"前のページ",$currentPage - 1);    
            } elsif ($type == VVNetwork::REPLY) {
                return threadLink($id,"前のページ",$currentPage - 1);
            } elsif ($type == VVNetwork::MESSAGE) {
                return messageLink($id,"前のページ",$currentPage - 1);
            } elsif ($type == VVNetwork::SEARCH) {
                return searchLink($id,"次のページ",$currentPage - 1,$searchType);
            }
            
        }
    } elsif ($next == 1) {
        if ($currentPage == $totalPage) {
            return "次のページ";
        } else {
            if ($type == VVNetwork::TOPIC) {
                return indexLink("次のページ",$currentPage + 1);
            } elsif ($type == VVNetwork::THREAD) {
                return topicLink($id,"次のページ",$currentPage + 1);    
            } elsif ($type == VVNetwork::REPLY) {
                return threadLink($id,"次のページ",$currentPage + 1);  
            } elsif ($type == VVNetwork::MESSAGE) {
                return messageLink($id,"次のページ",$currentPage + 1);
            } elsif ($type == VVNetwork::SEARCH) {
                return searchLink($id,"次のページ",$currentPage + 1,$searchType);
            }
            
        }
    }
}