#!/usr/bin/perl
#my @files = glob "/usr/local/apache/htdocs/jon/ss/classhome.php";
my @files = glob "/usr/local/apache/htdocs/jon/ss/Reports/0/lunchlabels.php";
#push @files, glob "/usr/local/apache/htdocs/jon/ss/Reports/0/*.php";
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
        for ( @lines ) {       
            if($_ =~ /header_open/) {      
                $header = 1;       
            }      
            if($header == 1) {     
                s/^([\t\s\/]*)([.*\<[aA].*])?.*window\.open\(([^,]+,[^,]+),.*width=([0-9]+).*height=([0-9]+).*(\).*)/$1$2popwin\($4,$5,$3$6/;      
                s/if\(\!.*\.opener\)[\s\n\r]*.*\.opener\s*=\s*self//;      
            }      
            print;     
        }
#Finish up
    close STDOUT;
}
