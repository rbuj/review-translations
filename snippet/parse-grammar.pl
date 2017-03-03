#!/usr/local/bin/perl -w
use v5.12;

while (<STDIN>) {
  if (m/^<br\/>$/) {
    print "</tip></item>\n";
  } elsif (m/^[\-]{2,}/) {
    print "<item>";
  } elsif (m/^<b>.*<\/b><br\/>/) {
    my $file = $_;
    $file =~ s/^<b>(.*)<\/b><br\/>\n/$1/;
    print "<file>$file</file>";
  } elsif (m/^<b>Context\:.*/) {
    my $context = $_;
    $context =~ s/^<b>Context\:<\/b>[\s]*(.*)<br\/>\n/$1/;
    print "<context>$context</context>";
  } elsif (m/^\(.*\)\s+.*<br\/>\n/) {
    my $rule = $_;
    $rule =~ s/^\(([[A-Z0-9_]+)\)\s.*\n/$1/;
    print "<rule>$rule</rule>";
    my $tip = $_;
    $tip =~ s/^.*<\/font><\/b>(.*)<br\/>\n/$1/;
    print "<tip>$tip";
  } elsif (m/^\s+<br\/>\n/) {
     ;
  } elsif (m/^\s+.*<br\/>\n/) {
    my $line = $_;
    $line =~ s/^\s+(.*)<br\/>\n/$1/;
    print "<br/>$line";
  } else {
    print;
  }
}
