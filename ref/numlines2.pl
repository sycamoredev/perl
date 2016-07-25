#!/usr/bin/perl
my @files = glob "/usr/local/apache/htdocs/jon/ss/*.php";
push @files, glob "/usr/local/apache/htdocs/jon/ss/*.inc";
#push @files, glob "/usr/local/apache/htdocs/jon/ss/*.tab";
push @files, glob "/usr/local/apache/htdocs/jon/ss/admissions/*.php";
push @files, glob "/usr/local/apache/htdocs/jon/ss/admissions/*.inc";
#push @files, glob "/usr/local/apache/htdocs/jon/ss/admissions/*.tab";
push @files, glob "/usr/local/apache/htdocs/jon/ss/Reports/0/*.php";
push @files, glob "/usr/local/apache/htdocs/jon/ss/Reports/0/*.inc";
#push @files, glob "/usr/local/apache/htdocs/jon/ss/Reports/0/*.tab";

my @total;
my $max = 0;
my @lowfiles;
foreach $file(@files){
    my $lines = 0;
    #print "Checking $file\n";
    open(FH, $file) or die "Could not open $!";
    #while(<FH>) {$lines++ if !/^\s+?$/;}
    #$total = $total + $lines;
    while(<FH>) {}
    push @total, $. if $. > 100;
    $max = $. if $. > $max;
    #push @lowfiles, $file if $. < 300;
    close FH;
}
print "Pre-sort:".scalar(@total)."\n    ";
print "First: $total[0]\n    Last: $total[$#total]\n";
@total = sort {$a <=> $b} @total;
print "Post-sort:".scalar(@total)."\n    ";
print "First: $total[0]\n    Last: $total[$#total]\n";
#@total = @total[300 .. $#total - 300];
#print "Post-slice:".scalar(@total)."\n    ";
#print "First: $total[0] Last: $total[$#total]\n";
my $total_lines = eval join '+', @total;
print "Total lines: $total_lines\n";
print "Total files: ".scalar(@total)."\n";
print "Average: ".(sprintf "%.2f", ($total_lines/scalar(@total)))."\n";
