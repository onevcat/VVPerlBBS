#!/usr/bin/perl -w
BEGIN {require('libpath.pl')}
use strict;
use VVNetwork qw(connectDatabase selectOnePost parentPostTitle);
use VVCGIGenerator qw(userLink topicURL topicLink threadLink indexURL);
use VVTextUtility qw(checkTitle checkContent convertViewContent);
use VVFileOpreation qw(templateWithName saveToTemp fullPathOfUserFile 
                        imagesListFromString stringFromImageList);
use CGI::Session;
use CGI;


$CGI::POST_MAX = 1024 * 1024;

my $q = CGI->new;
$q->charset('utf-8');

my $uploaded_file = $q->param('uploadFileName');
   if (!$uploaded_file && $q->cgi_error()) {
      print $q->header(-status=>$q->cgi_error());
      print $q->cgi_error();
      exit 0;
}

#If Cancel Button is pressed:
print $q->redirect(topicURL($q->param('topic'))) if ($q->param('cancel'));

#Check which type this submit is..
my $isImageUpload = $q->param('imgUpload');
my $isImageDelete = $q->param('imageDelete');
# If it is an image submit(upload button pressed), the previewSubmit should be undef. In case of a incident post request.
my $isPreviewSubmitted = ($isImageUpload || $isImageDelete) ? undef : $q->param('preview');

# If isPreviewSubmitted is defined, this page is submitted, it means the user may edit the thread or reply already.
# Then we should check the forms.
my $isTitleOK = 1;
my $isContentOK = 1;

# What is this post?
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

# The user is administrator or not?
my $session = CGI::Session->new;
my $userID = userLink($session->param('userID'));
my $admin = $session->param('admin');

# Normal user want to edit a topic page
print $q->redirect(indexURL) if (!$admin && $postType == 1);

my $dbh = connectDatabase();
my $topicTitle = parentPostTitle($dbh,2,$topicID);
my $threadTitle = parentPostTitle($dbh,3,$threadID);

my $title = $q->param('title'); 
my $content = $q->param('content');
my $previewTitle = undef;
my $sqlSaveTitle = undef;
my $sqlSaveContent = undef;
my $previewContent = undef;


if ($isPreviewSubmitted) {
    $previewTitle = $q->escapeHTML($title);
    $sqlSaveTitle = $previewTitle;

    $previewContent = $q->escapeHTML($content);
    $sqlSaveContent = $previewContent;
    $previewContent = convertViewContent($previewContent);

    $isTitleOK = checkTitle($sqlSaveTitle,$postType);
    $isContentOK = checkContent($sqlSaveContent,$postType);
}

my @originImages = imagesListFromString($q->param('originImageStrings'));
my @tempImages = imagesListFromString($q->param('tempImageStrings'));
if ($isImageUpload) {
    $isPreviewSubmitted = undef;
    my $uploadFileName = $q->param('uploadFileName');
    if ($uploadFileName) {
        my $tempFileName = saveToTemp($uploadFileName);
        if ($tempFileName) {
            push @tempImages,$tempFileName;
            push @originImages,$uploadFileName;
        }
    }   
}

if ($isImageDelete) {
    my $index = 0;
    $index++ until $tempImages[$index] eq $isImageDelete;
    splice(@tempImages, $index, 1);
    splice(@originImages, $index, 1);
}

# Map the tempImages to the originImages for looking up
my %imageStrings = map {$tempImages[$_], $originImages[$_]} (0..$#tempImages);

my @htmlTempImages = ();
foreach my $image (@tempImages) {
    my %imageDetail = ();
    $imageDetail{imageName} = $imageStrings{$image},
    $imageDetail{deleteImageName} = $image;
    $imageDetail{imageTempURL} = $q->img({src=>fullPathOfUserFile($image,1)});
    push @htmlTempImages, \%imageDetail;
}
my $str = $q->param('originImageStrings');

my $originImageStrings = stringFromImageList(@originImages);
my $tempImageStrings = stringFromImageList(@tempImages);

#Generate Forms
my $canUpload = 1;
my $temp = templateWithName('newpost');
if ($isPreviewSubmitted && $isTitleOK && $isContentOK){
    $temp->param(previewParam($q,$topicID,$topicTitle,$threadID,$threadTitle,$previewTitle,$previewContent,$sqlSaveTitle,$sqlSaveContent,$userID,$originImageStrings,$tempImageStrings));
    $temp->param(htmlTempImages => \@htmlTempImages);
}
else {
    $temp->param(textParam($q,$topicID,$topicTitle,$threadID,$threadTitle,$originImageStrings,$tempImageStrings));
    $temp->param(htmlTempImages => \@htmlTempImages);
    my $originImagesCount = @originImages;
    my $tempImagesCount = @tempImages;
    $canUpload = 0 if ($originImagesCount != $tempImagesCount || $tempImagesCount >= 5);
    $canUpload ? $temp->param(imageParam($q)) : 1;
}

# Can Still Upload an image

print $q->header();
print $q->start_html(-title=>"投稿|OneV's Denの掲示板",
                     -style=>{'src'=>VVNetwork::CSS},
                    );
require 'header.pl';
print $temp->output;
require('footer.pl');

sub textParam {
    my ($q,$topicID,$topicTitle,$threadID,$threadTitle,$originImageStrings,$tempImageStrings) = @_;

    my %param = (
        titleTextField => $q->textfield(-name=>'title',-value=>'',-size=>120,-maxlength=>128),
        contentTextArea => $q->textarea(-name=>'content',-default=>'',-rows=>20,-columns=>113),
        canUpload => $canUpload,
        formStart => $q->start_form({-method => "POST"}),
        formEnd => $q->end_form(),
        submit => $q->submit({-name => "preview",-class => "submit",-value => "投稿前に確認"}),
        belongTopic => $q->hidden({-name => 'topic',-value => $topicID}),
        belongThread => $q->hidden({-name => 'thread',-value => $threadID}),
        originImageStrings => $q->hidden({-name => 'originImageStrings',-value => $originImageStrings,-override =>1}),
        tempImageStrings => $q->hidden({-name => 'tempImageStrings',-value => $tempImageStrings,-override =>1}),
        isTitleOK => $isTitleOK,
        isContentOK => $isContentOK,
        cancelSubmit => $q->submit({-name => "cancel",-class => "submit",-value => "キャンセル"}),
        topicURL => topicLink($topicID,$topicTitle),
        threadURL => threadLink($threadID,$threadTitle),
        );
}

sub previewParam {
    my ($q,$topicID,$topicTitle,$threadID,$threadTitle,$previewTitle,$previewContent,$sqlSaveTitle,
        $sqlSaveContent,$userID,$originImageStrings,$tempImageStrings) = @_;
    
    my $time = localtime(time);
    my %param = (
        isPreview => 1,
        topicURL => topicLink($topicID,$topicTitle),
        threadURL => threadLink($threadID,$threadTitle),
        newPostTitle => $q->param('title'),
        newPostUser => $userID,
        postTime => $time,
        newPostContent => $previewContent,
        
        submitFormStart => $q->start_form({-action => "submit.pl", -method => "POST"}),
        hiddenTitle => $q->hidden({-name => 'title',-value => $sqlSaveTitle}),
        hiddenContent => $q->hidden({-name => 'content',-value => $sqlSaveContent}),

        belongTopic => $q->hidden({-name => 'topic',-value => $topicID}),
        belongThread => $q->hidden({-name => 'thread',-value => $threadID}),

        postSubmit => $q->submit({-name => "submit",-class => "submit",-value => "投稿"}),
        submitFormEnd => $q->end_form(),

        editFormStart => $q->start_form({-method => "POST"}),
        editSubmit => $q->submit({-name => "edit",-class => "submit",-value => "再編"}),
        editFormEnd => $q->end_form(),

        originImageStrings => $q->hidden({-name => 'originImageStrings',-value => $originImageStrings,-override =>1}),
        tempImageStrings => $q->hidden({-name => 'tempImageStrings',-value => $tempImageStrings,-override =>1}),
        );
    
}

sub imageParam {
    my $q = shift @_;
    my %param = (
        uploadFormStart => $q->start_multipart_form(),
        uploadField => $q->filefield({-name => "uploadFileName",-default => "",-size => 80,}),
        uploadSubmit => $q->submit({-name => "imgUpload",-class => "submit",-value => "アップロード"}),
        uploadFormEnd => $q->end_multipart_form(),
        );
}