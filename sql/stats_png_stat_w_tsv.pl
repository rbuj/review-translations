#!/usr/bin/perl -n
foreach $line ( <STDIN> ) {
    chomp( $line );
    $line =~ s/^(\w*@?\w*)\|fuzzy\|(\d+)\s+\w*@?\w*\|obsolete\|\d+\s+\w*@?\w*\|total\|\d+\s\w*@?\w*\|translated\|(\d+)\s\w*@?\w*\|untranslated\|(\d+)/$1 $3 $2 $4/g;
    print "$line\n";
}
