#!/usr/bin/perl
#my @files = glob "test.php";
#my @files = glob "*.inc";
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
my $duplicates;
my %funList;
#my $debug = 'debug.qf';
##open (my $dqf, ">", $debug) or die "Can't open $debug $!\n";
##print $dqf '';
#close $dqf;
foreach $file(@files){
    open (FILE, "<$file") or die "Can't open $file: $!\n";
    @lines = <FILE>;
    close FILE;
    #open (my $dqf, ">>", $debug) or die "Can't open $debug $!\n";
    #open (STDOUT, ">>$output") or die "Can't open $output $!\n";
    my $script = 0;
    my $obj = 0;
    my $brackets = 0;
    my $funName = '';
    for my $i (0...$#lines ) {
        $line = $lines[$i];
        my $lineNum = $i + 1;
        if($line =~ /\<script/i) {
            $script = 1;
        }elsif($line =~ /\<\/script/i) {
            $script = 0;
        }
        if($obj == 1) {
            if($line =~ /.*{.*/) {
                $brackets++;
                #print "$lineNum Open: $brackets\n"
            }
            if($line =~ /.*}.*/) {
                $brackets--;
                #print "$lineNum Close: $brackets\n";
            }
        }
        if($line =~ /class\s\w*Obj/i) {
            $obj = 1;
            if($line =~ /.*{.*/) {
                $brackets++;
            }
            #print $dqf "$file:$lineNum:Start Obj "; 
        }elsif($brackets == 0) {
            #print $dqf "$lineNum\n" if $obj == 1; 
            $obj = 0;
        }
        if($script == 1 || $obj == 1) {
            next;
        }

        if($line =~ /^function /) {
            ($funName) = $line =~ m/^function +(\w+) *\(/i;
            $funList{$funName}{$file} .= $lineNum;
        }
    }
    #close $dqf;
}
my $totalFiles = 0;
my $totalFunctions = 0;
my $uniqueFunctions = 0;
my %test;
$qfFile = "duplicates.qf";
$txtFile = "duplicates.txt";
open (my $qf, ">", $qfFile) or die "Can't open $qfFile $!\n";
open (my $txt, ">", $txtFile) or die "Can't open $txtFile $!\n";
foreach my $funName (keys %funList) {
    my $fileCount = scalar(keys $funList{$funName});
    if($fileCount > 1) {
        if(/.*inc$/ ~~ %{ $funList{$funName} }) {
            $uniqueFunctions++;
            $totalFunctions += $fileCount;
            foreach my $file (keys %{ $funList{$funName} }) {
                if($test{$file}++ == 0) {
                    $totalFiles++;
                }
                print $qf "$file:$funList{$funName}{$file}:$funName\n";
            }
            my $funFiles =  join(", ", keys %{ $funList{$funName} });
            print $txt "$funName($fileCount): $funFiles\n";
        }
    }
}
close $qf;
close $txt;
print "Found $uniqueFunctions duplicate PHP functions($totalFunctions total) in $totalFiles files\n";
print "Information stored in $qfFile(vim quickfix) and $txtFile.\n";
