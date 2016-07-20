#!/usr/bin/perl
use Tie::File;
use feature qw(switch);

my @files = glob "students.php";
#push @files, glob "*.inc";
#push @files, glob "Reports/0/*.php";
#push @files, glob "Reports/0/*.inc";
#push @files, glob "admissions/*.php";
#push @files, glob "admissions/*.inc";

# Globals
my $sqlVar = '';
my $spaces = '';
my $sqlType = '';
my $resultsVar = '';
my $pdoRowVar = '';
my $sql = 0;
my $fetch = 0;
my $varCount = 0;
my $inputsDone = 0;
my $queryLine = 0;
my @array;
my @varNames;
my @colNames;
my @vars;

my $count = 1;

#my $file = 'userstatistics.php';
foreach $file(@files){
    print "$count Checking $file";
    my $jump = 0;
    do {
        clear_globals();
        $jump = do_file($file,$jump);
        print "JUMP $jump\n";
    }while($jump > 0);
}

sub do_file {
    $start = $_[1];
    #$start = 1500;
    #$stop = 1535;

    #print "HELLO $_[0]\n";
    #clear_globals();
    tie @array, 'Tie::File', $_[0] or die "Can't open $_[0] $!\n";
    $stop = scalar @array;

    print $array[$start];
    #print "\n";

    for(my $i=$start; $i<$stop; $i++) {
        my $line = $array[$i];
        #print "LINE $line\n";
        #$lineNum = $i + 1;
        if($line =~ /^([ \s\t]*)\$([^ =]+) *= *" *(select|update|insert|delete)[ "]/i && $sql == 0) {
            print "MATCH\n";
            print length $1;
            print "\n$2\n$3\n";

            $spaces = $1;
            $sqlVar = $2;
            $sqlType = lc $3;
            if(length $sqlVar > 0 && length $sqlVar > 0) {
                $sql = 1;
            }
        }
        if($sql == 1 && $inputsDone == 0) {
            
            given($sqlType) {
                when('select') {
                    ($line) = $line =~ s/\\" *(\$.+?) *\\"/$1/gr;
                    if($line =~ /$sqlVar *\.?= *"(.+[<>!=]+.+) *";$/i) {
                        (@vars) = $1 =~ m/([A-Za-z0-9_\-]+) *[<>!=]+(?:[ ']*)(\$[A-Za-z0-9_\-]+)(?:[ ']*),? */g;
                        for(my $x=0; $x<@vars; $x++) {
                            if($x % 2 == 1) {
                                $line = $line =~ s/\\"//gr;
                                print "LINE $line\n";
                                print "VAR: $vars[$x]| COL: $vars[$x-1]|\n";
                                $varCount++;
                                ($varName) = quotemeta $vars[$x];
                                ($colName) = $vars[$x-1] =~ s/^.*?\$?(.++) *$/$1_$varCount/r;
                                print "VARNAME: $varName| COL: $colName| \n";
                                $line = $line =~ s/([' ]*+)?$varName([' ]*)/ :$colName /gr;
                                #print "NEWLINE $line\n";
                                $array[$i] = $line;
                                push @colNames, $colName;
                                push @varNames, $vars[$x];
                            }
                        }
                    }
                }when('update'){
                    #print "UPDATE \n";
                    ($line) = $line =~ s/\\" *(\$.+?) *\\"/$1/gr;
                    if($line =~ /$sqlVar *\.?= *"(.+=.+) *";$/i) {
                        (@vars) = $1 =~ m/([A-Za-z0-9_\-]+) *=(?:[ ']*)(\$[A-Za-z0-9_\-]+)(?:[ ']*),? */g;
                        for(my $x=0; $x<@vars; $x++) {
                            if($x % 2 == 1) {
                                $line = $line =~ s/\\"//gr;
                                print "LINE $line\n";
                                print "VAR: $vars[$x]| COL: $vars[$x-1]|\n";
                                $varCount++;
                                ($varName) = quotemeta $vars[$x];
                                ($colName) = $vars[$x-1] =~ s/\$?(.+) *$/$1_$varCount/r;
                                print "VARNAME: $varName| COL: $colName| \n";
                                $line = $line =~ s/([' ]*+)?$varName([' ]*)/ :$colName /gr;
                                #print "NEWLINE $line\n";
                                $array[$i] = $line;
                                push @colNames, $colName;
                                push @varNames, $vars[$x];
                            }
                        }
                    }

                }when('insert'){
                    print "INSERT \n";
                }when('delete'){
                    print "DELETE \n";
                }default {
                    print "NO IDEA\n";
                }
            }
            if($line =~ /\$([^ ]+)?(?: *= *)?mysql_query\( *\$$sqlVar/i) {
                #print "$line\n";
                ($resultsVar) = $1;
                $searchSql = "\\\$$sqlVar";
                my ($numInputs) = scalar @varNames;
                $inputsName = '$pdo_inputs_'.($i+3+$numInputs);
                $line = $line =~ s/mysql_query\( *$searchSql *\)/pdo_query(\$$sqlVar,$inputsName)/r;
                $array[$i] = $line;



                my $inputStr;
                my @inputArray;
                push @inputArray, "$spaces$inputsName = Array(";
                for(my $n=0; $n<$numInputs; $n++) {
                    $inputStr = "$spaces    \"$colNames[$n]\" => \"$varNames[$n]\"";
                    if($n+1 < $numInputs) {
                        push @inputArray, "$inputStr,";
                    }else{
                        push @inputArray, "$inputStr";
                    }
                }
                push @inputArray, "$spaces);";



                $tmp = join "\n", @inputArray;
                splice(@array,$i,0,@inputArray);
                $inputsDone = 1;

                #print "$resultsVar\n $i $line\n";
                print "INPUTStr: $tmp\n";

                ($i)= $i+$numInputs+2;
                ($queryLine) = $i+1;
                $pdoRowVar = "\$pdo_row_$resultsVar"."_$queryLine";
                if($sqlType ne 'select') {
                    print "EXIT $i $line\n";
                    last;
                }else{
                    next;
                }
            }
        }elsif($line =~ /\$$resultsVar *= *mysql_query\(/) {
            print "EXIT ".$i." $line\n";
            last;
        }else{
            if($line =~ /mysql_result\( *\$$resultsVar/i) {
                $line = $line =~ s/mysql_result\( *\$$resultsVar *,[^,]+, *(["'][^"']+["']) *\);/$pdoRowVar\[$1\];/r;
                $array[$i] = $line;
                if($fetch == 0) {
                    $fetch = 1;
                    $pdoFetch = "$spaces$pdoRowVar = pdo_fetch_assoc(\$$resultsVar);";
                    splice(@array,$i,0,$pdoFetch);
                    $i++;
                }
            }elsif($line =~ /\$([^ =]+) *= *mysql_num_rows\( *\$$resultsVar *\);/) {
                #print "ROW $line\n";
                $rowsVar = $1;
            }elsif($line =~ /for\(.*?< *\$$rowsVar.*\) *\{/i) {
                #print "FOR $line\n";
                $fetch = 1;
                #$line = $line =~ s/for\(.*?< *\$$rowsVar.*\) *\{/while(\$$pdoRowVar = pdo_fetch_assoc(\$$resultsVar)) {/r;
                $line = $line =~ s/for\(.*?< *\$$rowsVar.*\) *\{/while($pdoRowVar = pdo_fetch_assoc(\$$resultsVar)) {/r;
                $array[$i] = $line;
            }
        }
    }
    #print "COLS: ";
    #print join(", ", @colNames);
    #print "\n";
    #print "VALS: ";
    #print join(", ", @varNames);
    #print "\n";

    untie @array;
    #print "LINE: $queryLine \n";
    return $queryLine;
}

sub clear_globals {
    $sqlVar = '';
    $spaces = '';
    $sqlType = '';
    $resultsVar = '';
    $pdoRowVar = '';
    $sql = 0;
    $fetch = 0;
    $varCount = 0;
    $inputsDone = 0;
    $queryLine = 0;
    @array = ();
    @varNames = ();
    @colNames = ();
    @vars = ();
}

     

