#!/usr/bin/perl

my @files;
if ( @ARGV > 1 ) {
    @files = @ARGV;
} elsif(@ARGV == 1) {
    @files = glob "$ARGV[0]";
} else {
    print "Error: no files found\n";
    exit;
}

if(@files < 1) {
    print "Error: no files found\n";
    exit;
}

print scalar @files." files to process.\n";

foreach $file(@files){

    # Set output back to STDOUT(terminal)
    select STDOUT;
    print "Processing $file\n";


    #Open the file and read data
    #Die with grace if it fails
    open (FILE, "<$file") or die "Can't open $file: $!\n";
    @lines = <FILE>;
    close FILE;
    #Open same file for writing, using FF
    open (FF, ">$file") or die "Can't open $file: $!\n";

    # Select current file as output destination
    select FF;
    my $header = 0;
    for ( @lines ) {
        s/(print\(.*?)\\n(?= *\" *\);)/$1/;
        print;
    }
    close FF;
}
