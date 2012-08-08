#!/usr/bin/perl -w
BEGIN {require('libpath.pl')}
use VVFileOpreation qw(templateWithName);
 
my $temp = templateWithName('footer');
my $lastUpdate = localtime(time() - (-M 'footer.pl') * 86400);

$temp->param(lastUpdateTime => $lastUpdate);
print $temp->output;
