#!/usr/bin/perl
use Tie::File;

my $start_run = time();

my @files;

# if multiple args, assume list of files
if ( @ARGV > 1 ) {
    @files = @ARGV;
# if one arg, assume filename/pattern, e.g. "students.php" or "s*.php"
} elsif(@ARGV == 1) {
    @files = glob "$ARGV[0]";
} else {
    print "Error: no files found\n";
    exit;
}

if(@files < 1) {
    print "Error: no files found\n";
    exit;
}

# Initialize globals
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
my $sqlLine = 0;
my @array;
my @varNames;
my @keyNames;
my @vars;

# skip specific files
my @skipFiles = qw(session_mysql.inc login.inc logout.php login.php);
my %h;

# Initialise the hash using a slice
@h{@skipFiles} = undef;

print "@files";

# rewrite @files with @skipFiles removed
@files = grep {not exists $h{$_}} @files;

print "\n";
print "@files";

# operators
my $ops = "[<>!=]{1,2}|LIKE";

# start converting file at line X
my $jump = 0;
#$jump = 3690;

my $count = 0;

# force perl to flush the STDOUT(standard output) buffer
$| = 1;
foreach $file(@files){
    if(@files > 1) {
        print ++$count."/".@files." ";
    }
    print "Converting $file...";
    do {
        clear_globals();
        # $jump is returned when a query has been found and modified
        # if $jump == 0, no queries were found to convert, so the process is complete
        $jump = do_file($file,$jump);
    }while($jump > 0);
    print "Done\n";
}
$| = 0;
# return buffering to it's normal state

$end_run = time();
$run_time = $end_run - $start_run;
print "Job took $run_time seconds\n";
my $line = '';

sub do_file {
    $start = $_[1];

    #print "Start line: $start\n";
    #print $array[$start];

    # read lines of file into array, modifying array modifies file
    tie @array, 'Tie::File', $_[0] or die "Can't open $_[0] $!\n";
    $stop = @array;
    #print "STOP: $stop\n";
    #print $array[$stop];

    #print "\n";

    # $stop can be set manually for debugging
    # To adjust the $start var, adjust the default value for $jump instead
    #$stop = 4055;

    for(my $i=$start; $i<$stop; $i++) {
        $line = $array[$i];
        $lineNum = $i + 1;

        #skip commented lines
        $line =~ /^([ \s\t]*)(\/\/|\/\*)/ and next;

        $line = $line =~ s/mysql_real_escape_string\( *(\$[^ ]+) *\)/$1/ri;


        # find start of SQL statement
        # Example: $sql =  "SELECT ....
        if($line =~ /^([ \s\t]*+)\$([^ =]+) *= *['"] *(select|update|insert|delete)[ "']/i && $sql == 0) {


            # record indentation
            $spaces = $1;

            # save sql variable(usually "sql")
            $sqlVar = $2;

            # sql type(select, update, etc) cast as lowercase
            $sqlType = lc $3;


            if(length $sqlVar > 0 && length $sqlType > 0) {
                # set flags
                $sql = 1;
                $sqlLine = $i;
            }

            # if type is insert, but uses 'set' syntax like update, treat as update
            if($sqlType == 'insert') {
                if($line =~ /set/i || $array[$i+1] =~ /set/i) {
                    $sqlType = 'update';
                }
            }
        }


        # if sql statement as been found and pdo $inputs array hasn't been created
        if($sql == 1 && $inputsDone == 0) {
            # Queries broken into if/else statements that use the same 'mysql_query()'
            # call can cause problems for queries later in the file, this is to help prevent that
            if($line =~ /^([ \s\t]*+)\$([^ =]+) *\.= *".+:.+_\d/i) {
                $sqlLine = $i;
                last;
            }

            # remove escaped quotes
            $line = $line =~ s/\\"//gr;
            if($sqlType =~ /^(update|delete|select)$/){
                # matches lines that contain the sql variable and at least 
                # one operator(<>=!|LIKE).                 #
                # Examples:
                # $sql .= "Column = $val ";
                # $sql .= "ColA = '$val1' AND ColB != $val2 ";
                if($line =~ /$sqlVar *\.?= *"(.+(?:$ops).+) *";/i) {
                    # Capture group will be stored in $1 automatically.
                    # Examples:
                    # Column = $val
                    # ColA = '$val1' AND ColB != $val2

                    # Store matches for columns and variable values in array
                    # Examples:
                    # [Column, val]
                    # [ColA, val1, ColB, val2]
                    @vars = $1 =~ m/([A-z0-9_]+) *(?:$ops)(?:[ ']*+)(%?\{? *?\$[A-z0-9_\$\->'\[\]]+ *?%?\}?)(?:[ ']*)/g;

                    # loop through array
                    for(my $x=0; $x<@vars; $x++) {
                        # skip column elements(indicies 0,2,4,6...)
                        if($x % 2 == 1) {
                            # use $varCount to guarantee unique keys
                            $varCount++;

                            # remove leading/trailing apotrophes
                            $vars[$x] = $vars[$x] =~ s/^[ ']*|[ ']*$//gr;
                            # escape all non-word characters(alphanumeric + underscore)
                            $varName = quotemeta($vars[$x]);
                            # store "<column name>_$varCount" as $keyName
                            $keyName = $vars[$x-1] =~ s/\$?(.+) *$/$1_$varCount/r;

                            # replace non-word characters with underscores(for pdo compliance)
                            $keyName = $keyName =~ s/[^A-z0-9_]/_/gr;

                            # rewrite line in pdo format
                            # Example: $sql .= "ColA = :ColA_1 AND ColB != :ColB_2 ";
                            $line = $line =~ s/($vars[$x-1] *$ops) *'?$varName *'?(,)? */$1 :$keyName$2 /gr;
                            # handle vars that are concatenated into the SQL string
                            $line = $line =~ s/" *\. *:$keyName *\. *"/".":$keyName"."/gr;
                            $array[$i] = $line;

                            # append key and vars to respective arrays
                            push @keyNames, $keyName;
                            push @varNames, $vars[$x];
                        }
                    }
                }

            }elsif($sqlType =~ /^insert$/){
                # trim line to only capture inside quotation marks
                if($line =~ /$sqlVar *\.?= *"(.*)";/i) {
                    # save match in $thisLine
                    $thisLine = $1;

                    # if line contains 'values' keyword plus parenthesis, find variables
                    # Example:
                    # $sql .= " )VALUES( $var1, '$var2', 0, 'yes', $var3, ";
                    if($thisLine =~ /values *\(/i) {
                        # match variables, exclude apostrophes
                        # Above example matches:
                        # var1  
                        # var2  
                        # var3  
                        @vars = $thisLine =~ m/(?:[ ']*)(\{?\$[A-z0-9_\$\->'\[\]]+\}?)(?:[ ']*),?+ */g;
                        # set flag so we know we're in the 'values' section of query
                        $insVals = 1;
                    # sometimes values is alone on a line
                    # $sql .= "VALUES";
                    # $sql .= "($var1, $var2...
                    # set 'values' flag and skip to next line
                    }elsif($thisLine =~ /values *\(? *$/i) {
                        $insVals = 1;
                        next;
                    # if already in 'values' section, match vars
                    }elsif($insVals == 1) {
                        @vars = $thisLine =~ m/(?:[ ']*)(\{?\$[A-z0-9_\$\->'\[\]]+\}?)(?:[ ']*),?+ */g;
                    }
                    # loop through vars
                    foreach(@vars) {
                        # use $varCount to guarantee unique keys
                        $varCount++;
                        # remove leading/trailing apotrophes
                        $var = $_ =~ s/^[ ']*|[ ']*$//gr;
                        # escape all non-word characters(alphanumeric + underscore)
                        $varName = quotemeta($var);
                        # replace non-word characters with underscores(for pdo compliance)
                        # brackets don't play nice, so they get their own category
                        $keyName = $var =~ s/(\[|\]|[^A-z0-9])+/_/gr;
                        # trim leading/trailing underscores
                        $keyName = $keyName =~ s/(^_*|_*$)//gr;
                        # append $varCount to guarantee unique key
                        $keyName = $keyName."_$varCount";
                        # rewrite line in pdo format
                        # $sql .= " )VALUES( $varA, '$varB', 0, 'yes', $varC, $obj->prop ";
                        # becomes
                        # $sql .= " )VALUES( :varA_1, :varB_2, 0, 'yes', :varC_3, :obj__prop ";
                        $line = $line =~ s/(\$$sqlVar.*?)([' ]*+)?$varName([' ]*)/$1 :$keyName/gr;
                        # handle vars that are concatenated into the SQL string
                        $line = $line =~ s/" *\. *:$keyName *\. *"/".":$keyName"."/gr;
                        $array[$i] = $line;
                        # append key and vars to respective arrays
                        push @keyNames, $keyName;
                        push @varNames, $var;
                    }

                }
            }
            # if line contains mysql_query with our current $sqlVar
            if($line =~ /(?:\$([^ ]+)(?: *= *))?mysql_query\( *\$$sqlVar *\)/i) {
                # capture results var
                # Example:
                # $rs = mysql_query($sql);
                # $resultsVar now contains 'rs'
                if(length $1 > 0) {
                    $resultsVar = $1;
                }

                # prepend escaped dollar sign for regex
                $searchSql = "\\\$$sqlVar";

                # retrieve number of variables found in previous block
                my $numInputs = scalar @varNames;

                # build name for inputs array
                # $pdo_inputs_<line number of pdo_query>
                $inputsName = '$pdo_inputs_'.($lineNum+2+$numInputs);
                # replace mysql_query with pdo_query plus pdo inputs variable
                $line = $line =~ s/mysql_query\( *$searchSql *\)/pdo_query(\$$sqlVar, $inputsName)/r;
                $array[$i] = $line;

                my $inputStr;
                my @inputArray;
                # build inputs array
                push @inputArray, "$spaces$inputsName = array(";
                for(my $n=0; $n<$numInputs; $n++) {
                    $inputStr = "$spaces    \"$keyNames[$n]\" => \"$varNames[$n]\"";
                    # don't include comma on the last item
                    if($n+1 < $numInputs) {
                        $inputStr = "$inputStr,";
                    }
                    push @inputArray, "$inputStr";
                }


                # close array
                push @inputArray, "$spaces);";

                # splice inputs array into main file
                splice(@array,$i,0,@inputArray);
                # inputs flag
                $inputsDone = 1;

                # advance $i to account for the added lines
                $i += @inputArray;
                $queryLine = $i + 1;
                $pdoRowVar = "\$pdo_row_$queryLine";
                # if not a 'select' statement, end iteration and return to 'while' loop
                if($sqlType ne 'select') {
                    last;
                }else{
                    next;
                }
            }
        # if input array has already been constructed and we
        # find a mysql_query line with the same results variable
        # we can assume we've completed everything for the current
        # sql statement and move on to the next
        }elsif($line =~ /\$$resultsVar *= *mysql_query\(/) {
            last;
        }else{
            # match mysql_result lines for current results variable
            # Example:
            # $val = mysql_result($rs, $i, 'Value');
            if($line =~ /mysql_result\( *\$$resultsVar *,/i) {
                # convert mysql_result lines to $pdo_row_<queryline>['...'] syntax
                # Example:
                # $val = pdo_row_156['Value'];
                $line = $line =~ s/mysql_result\( *\$$resultsVar *,[^,]+, *(["'][^"']+["']) *\)/$pdoRowVar\[$1\]/r;
                # NOTE: Column names in SQL are case-insensitive, meaning
                # "SELECT Lastname" would match a column named "LASTNAME" in the database
                # Similarly, $lname = mysql_result($rs, $i, "lastname"); would match that 
                # same column in the result set.
                # Our PDO results come back in the form of an associative array, which
                # means the selected column must match the key exactly.
                # "SELECT Lastname" will only work with $pdo_row['Lastname'];
                # This difference will cause problems in places where the selected column differs
                # from the name used in the call to mysql_result

                $array[$i] = $line;

                # if no 'pdo_fetch_assoc()' line has been created for this query
                # This will be the case for single result queries, i.e. those without
                # a for loop.
                if($fetch == 0 && $pdoRowVar) {
                    $fetch = 1;
                    $pdoFetch = "$spaces$pdoRowVar = pdo_fetch_assoc(\$$resultsVar);";
                    splice(@array,$queryLine,0,$pdoFetch);
                    $i++;
                }
            # if mysql_num_rows function is found for current $resultsVar
            # Example:
            # $rsc = mysql_num_rows($rs);
            }elsif($line =~ /\$([^ =)]+) *= *mysql_num_rows\( *\$$resultsVar *\)/) {
                # match "rsc" from example
                $rowsVar = $1;

                # replace mysql_num_rows with pdo_num_rows
                $line = $line =~ s/\$$rowsVar *= *mysql_num_rows\( *\$$resultsVar *\)/\$$rowsVar = pdo_num_rows(\$$resultsVar)/gir;

                # Remove "if($resultsVar)" if current and next line do not contain 'else'
                # Example:
                # if($rs) $rsc = pdo_num_rows($rs);
                # $rsc = pdo_num_rows($rs);
                # No Match: if($rs) $rsc = pdo_num_rows($rs); else $msg = 'No Records';
                if($line !~ /else/gi && $array[$i+1] !~ /else/gi) {
                    $line = $line =~ s/if\( *\$$resultsVar *\) *(\$$rowsVar *= *pdo_num_rows\(\$$resultsVar\);)/$1/gir;
                }
                $array[$i] = $line;
            # match for loop over current row variable
            # Example: 
            # for($i=0; $i < $rsc; $i++) {
            # Also make sure $rowsVar and $pdoRowVar are populated, and
            # a pdo_fetch_assoc line has not been added yet
            }elsif($line =~ /for\(.*?< *\$$rowsVar.*\) *\{/i && length $rowsVar > 0 && $fetch == 0 && length $pdoRowVar > 0 && length $resultsVar > 0) {
                $fetch = 1;
                # convert 'for' loop to while loop
                # Example:
                # for($i=0; $i < $rsc; $i++) {
                # while($pdo_row_265 = pdo_fetch_assoc($rs)) {
                $line = $line =~ s/for\(.*?< *\$$rowsVar.*\) *\{/while($pdoRowVar = pdo_fetch_assoc(\$$resultsVar)) {/r;
                $array[$i] = $line;
            }else{
                # convert mysql functions to pdo
                $line = $line =~ s/mysql_insert_id/pdo_insert_id/ri;
                $line = $line =~ s/mysql_error/pdo_error/ri;
                $line = $line =~ s/mysql_fetch_array/pdo_fetch_assoc/ri;
                # This handles num_rows functions that are not assigned to a value
                # Example:
                # if(mysql_num_rows($rs) {
                # if(pdo_num_rows($rs) {
                $line = $line =~ s/^([^=]+)mysql_num_rows/$1pdo_num_rows/ri;
                $line = $line =~ s/mysql_fetch_assoc(\( *\$$resultsVar *\))/pdo_fetch_assoc$1/ri;
                $array[$i] = $line;
            }
        }
    }

    # untie array(close the file)
    untie @array;

    # direct next iteration of the while loop where to start in the file
    # This should be one line after select/update/delete/insert was found
    $sqlLine = $sqlLine == 0 ? $sqlLine : $sqlLine + 2;
    return $sqlLine;
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
    $sqlLine = 0;
    $insVals = 0;
    @array = ();
    @varNames = ();
    @keyNames = ();
    @vars = ();
}
