#!/usr/bin/perl

my $file = $ARGV[0];

my $type = '';
if(scalar @ARGV == 2) {
    $type = $ARGV[1];
}
if($type eq 'quickfix') {
    $type = 'qfx';
}
     

open my $phpInput, '<', $file or die "can't open $file: $!";
my @incFiles;
while (<$phpInput>) {
    chomp;
    #print "$_\n";
    push @incFiles, $_ =~ m/require_once\(["'] *([A-Za-z\._0-9\/-]+) *["']\)/g;
}
close $phpInput;

my @functions;
my @skipFiles = ('pdo.inc','crumb.inc','tab.inc', 'array.inc', 'alphabetbar.inc', 'simpleimage.inc', 'phone.inc' );
my @skipFunctions = ('formatDateTime', 'Display', 'htmlQuotes');
foreach(@incFiles) {
    if($_ ~~ @skipFiles) {
        next;
    }
    open my $incInput, '<', $_ or die "can't open $_ $!";
    while (<$incInput>) {
        chomp;
        if($_ =~ /function +([A-Za-z_0-9-]+)\b/g) {
            if(!($1 ~~ @functions) && !($1 ~~ @skipFunctions)) {
                push @functions, $1;
            }
        }
    }
    close $incInput;
}

my @foundFunctionsTxt;
my @foundFunctionsQfx;
my $lineNum = 0;
open my $phpInput2, '<', $file or die "can't open $file: $!";
while (<$phpInput2>) {
    chomp;
    ($line) = $_;
    $lineNum++;
    foreach(@functions) {
        #print "$_\n";
        if($line =~ /\b($_) *\(/i) {
            push @foundFunctionsTxt, "$lineNum: $_";
            push @foundFunctionsQfx, "$file:$lineNum:$_";
        }
    }
}
close $phpInput2;

if($type eq 'txt' or $type eq '') {
    open(my $txtInput, '>', "inc_functions.txt") or die "Could not open file 'inc_functions.txt' $!";
    my $foundNamesTxt = join "\n", @foundFunctionsTxt;
    print $txtInput $foundNamesTxt;
    close $txtInput;
}
if($type eq 'qfx' or $type eq '') {
    open(my $qfxInput, '>', "inc_functions.qfx") or die "Could not open file 'inc_funtions.qfx' $!";
    my $foundNamesQfx = join "\n", @foundFunctionsQfx;
    print $qfxInput $foundNamesQfx;
    close $qfxInput;
}
