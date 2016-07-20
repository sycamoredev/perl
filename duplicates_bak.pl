#!/usr/bin/perl
#my @files = glob "test.php";
my @files = glob "a*.php";
#push @files, glob "*.ajax.php";
#push @files, glob "*.inc";
#push @files, glob "Reports/0/*.php";
#push @files, glob "Reports/0/*.inc";
#push @files, glob "admissions/*.php";
#push @files, glob "admissions/*.inc";
#for (0..$#files){
      #$files[$_] =~ s/\.txt$//;
  #}
#my @files = glob "$dir
my $duplicates;
my %functions;
my $output = 'duplicates.txt';
#my $pattern = '.*(EntityColumn|SchoolID)';
foreach $file(@files){
    open (FILE, "<$file") or die "Can't open $file: $!\n";
    @lines = <FILE>;
    close FILE;
    open (STDOUT, ">>$output") or die "Can't open $output $!\n";
    #open (STDOUT, ">>$output") or die "Can't open $output $!\n";
    my $script = 0;
    my $schoolid = 0;
    my $where = 0;
    my $and = 0;
    my $function = '';
    for my $i (0...$#lines ) {
        $line = $lines[$i];
        my $lineNum = $i + 1;
        if($line =~ /\<script/i) {
            $script = 1;
        }elsif($line =~ /\<\/script/i) {
            $script = 0;
        }
        if($script == 1) {
            next;
        }

        if($line =~ /^function /) {
            ($function) = $line =~ m/^function +(\w+) *\(/i;
            if(exists($functions{$function})) {
                my %test = map { $_ => 1 } @duplicates;
                if(!exists($test{$function})) { 
                    $test{$function} = 1;
                    @duplicates = keys %test;
                    $fileLine = $functions{$function};
                    print "$fileLine:$function\n";
                }else{
                    $functions{ $function } .= "$file:$lineNum";
                }
                print "$file:$lineNum:$function\n";
            }else{
                $functions{$function} .= "$file:$lineNum";
            }
        }
    }
    close STDOUT;
}
