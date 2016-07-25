#!/usr/bin/perl
use Tie::File;
#my @files = glob "perlsqltest.php";
my @files = glob "acctinv.inc";
##push @files, glob "Reports/0/*.php";
#push @files, glob "Reports/0/*.inc";
##push @files, glob "admissions/*.php";
#push @files, glob "admissions/*.inc";
#for (0..$#files){
      #$files[$_] =~ s/\.txt$//;
  #}
#my @files = glob "$dir
my $pattern = '.*(EntityColumn|SchoolID)';
my $globals = "Global \$EntityColumn, \$EntityValue;";
my $fromLine = 0;
my $sqlVar = '';
my $multi = 0;
my $alias = '';
my $whereLine = undef;
my $sql = 0;
my $schoolid = 0;
my $where = 0;
my $and = 0;
my $whereStr = '';
my @array;
foreach $file(@files){
    print "Checking $file...\n";
    do_file($file);
}
sub do_file () {
    my $change = 0;

    clear_globals();
    tie @array, 'Tie::File', $_[0] or die "Can't open $_[0] $!\n";

    for (@array) {
        $line = $_;
        $lineNum = $index + 1;
        if($line =~ /\$.*(sql|select).*" *select/i) {
            print "$lineNum SQL 1\n";
            ($sqlVar) = $line =~ m/(\$.*(sql|select)[^ ]*).*" *select/i;
            $sql = 1;
        }
        if($line =~ /mysql_query/i) {
            if($sql == 1 && $schoolid == 0) {
                print("Schoolid 0 SQL 1\n");
                if($whereLine == 0) {
                    $whereLine = $index;
                }
                fix_sql($sqlVar,$multi,$alias,$whereLine);
                $change = $lineNum;
                clear_globals();
            }
            clear_globals();
        }
        if($sql == 1) {
            if($line =~ /" *from/i) {
                $fromLine = $lineNum;
            }
            if($fromLine > 0 && $line =~ /(,|left join)/i) {
                $multi = 1;
            }
            if($line =~ /" *order/i) {
                $where = 0;
                if($whereLine == 0) {
                    $whereLine = $lineNum-1;
                }
            }
            if($line =~ /" *where/i) {
                $whereLine = $lineNum;
                $where = 1;
            }
            if($where == 1) {
                if($line =~ /$pattern/i) {
                    print "Schoolid 1\n";
                    $schoolid = 1;
                }
            }
            if($multi == 1 && $fromLine > 0 && $whereLine > 0) {
                my $thisLine = $array[$fromLine-1];
                ($alias) = $thisLine =~ m/from *[^ ,]* *([^ ,"]*)/i;
            }


        }
    }
    $index = $index + 1;
#Finish up
    untie @array;
}
sub fix_sql {
    my $sqlVar = $_[0];
    my $multi = $_[1];
    my $alias = $_[2];
    my $where = $_[3];
    my $str = '';
    if($multi == 1) {
        $str = "$alias.\$EntityColumn";
    }else{
        $str = "\$EntityColumn";
    }
    my $sqlPattern = "$sqlVar .= \" AND $str = \$EntityValue \";"; 
    splice(@array,$where,0,$globals,$sqlPattern);
}

sub clear_globals {
    $fromLine = 0;
    $sqlVar = '';
    $multi = 0;
    $alias = '';
    $whereLine = undef;
    $sql = 0;
    $schoolid = 0;
    $where = 0;
    $and = 0;
    $whereStr = '';
}
