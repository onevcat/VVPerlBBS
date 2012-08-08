package  VVFileOpreation;
require  Exporter;

use File::Spec;
use HTML::Template;
use File::Copy qw(copy move);
use File::Temp qw(tempfile);
use File::Basename;
use Fatal qw(copy chmod);

@ISA=qw(Exporter);
@EXPORT=qw(templateWithName saveToTemp moveToContent 
           fullPathOfUserFile imagesListFromString stringFromImageList 
            newBannerPath); 

sub templateWithName {
    my $filename = shift @_;
    $temp = HTML::Template->new(filename => File::Spec->catfile('html_template',$filename.'.html'))
        or die 'Can not open html template. $!';
    return $temp;
}

sub saveToTemp {
    my $uploadFileName = shift @_;
    my($filename, $directories, $suffix) = fileparse($uploadFileName,qr/\.[^.]*/);
    my ($fh_save, $newFileName) = tempfile("img_XXXXXXXX",DIR=>File::Spec->catdir('img','user_content_tmp'),SUFFIX => $suffix);
    binmode($uploadFileName);
    binmode($fh_save);
    chmod 0644, $newFileName;
    copy($uploadFileName, $fh_save) or die $!;

    return basename($newFileName);
}

sub moveToContent {
    my $tempFileName = shift @_;
    my $fullTempFilePath = File::Spec->catfile(File::Spec->catdir('img','user_content_tmp'),$tempFileName);
    my $userContentFile = File::Spec->catfile('img','user_content',$tempFileName);
    return move($fullTempFilePath, $userContentFile);
}

sub fullPathOfUserFile {
    my $fileBaseName = shift @_;
    my $temp = shift @_;
    $temp ? return File::Spec->catfile(File::Spec->catdir('img','user_content_tmp'),$fileBaseName) 
          : return File::Spec->catfile('img','user_content',$fileBaseName);
}

#We use ':' for the seperator of image names.
sub imagesListFromString {
    return split (/:/,shift @_);
}

sub stringFromImageList {
    return join(':',@_);
}

sub newBannerPath {
    return File::Spec->catfile('img','new.gif');
}
