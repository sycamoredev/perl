#!/usr/bin/perl
use Tie::File;
my @files = glob "/usr/local/apache/htdocs/jon/ss/*.php";
#push @files, glob "/usr/local/apache/htdocs/jon/ss/*.inc";
push @files, glob "/usr/local/apache/htdocs/jon/ss/*.tab";
push @files, glob "/usr/local/apache/htdocs/jon/ss/admissions/*.php";
push @files, glob "/usr/local/apache/htdocs/jon/ss/admissions/*.inc";
push @files, glob "/usr/local/apache/htdocs/jon/ss/admissions/*.tab";
push @files, glob "/usr/local/apache/htdocs/jon/ss/Reports/0/*.php";
push @files, glob "/usr/local/apache/htdocs/jon/ss/Reports/0/*.inc";
push @files, glob "/usr/local/apache/htdocs/jon/ss/Reports/0/*.tab";

# Globals
my $sqlVar = '';
my $spaces = '';
my $current = '';
my $sys = 0;
my $sql = 0;
my @array;

my $count = 1;

#my $file = $ARGV[0];
foreach $file(@files){
    print "$count Checking $file\n";
    $sqlVar = '';
    $spaces = '';
    $current = '';
    $sys = 0;
    $sql = 0;
    do_file($file);
}

sub do_file {
    $start = $_[1];

    #print "HELLO $start\n";
    #clear_globals();
    tie @array, 'Tie::File', $_[0] or die "Can't open $_[0] $!\n";

    #print $array[$start];
    #print "\n";

    for(my $i=$start; $i<@array; $i++) {
        my $line = $array[$i];
        if($line =~ /^([ \s\t]*)\/\// && $sql == 0) {

            next;
        }
        if($line =~ /mysql_query/) {
            $sql = 0;
            $sys = 0;
            $current = '';
            $spaces = '';
        }
        if($line =~ /^([ \s\t]*)\$([^ =]+) *= *" *select[ "]/i && $sql == 0) {

            $spaces = $1;
            $sqlVar = $2;
            if(length $sqlVar > 0) {
                $sql = 1;
            }
            $sys = 0;
        }

        if($sql == 1) {
            if($line =~ /.*SchoolYearStudents +(\w+)?/) {
                if(length $1 > 0) {
                    $current = "$1.Current";
                }else{
                    $current = "Current";
                }
                $sys = 1;
            }

            if($line =~ /(where|and).*/i && $sys == 1) {
                print "$i || $line\n";
                ($line) = $line =~ s/^(.*)";/$1 AND $current = 1 ";/gr;
                $array[$i] = $line;
                $sys = 0;
                $current = '';
                next;
            }
        }
    }
            

    untie @array;
}

