#!/usr/bin/perl
use Tie::File;

my @files = glob "$ARGV[0]";
#my @files = glob "students.php";
#my @files = glob "*.php";
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
my $insVals = 0;
my $queryLine = 0;
my $whereLine = 0;
my @array;
my @varNames;
my @keyNames;
my @vars;

my $count = 1;

foreach $file(@files){
    #my $file = $ARGV[0];
    print "$count Checking $file\n";
    my $jump = 0;
    do {
        clear_globals();
        $jump = do_file($file,$jump);
        print "JUMP $jump\n";
    }while($jump > 0);
}

sub do_file {
    $start = $_[1];

    print "HELLO $start\n";
    print $array[$start];
    #clear_globals();
    tie @array, 'Tie::File', $_[0] or die "Can't open $_[0] $!\n";
    $stop = scalar(@array);
    print "STOP: $stop\n";
    print $array[$stop];

    print "\n";

    #$start = 3780;
    #$stop = 3850;

    for(my $i=$start; $i<$stop; $i++) {
        my $line = $array[$i];
        #print "LINE $line\n";
        #$lineNum = $i + 1;
        if($line =~ /^([ \s\t]*)\/\// && $sql == 0) {
            #print "COMMENTED LINE $i $line\n";

            next;
        }
        if($line =~ /^([ \s\t]*)\$([^ =]+) *= *" *(select|update|insert|delete)[ "]/i && $sql == 0) {
            #if($i< 2300) {
                #print "MATCH $i\n";
                #print "$2 || $3 || $line\n";
            #}

            $spaces = $1;
            $sqlVar = $2;
            $sqlType = lc $3;
            if(length $sqlVar > 0 && length $sqlType > 0) {
                $sql = 1;
            }
            if($sqlType == 'insert') {
                if($line =~ /set/i || $array[$i+1] =~ /set/i) {
                    $sqlType = 'update';
                }
            }
        }
        if($sql == 1 && $inputsDone == 0) {
            #print "SQL 1 Inputs 0 $i $line\n";
            
            if($sqlType =~/^select$/) {
                ($line) = $line =~ s/\\" *(\$.+?) *\\"/$1/gr;
                if($i> 4200) {
                    #print "SQLVAR $i $sqlVar $line\n";
                }
                if($line =~ /$sqlVar *\.?= *"(.+(?:[<>!=]++|LIKE).+) *";/i) {
                    #print "CONDITIONAL $1\n";
                    (@vars) = $1 =~ m/([A-Za-z0-9_]+) *(?:[<>!=]+|LIKE)(?:[ ']*)(\$[A-Za-z0-9_\->%]+)(?:[ ']*) */g;
                    $tmp = join ", ", @vars;
                    for(my $x=0; $x<@vars; $x++) {
                        if($x % 2 == 1) {
                            $line = $line =~ s/\\"//gr;
                            #print "LINE $line\n";
                            #print "VAR: $vars[$x]| COL: $vars[$x-1]|\n";
                            $varCount++;
                            ($varName) = quotemeta $vars[$x];
                            ($keyName) = $vars[$x-1] =~ s/^\$?(.+) */$1_$varCount/r;
                            #$oldKey = $vars[$x-1];
                            #print "VARNAME: $varName| COL: $keyName| $oldKey\n";
                            $line = $line =~ s/([<>!=]++|LIKE)([' ]*+)?$varName([' ]*)/$1 :$keyName /gr;
                            #print "NEWLINE $line\n";
                            $array[$i] = $line;
                            push @keyNames, $keyName;
                            push @varNames, $vars[$x];
                        }
                    }
                }
            }elsif($sqlType =~ /^(update|delete)$/){
                #print "UPDATE \n";
                ($line) = $line =~ s/\\" *(\$.+?) *\\"/$1/gr;
                if($line =~ /$sqlVar *\.?= *"(.+(?:[<>!=]++|LIKE).+) *";/i) {
                    if($i > 4200) {
                        #print "$1\n";
                    }
                    (@vars) = $1 =~ m/([A-Za-z0-9_]+) *(?:[<>!=]++|LIKE)(?:[ ']*)(\$[A-Za-z0-9_\->%]+)(?:[ ']*),? */g;
                    $tmp = join ", ", @vars;
                    if($i < 2200) {
                        #print "$sqlVar Test Vars:$i $tmp\n";
                    }
                    for(my $x=0; $x<@vars; $x++) {
                        if($x % 2 == 1) {
                            $line = $line =~ s/\\"//gr;
                            #print "LINE $line\n";
                            #print "VAR: $vars[$x]| COL: $vars[$x-1]|\n";
                            $varCount++;
                            ($varName) = quotemeta $vars[$x];
                            ($keyName) = $vars[$x-1] =~ s/\$?(.+) *$/$1_$varCount/r;
                            #print "VARNAME: $varName| COL: $keyName| \n";
                            #print "OLDLINE $i $line\n";
                            $line = $line =~ s/([<>!=]++|LIKE)([' ]*+)?$varName([' ]*)/$1 :$keyName /gr;
                            #print "NEWLINE $i $testLine\n";
                            $array[$i] = $line;
                            push @keyNames, $keyName;
                            push @varNames, $vars[$x];
                        }
                    }
                }

            }elsif($sqlType =~ /^insert$/){
                #print "INSERT \n";
                ($line) = $line =~ s/\\" *(\$.+?) *\\"/$1/gr;
                if($line =~ /$sqlVar *\.?= *"(.*)";/i) {
                    ($thisLine) = $1;
                    if($thisLine =~ /values *\(/i) {
                        #print "THIS LINE1: $thisLine\n";
                        ($testLine) = $thisLine =~ m/values(.+)/i;
                        #print "THIS LINE: $testLine\n";
                        (@vars) = $testLine =~ m/(?:[ ']*)(\$[A-Za-z0-9_\->]+)(?:[ ']*),?+ */g;
                        if($i < 2200) {
                            #print "VALUESLINE $line \n";
                            #print "TESTLINE  $testLine \n";
                        }
                        #print "FOUND VALUE(\n";
                        $insVals = 1;
                    }elsif($thisLine =~ /values *\(? *$/i) {
                        #print "FOUND VALUE $i $line\n";
                        $insVals = 1;
                        next;
                    }elsif($insVals == 1) {
                        if($i < 2200) {
                            #print "Searching Values $thisLine\n";
                        }
                        (@vars) = $thisLine =~ m/(?:[ ']*)(\$[A-Za-z0-9_\->]+)(?:[ ']*),?+ */g;
                    }
                    foreach(@vars) {
                        $varCount++;
                        #print "Var: $_\n";
                        ($varName) = quotemeta($_);
                        ($keyName) = $_ =~ s/\$(.+) *$/$1_$varCount/r;
                        $line = $line =~ s/(\$$sqlVar.*?)([' ]*+)?$varName([' ]*)/$1 :$keyName/gr;
                        $array[$i] = $line;
                        push @keyNames, $keyName;
                        push @varNames, $_;
                    }
                    $tmp = join ", ", @vars;
                    if($i < 2200) {
                        #print "$sqlVar Test Vars:$i $tmp\n";
                    }

                }
            }else {
                print "NO IDEA $line\n";
            }
            if($line =~ /(?:\$([^ ]+)?(?: *= *))?mysql_query\( *\$$sqlVar/i) {
                if($i< 2300) {
                    #print "Query Line $i $line\n";
                }
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
                    $inputStr = "$spaces    \"$keyNames[$n]\" => \"$varNames[$n]\"";
                    if($n+1 < $numInputs) {
                        push @inputArray, "$inputStr,";
                    }else{
                        push @inputArray, "$inputStr";
                    }
                }

                push @inputArray, "$spaces);";

                #$tmp = join "\n", @inputArray;
                splice(@array,$i,0,@inputArray);
                $inputsDone = 1;

                #print "$resultsVar\n $i $line\n";
                #print "INPUTStr: $tmp\n";

                ($i)= $i+$numInputs+2;
                ($queryLine) = $i+1;
                $pdoRowVar = "\$pdo_row_$queryLine";
                if($sqlType ne 'select') {
                    print "EXIT NO SEL $i $line\n";
                    last;
                }else{
                    print "INPUTS ENTERED $i $queryLine $line\n";
                    next;
                }
            }
        }elsif($line =~ /\$$resultsVar *= *mysql_query\(/) {
            print "EXIT SAME RS VAR OLD: $queryLine NEW:$i $line\n";
            last;
        }else{
            if($line =~ /mysql_result\( *\$$resultsVar/i) {
                #print "result $resultsVar\n";
                $line = $line =~ s/mysql_result\( *\$$resultsVar *,[^,]+, *(["'][^"']+["']) *\);/$pdoRowVar\[$1\];/r;
                $array[$i] = $line;
                if($fetch == 0) {
                    $fetch = 1;
                    $pdoFetch = "$spaces$pdoRowVar = pdo_fetch_assoc(\$$resultsVar);";
                    splice(@array,$i,0,$pdoFetch);
                    $i++;
                }
            }elsif($line =~ /\$([^ =)]+) *= *mysql_num_rows\( *\$$resultsVar *\);/) {
                #print "ROW $line\n";
                $rowsVar = $1;
                $line = $line =~ s/mysql_num_rows/pdo_num_rows/gir;
                $array[$i] = $line;
            }elsif($line =~ /for\(.*?< *\$$rowsVar.*\) *\{/i && length $rowsVar > 0 && $fetch == 0 && length $pdoRowVar > 0) {
                #print "FOR $i $line\n";
                #print "ROWSVAR $rowsVar\n";
                #print "Query $queryLine\n";
                $fetch = 1;
                #$line = $line =~ s/for\(.*?< *\$$rowsVar.*\) *\{/while(\$$pdoRowVar = pdo_fetch_assoc(\$$resultsVar)) {/r;
                $line = $line =~ s/for\(.*?< *\$$rowsVar.*\) *\{/while($pdoRowVar = pdo_fetch_assoc(\$$resultsVar)) {/r;
                $array[$i] = $line;
            }else{
                $line = $line =~ s/mysql_insert_id/pdo_insert_id/ri;
                $line = $line =~ s/mysql_fetch_assoc(\( *\$$resultsVar *\))/pdo_fetch_assoc$1/ri;
                $array[$i] = $line;
            }
        }
    }
    #print "COLS: ";
    #print join(", ", @keyNames);
    #print "\n";
    #print "VALS: ";
    #print join(", ", @varNames);
    #print "\n";

    untie @array;
    print "LINE: $queryLine \n";
    return $queryLine;
}

sub clear_globals {
    $sqlVar = '';
    $spaces = '';
    $sqlType = '';
    #$resultsVar = '';
    $pdoRowVar = '';
    $sql = 0;
    $fetch = 0;
    $varCount = 0;
    $inputsDone = 0;
    $queryLine = 0;
    $insVals = 0;
    @array = ();
    @varNames = ();
    @keyNames = ();
    @vars = ();
}

     

