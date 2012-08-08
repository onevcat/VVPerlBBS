#!/usr/bin/perl -w
BEGIN {require('libpath.pl')}
use strict;
use VVNetwork qw(connectDatabase totalPageNumber fetchPosts sendPost);
use VVUsers qw(checkLoginInfo userExist changePassword);
use VVTextUtility qw(checkNotEmptyString checkTitle checkContent convertViewContent);
use VVFileOpreation qw(templateWithName);
use VVCGIGenerator qw(guestName indexURL pager messageURL);
use CGI::Session;
use CGI;

my $session = CGI::Session->new;
my $userID = $session->param('userID');

my $q = CGI->new;
$q->charset('utf-8');
my $inputUserID = $q->param('userID');
my $guestName = guestName;
print $q->redirect(indexURL) if (!checkNotEmptyString($inputUserID) || $inputUserID =~ /^($guestName)$/i);

my $isSelf = $userID eq $inputUserID;
my $dbh = connectDatabase();
my $temp = templateWithName('user');

if ($isSelf) {
    # User request change password. Try it~
    my $changePasswordMessage = tryChangePassword($dbh, $userID, 
        $q->param('oldPassword'), $q->param('newPassword'), $q->param('againPassword')) 
        if ($q->param('changePassword'));

    my $page = $q->param('page') ? $q->param('page') : 1;
    my $totalPage = totalPageNumber($dbh,VVNetwork::MESSAGE,$userID);
    print $q->redirect(messageURL($userID)) if ($totalPage < $page);

    $temp->param(
        inputUserID => $inputUserID,
        isSelf => 1,
        changePasswordFormStart => $q->start_form({-method => "POST"}),
        oldPasswordTextField => $q->password_field({-name => 'oldPassword', -override =>1, -value => ''}),
        newPasswordTextField => $q->password_field({-name => 'newPassword', -override =>1, -value => ''}),
        againPasswordTextField => $q->password_field({-name => 'againPassword', -override =>1, -value => ''}),
        changePasswordSubmit => $q->submit({-name => "changePassword",-class => "submit",-value => "パスワードを変更"}),
        changePasswordFormEnd => $q->end_form(),
        messages => [getMessages($page,$userID,$dbh,$q)],
        changePasswordMessage => $changePasswordMessage,
        hiddenUserID => $q->hidden({-name => 'userID',-value => $userID}),
        currentPage => $page."/".$totalPage,
        previousPage => pager($page,$totalPage,-1,VVNetwork::MESSAGE,$userID), 
        nextPage => pager($page,$totalPage,1,VVNetwork::MESSAGE,$userID),
    )
} else {
    my $messageSendMessage = trySendMessage($dbh,$q->escapeHTML($q->param('title')),
                                            $q->escapeHTML($q->param('content')),$inputUserID,$userID) 
                                           if ($q->param('send'));
    $temp->param(
        inputUserID => $inputUserID,
        isSelf => 0,
        userID => $userID,
        messageFormStart => $q->start_form({-method => "POST"}),
        messageTitleTextFild => $q->textfield(-name=>'title',-value=>'',-size=>150,-maxlength=>64),
        messageContentTextFild => $q->textarea(-name=>'content',-default=>'',-rows=>20,-columns=>143),
        messageSubmit => $q->submit({-name => "send",-class => "submit",-value => "送信する"}),
        messageFormEnd => $q->end_form(),
        messageSendMessage => $messageSendMessage,
        hiddenUserID => $q->hidden({-name => 'userID',-value => $inputUserID}),
    )
}

$dbh->disconnect();

print $q->header(-charset=>'utf-8');
print $q->start_html(-title=>"会員info|OneV's Denの掲示板",
                     -style=>{'src'=>VVNetwork::CSS},
                    );
require 'header.pl';
print $temp->output;
require 'footer.pl';


sub getMessages {
    my ($page,$userID,$dbh,$q) = @_;
    my @messages = ();
    my $resultFetch = fetchPosts($dbh,VVNetwork::MESSAGE,$userID,$page);
    while (my $result = $resultFetch->fetchrow_hashref()) {
        push @messages,prepareMessage($q,$result);
    }
    return @messages;
}

sub tryChangePassword {
    my ($dbh, $userID, $oldPassword, $newPassword, $againPassword) = @_;
    
    #Check the error entering.
    my $error = formNotFilled($oldPassword, $newPassword, $againPassword);
    $error = newPasswordNotValid($newPassword) unless $error;
    $error = passwordNotMatch($newPassword,$againPassword) unless $error;
    return $error if $error;

    #Check login info. If ok, change the password.
    my $userLoggedIn = checkLoginInfo($userID,$oldPassword,$dbh,undef);
    if ($userLoggedIn == 1) {
        return "パスワードを変更成功。" if changePassword($dbh,$userID,$newPassword);
    } else {
        return "会員IDまたはパスワードが正しくありません。";
    }
}

sub formNotFilled {
    my ($oldPassword, $newPassword, $againPassword) = @_;
    if (!(checkNotEmptyString($oldPassword) && checkNotEmptyString($newPassword) && checkNotEmptyString($againPassword))) {
        return "パスワードを入力必須";
    }
    return undef;
}

sub newPasswordNotValid {
    my $newPassword = shift @_;
    if (!($newPassword =~ /^[A-Za-z0-9`~!@#%^&*()_+-=;:?,.]{6,31}$/)) {
        return "入力されが正しくないようです";   
    }
    return undef;
}

sub passwordNotMatch {
    my ($newPassword, $againPassword) = @_;
    if ($newPassword ne $againPassword) {
        return "パスワードが一致しません。もう一度入力してください。";
    }
    return undef;
}

sub prepareMessage {
    my ($q, $result) = @_;
    my %message = ();
    $message{messageID} = $result->{id};
    $message{messageTitle} = $q->escapeHTML($result->{title});
    $message{fromUser} = $result->{fromUser} ? $result->{fromUser} : guestName;
    $message{messageTime} = localtime($result->{time});
    $message{messageContent} = convertViewContent($q->escapeHTML($result->{content}));
    return \%message;
}

sub trySendMessage {
    my ($dbh,$title,$content,$toUser,$fromUser) = @_;
     #Check the error entering.
    my $error = messageNotFilled($title,$content);
    $error = toUserNotExist($dbh,$toUser) unless $error;
    return $error if $error;

    #Every thing seems OK, send message.
    return sendMessage({
            dbh => $dbh,
            title => $title,
            content => $content,
            fromUser => $fromUser,
            toUser => $toUser,
            type => VVNetwork::MESSAGE,
        })
}

sub messageNotFilled {
    my ($messageTitle,$messageContent) = @_;
    if (! (checkTitle($messageTitle,VVNetwork::MESSAGE) && checkContent($messageContent,VVNetwork::MESSAGE)) ) {
        return "タイトルとメッセージの内容を入力必須";
    }
    return undef;
}

sub toUserNotExist {
    my ($dbh,$inputUserID) = @_;
    if (!userExist($dbh,$inputUserID)) {
        return "その会員がいません。";
   }
   return undef;
}

sub sendMessage {
    my $input = shift;
    if (sendPost($input)){
        return "送信は成功しました";
    }
    else {
        return "送信は失敗しました";
    }
}
