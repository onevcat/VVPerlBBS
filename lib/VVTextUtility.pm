#!/usr/bin/perl
package  VVTextUtility;
require  Exporter;

use VVNetwork qw();
use URI::Find;
use Email::Find;
use Encode;

@ISA=qw(Exporter);
@EXPORT=qw(checkNotEmptyString checkIsValidString checkTitle 
 checkContent convertViewContent highlightKeyText); 

sub checkNotEmptyString {
    my $str = shift @_;
    return $str ? !($str =~ /^(\s)*$/) : undef;
}

#checkIsValidString($string, $upperWordCount)
sub checkIsValidString {
    my $s = shift @_;
    my $upperCount = shift @_;
    $s = decode 'utf8', $s;
    return (length $s <= $upperCount) ? 1 : undef;
}

sub checkTitle {
    my ($title,$postType) = @_;
    
    if ($postType == VVNetwork::TOPIC || $postType == VVNetwork::THREAD) { #If the submitted post is a thread or topic, then we should check both empty and valid
        return checkNotEmptyString($title) && checkIsValidString($title,128);
    }
    elsif ($postType == VVNetwork::MESSAGE) { #It is a message. Check both not empty and length
        return checkNotEmptyString($title) && checkIsValidString($title,64);   
    }
    elsif ($postType == VVNetwork::REPLY) { #It is a reply. Just check the valid.

        return checkIsValidString($title,128);
    }
    else {return undef};
}

sub checkContent {
    my ($content,$postType) = @_;
    if ($postType == VVNetwork::MESSAGE) {
        return checkNotEmptyString($content) && checkIsValidString($content,512);
    } elsif ($postType == VVNetwork::TOPIC) {
        return 1
    } else {
        return checkNotEmptyString($content) && checkIsValidString($content,4096);    
    }   
}

sub convertViewContent {
    my $s = shift @_;
    $s = replaceURL($s);
    $s = replaceEmail($s);
    $s =~ s{\n}{<br/>}g;   
    return $s;
}

sub highlightKeyText {
    my ($text,$key) = @_;
    $text =~ s/($key)/<font color="blue">$key<\/font>/g;
    return $text; 
}

sub replaceEmail {
    my $data = shift @_;
    my $finder = Email::Find->new(
      sub {
          my($email, $orig_email) = @_;
          my($address) = $email->format;
          return qq|<a href="mailto:$address">$orig_email</a>|;
      }
  );
  $finder->find(\$data);
  return $data;
}

sub replaceURL {
    my $data = shift @_;
    require URI::Find::Schemeless;
    my $finder = URI::Find::Schemeless->new(
        sub {
            my($uri, $orig_uri) = @_;
            return qq|<a href="$uri">$orig_uri</a>|;
        }
    );
    $finder->find( \$data );
    return $data;
}
