#!/usr/bin/perl
package  VVNetwork;
require  Exporter;
# use CGI::Carp qw(fatalsToBrowser);
use DBI;
use DBD::mysql;
use Digest::MD5 qw(md5_hex);

use constant {
        TOPIC   => 1,
        THREAD   => 2,
        REPLY  => 3,
        MESSAGE  => 4,
        SEARCH => 0,
};
use constant CSS => 'style/style.css';

@ISA=qw(Exporter);
@EXPORT=qw(connectDatabase hashPassword selectOnePost parentPostTitle 
    checkLoginInfo totalPageNumber fetchPosts userExist sendPost 
    changePassword deletePost canDelete fetchThread fetchReply fetchTopic fetchSearch totalSearchPage);

sub connectDatabase {
    open(CONFIG,File::Spec->catfile('config','config.pl')) or die "Can't Open, $!";
    while(<CONFIG>){
        chomp;
        my($flag, $database,$username,$password) = split(/ /);
        if($flag eq "DATABASE_CONFIG"){
            $db_dsn .= $database;
            $db_user =$username;
            $db_passwd = $password;
            last;
        }
    }
    close(CONFIG);
    my $dbh = DBI->connect("dbi:mysql:$db_dsn;mysql_enable_utf8=1",$db_user,$db_passwd,{AutoCommit => 1,Taint => 1}) 
    or die "Failed to connect to DataBase: $DBI::errstr";
    return $dbh;
}

sub selectOnePost{
    my $dbh = shift @_;
    my $table = shift @_;
    my $fields = shift @_;
    my $postID = shift @_;

    my $fetch = $dbh->prepare(
    "SELECT $fields FROM $table WHERE id=?") 
    or die $dbh->errstr;
    $fetch->execute($postID) or die $dbh->errstr;
    return $fetch->fetchrow_hashref();
}

sub parentPostTitle {
    my $dbh = shift @_;
    my $postType = shift @_;
    my $postID = shift @_;
    my $post = undef;
    if ($postType == 3) {
        $post = selectOnePost($dbh,'thread','title',$postID); 
    }
    elsif ($postType == 2) {
        $post = selectOnePost($dbh,'topic','title',$postID);    
    }
    return $post->{title} if $post;
    return undef;
}

sub totalPageNumber {
    my ($dbh,$type,$parentID) = @_;
    my $allFetch = 0;
    if ($type == TOPIC) {
        $allFetch = $dbh->prepare("SELECT * FROM topic WHERE ? AND deleted=0") or die $dbh->errstr;
    } elsif ($type == THREAD) {
        $allFetch = $dbh->prepare("SELECT * FROM thread WHERE belongTopic=? AND deleted=0") or die $dbh->errstr;        
    } elsif ($type == REPLY) {
        $allFetch = $dbh->prepare("SELECT * FROM reply WHERE belongThread=? AND deleted=0") or die $dbh->errstr;
    } elsif ($type == MESSAGE) {
        $allFetch = $dbh->prepare("SELECT * FROM message WHERE toUser=?") or die $dbh->errstr;
    }
    $allFetch->execute($parentID) or die $dbh->errstr;
    return ( 1 + int(($allFetch->rows-1)/10) );
}

sub totalSearchPage {
    my ($keyword,$field,$dbh) = @_;
    my $allFetch = "";
    if ($field eq 'thread') {
        $allFetch = $dbh->prepare("SELECT * FROM thread WHERE content LIKE ?") or die $dbh->errstr;
    } elsif ($field eq 'reply') {
        $allFetch = $dbh->prepare("SELECT * FROM reply WHERE content LIKE ?") or die $dbh->errstr;
    }
    $allFetch->execute('%'.$keyword.'%') or die $dbh->errstr;
    return 1 + int(($allFetch->rows-1)/10);
}

sub fetchPosts {
    my ($dbh,$type,$postID,$page) = @_;
    if ($type == TOPIC) {
        $resultFetch = $dbh->prepare("SELECT * FROM topic WHERE deleted=0 AND ? ORDER BY mostRecentTime DESC LIMIT ?, ?;") 
                        or die $dbh->errstr;
    } elsif ($type == THREAD) {
        $resultFetch = $dbh->prepare("SELECT * FROM thread WHERE belongTopic=? AND deleted=0 ORDER BY mostRecentTime DESC, time DESC LIMIT ?, ?") 
                        or die $dbh->errstr;
    } elsif ($type == REPLY) {
        $resultFetch =  $dbh->prepare("SELECT * FROM reply WHERE belongThread=? AND deleted=0 ORDER BY time DESC LIMIT ?, ?") 
                        or die $dbh->errstr;
    } elsif ($type == MESSAGE) {
        $resultFetch = $dbh->prepare("SELECT * FROM message WHERE toUser=? ORDER BY time DESC LIMIT ?, ?") 
                        or die $dbh->errstr;;
    }
    $resultFetch->execute($postID,($page-1)*10,$page*10) or die $dbh->errstr;
    return $resultFetch;
}

sub fetchSearch {
    my ($dbh,$field,$keyword,$page) = @_;
    my $resultFetch = "";
    if ($field eq 'thread') {
        $resultFetch = $dbh->prepare("SELECT * FROM thread WHERE content LIKE ? OR title LIKE ? AND deleted=0 ORDER BY time DESC LIMIT ?, ?") 
                       or die $dbh->errstr;
    } elsif ($field eq 'reply') {
        $resultFetch = $dbh->prepare("SELECT * FROM reply WHERE content LIKE ? OR title LIKE ? AND deleted=0 ORDER BY time DESC LIMIT ?, ?") 
                       or die $dbh->errstr;
    }
    $resultFetch->execute('%'.$keyword.'%','%'.$keyword.'%',($page-1)*10,$page*10) or die $dbh->errstr;
    return $resultFetch;
}

sub fetchThread {
    my $dbh = shift @_;
    my $threadID = shift @_;
    my $threadFetch = $dbh->prepare(
        "SELECT id,title,threadUser,mostRecentReply FROM thread WHERE thread.id=?") 
    or die $dbh->errstr;
    $threadFetch->execute( $threadID ) or die $dbh->errstr;
    return $threadFetch->fetchrow_hashref();
}

sub fetchReply {
    my $dbh = shift @_;
    my $replyID = shift @_;
    my $replyFetch = $dbh->prepare(
        "SELECT replyUser FROM reply WHERE reply.id=?") 
    or die $dbh->errstr;
    $replyFetch->execute( $replyID ) or die $dbh->errstr;
    return $replyFetch->fetchrow_hashref();
}

sub fetchTopic {
    my $dbh = shift @_;
    my $topicID = shift @_;
    my $topicCheck = $dbh->prepare("SELECT * FROM topic WHERE id=?") or die $dbh->errstr;
    $topicCheck->execute($topicID) or die $dbh->errstr;
    return $topicCheck;
}

sub sendPost {
    my $input = shift;
    my $type = $input->{type};
    my $dbh = $input->{dbh};
    my $time = time();
    if ($type == TOPIC) {
        my $insert = "INSERT INTO topic (title,mostRecentTime) VALUES (?,?)";
        my $topic = $dbh->prepare($insert);
        $topic->execute($input->{title},$time) 
                or die "Can't Add topic".$dbh->errstr;
        $topicTitle = $title;
        return 0;
    } elsif ($type == THREAD) {

        my $insert = "INSERT INTO thread (title,content,time,attach,threadUser,belongTopic,mostRecentTime) VALUES (?,?,?,?,?,?,?)";
        my $thread = $dbh->prepare($insert);
        
        $thread->execute($input->{title},$input->{content},$time,$input->{imageString},$input->{userID},$input->{topicID},$time)
                 or die "Can't Add thread ".$dbh->errstr;
        my $threadID = $thread->{mysql_insertid};
        my $updateTopic = "UPDATE `topic` SET `mostRecentThread`=?, `mostRecentTime`=? WHERE `id`=?;";
        my $topic = $dbh->prepare($updateTopic);
        $topic->execute($threadID,time(),$input->{topicID}) 
                or die "Can't Update topic :".$dbh->errstr;
        return $threadID;
    } elsif ($type == REPLY) {
        my $insert = "INSERT INTO reply (title,content,time,attach,replyUser,belongThread) VALUES (?,?,?,?,?,?)";
        my $reply = $dbh->prepare($insert);
        $reply->execute($input->{title},$input->{content},$time,$input->{imageString},$input->{userID},$input->{threadID}) 
                or die "Can't Add reply".$dbh->errstr;
        
        my $replyID = $reply->{mysql_insertid};
        my $updateTopic = "UPDATE `topic` SET `mostRecentThread`=?, `mostRecentTime`=? WHERE `id`=?;";
        my $topic = $dbh->prepare($updateTopic);
        $topic->execute($input->{threadID},$time,$topicID) 
                or die "Can't Update topic :".$dbh->errstr;

        my $updateThread = "UPDATE `thread` SET `mostRecentReply`=?, `mostRecentTime`=? WHERE `id`=?;";
        my $thread = $dbh->prepare($updateThread);
        $thread->execute($replyID,$time,$input->{threadID}) 
                 or die "Can't Update thread :".$dbh->errstr;

    } elsif ($type == MESSAGE) {
        $dbh->do("INSERT INTO message (title, content, time, fromUser,toUser) 
            VALUES (?, ?, ?, ?, ?)",undef,$input->{title},$input->{content},
            $time,$input->{fromUser},$input->{toUser})
            or die "Failed to insert row: ".$dbh->errstr;
    }
}

sub deletePost {
    my ($dbh, $type, $id) = @_;
    my $delete = "";
    if ($type == TOPIC) {
        $delete = "UPDATE `topic` SET `deleted`='1' WHERE `id`=?;";
    } elsif ($type == THREAD) {
        $delete = "UPDATE `thread` SET `deleted`='1' WHERE `id`=?;";
    } elsif ($type == REPLY) {
        $delete = "UPDATE `reply` SET `deleted`='1' WHERE `id`=?;";
    } elsif ($type == MESSAGE) {

    }
    my $action = $dbh->prepare($delete);
    $action->execute($id) or die "Can't Delete ".$dbh->errstr;
}

