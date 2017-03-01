#!/usr/local/bin/perl -w
use v5.12;
use HTML::Strip;

while (<STDIN>) {
  if (m/^<font color='#[[:xdigit:]]+'>.*<\/font>\:<font color='#[[:xdigit:]]+'>\d+<\/font>\(<font color='#[[:xdigit:]]+'>#\d+<\/font>\)\:/) {
    my $line = $_;
    chomp $line;
    my $hs = HTML::Strip->new();
    my $text = $hs->parse($line);
    print "$text<br>\n";
  }
}
