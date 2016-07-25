#!/usr/bin/perl
my @files = glob "/usr/local/apache/htdocs/jon/ss/*.php";
push @files, glob "/usr/local/apache/htdocs/jon/ss/*.inc";
push @files, glob "/usr/local/apache/htdocs/jon/ss/admissions/*.php";
push @files, glob "/usr/local/apache/htdocs/jon/ss/admissions/*.inc";
push @files, glob "/usr/local/apache/htdocs/jon/ss/Reports/0/*.php";
push @files, glob "/usr/local/apache/htdocs/jon/ss/Reports/0/*.inc";
#for (0..$#files){
      #$files[$_] =~ s/\.txt$//;
  #}
#my @files = glob "$dir
foreach $file(@files){


#Open the file and read data
#Die with grace if it fails
    open (FILE, "<$file") or die "Can't open $file: $!\n";
    @lines = <FILE>;
    close FILE;
#Open same file for writing, reusing STDOUT
    open (STDOUT, ">$file") or die "Can't open $file: $!\n";

    my $header = 0;
    for ( @lines ) {
        if($_ =~ /header_open/) {
            $header = 1;
        }
        if($header == 1) {
            s/(<A[^\>]*)href=(["'])\s*\2\s(.*onClick[^;]*;)(?:return\sfalse;)/$1$3/i
        }
        print;
    }
#Finish up
    close STDOUT;
}
