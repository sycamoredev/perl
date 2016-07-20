#!/usr/bin/perl
my @files = glob "/usr/local/apache/htdocs/jon/ss/*.php";
push @files, glob "/usr/local/apache/htdocs/jon/ss/*.inc";
push @files, glob "/usr/local/apache/htdocs/jon/ss/*.tab";
push @files, glob "/usr/local/apache/htdocs/jon/ss/admissions/*.php";
push @files, glob "/usr/local/apache/htdocs/jon/ss/admissions/*.inc";
push @files, glob "/usr/local/apache/htdocs/jon/ss/admissions/*.tab";
push @files, glob "/usr/local/apache/htdocs/jon/ss/Reports/0/*.php";
push @files, glob "/usr/local/apache/htdocs/jon/ss/Reports/0/*.inc";
push @files, glob "/usr/local/apache/htdocs/jon/ss/Reports/0/*.tab";
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
        s/(^[\s\t]*print\([^(\\n)]*)\\n(\"\);$)/$1$2/;
        print;
    }
#Finish up
    close STDOUT;
}
