#!/usr/bin/perl
my @files = glob "/usr/local/apache/htdocs/jon/ss/*.php";
#push @files, glob "/usr/local/apache/htdocs/jon/ss/*.inc";
##push @files, glob "/usr/local/apache/htdocs/jon/ss/*.tab";
#push @files, glob "/usr/local/apache/htdocs/jon/ss/admissions/*.php";
#push @files, glob "/usr/local/apache/htdocs/jon/ss/admissions/*.inc";
##push @files, glob "/usr/local/apache/htdocs/jon/ss/admissions/*.tab";
#push @files, glob "/usr/local/apache/htdocs/jon/ss/Reports/0/*.php";
#push @files, glob "/usr/local/apache/htdocs/jon/ss/Reports/0/*.inc";
#push @files, glob "/usr/local/apache/htdocs/jon/ss/Reports/0/*.tab";

my $total = 0;
foreach $file(@files){
    my $lines = 0;
    #print "Checking $file\n";
    open(FH, $file) or die "Could not open $!";
    #while(<FH>) {$lines++ if !/^\s+?$/;}
    #$total = $total + $lines;
    while(<FH>) {}
    $total = $total + $.;
    close FH;
}
print "Total lines: $total\n";
print "Total files: ".scalar(@files)."\n";
print "Average: ".(sprintf "%.2f", ($total/scalar(@files)))."\n";
