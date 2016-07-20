#!/usr/bin/perl
use Tie::File;
#my @files = glob "perlsqltest.php";
#my @files = glob "$ARGV[0]";
my @files = glob "*.php";
push @files, glob "*.inc";
push @files, glob "Reports/0/*.php";
push @files, glob "Reports/0/*.inc";
push @files, glob "admissions/*.php";
push @files, glob "admissions/*.inc";
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
my $orderLine = undef;
my $sql = 0;
my $sqlLine = 0;
my $schoolid = 0;
my $spaces = 0;
my $where = 0;
my $and = 0;
my $whereStr = '';
my @array;
my $count = 0;
my $continue = 0;
#my $fileStart = index(@files, "$ARGV[0]");
foreach $file(@files){
    if(length $ARGV[0] == 0) {
        $continue = 1;
    }elsif($file eq "$ARGV[0]") {
        $continue = 1; 
        next;
    }
    if($continue == 0) {
        next;
    }
    if($count < 100) {
        my $flag = 0;
        print "$count Checking $file...\n";
        my $jump = 0;
        do {
            $jump = do_file($file, $jump);
            if($jump > 0) {
                $flag = 1;
            }
        }while($jump > 0);
        if($flag == 1) {
            $count++;
        }
    }
}
sub do_file () {
    my $change = 0;

    clear_globals();
    tie @array, 'Tie::File', $_[0] or die "Can't open $_[0] $!\n";

    for my $i ($_[1]...$#array ) {
        $line = $array[$i];
        $lineNum = $i + 1;
        if($line =~ /^[ \s\t]*\$.*(sql|select).*" *select/i) {
            #print "$lineNum SQL\n";
            ($sqlVar) = $line =~ m/^[ \s\t]*(\$.*(sql|select)[^ ]*).*" *select/i;
            ($spaces) = $line =~ m/^([ \s\t]*)\$/i;
            $sql = 1;
            $sqlLine = $lineNum;
        }
        if($line =~ /mysql_query/i) {
            #print "$lineNum $sqlLine QUERY\n";
            if($sql == 1 && $schoolid == 0 && $sqlLine != $whereLine && $sqlLine != $lineNum) {
                fix_sql($sqlVar,$multi,$alias,$whereLine,$spaces,$lineNum, $orderLine);
                $change = $lineNum;
                clear_globals();
                last;
            }
            clear_globals();
        }
        if($sql == 1) {
            #print "$lineNum SQL1\n";
            if($line =~ / *from/i) {
                $fromLine = $lineNum;
                if($line =~ /from .*(,|left join)/i) {
                    $multi = 1;
                }
            }
            if($fromLine > $lineNum && $line =~ /(,|left join)/i) {
                $multi = 1;
            }
            if($line =~ /" *order/i) {
                $orderLine = $lineNum;
            }
            if($line =~ / *where/i) {
                #print "$lineNum WHERE\n";
                $whereLine = $lineNum;
                $where = 1;
            }
            if($where == 1) {
                if($line =~ /$pattern/i) {
                    #print "$lineNum SCHOOLID\n";
                    $schoolid = 1;
                }
            }
            if($multi == 1 && $fromLine > 0 && $whereLine > 0) {
                my $thisLine = $array[$fromLine-1];
                ($alias) = $thisLine =~ m/from *[^ ,]* *([^ ,"]*)/i;
            }


        }
    }
#Finish up
    untie @array;
    return $change;
}
sub fix_sql {
    my $sqlVar = $_[0];
    my $multi = $_[1];
    my $alias = $_[2];
    my $where = $_[3];
    my $spaces = $_[4];
    my $orderLine = $_[5];
    my $current = $_[6];
    my $str = '';
    if($multi == 1) {
        $str = "$alias.\$EntityColumn";
    }else{
        $str = "\$EntityColumn";
    }
    if($where > 0) {
        $spliceLoc = $where;
        $str = "AND $str";
    }elsif($orderLine > 0) {
        $spliceLoc = $orderLine - 1;
        $str = "WHERE $str";
    }else{
        $spliceLoc = $current - 1;
        $str = "WHERE $str";
    }
    my $comment = "$spaces//SQL_PATCH";
    my $sqlPattern = "$spaces$sqlVar .= \" $str = \$EntityValue \";"; 
    my $globalDec = $spaces.$globals;
    splice(@array,$spliceLoc,0,$comment,$globalDec,$sqlPattern);
}

sub clear_globals {
    $fromLine = 0;
    $sqlVar = '';
    $multi = 0;
    $alias = '';
    $whereLine = undef;
    $orderLine = undef;
    $sql = 0;
    $sqlLine = 0;
    $schoolid = 0;
    $where = 0;
    $and = 0;
    $spaces = 0;
    $whereStr = '';
}
