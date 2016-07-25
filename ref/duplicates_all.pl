#!/usr/bin/perl
#my @files = glob "test.php";
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
#my $pattern = '.*(EntityColumn|SchoolID)';
foreach $file(@files){
    open (FILE, "<$file") or die "Can't open $file: $!\n";
    @lines = <FILE>;
    close FILE;
    #open (STDOUT, ">>$output") or die "Can't open $output $!\n";
    my $script = 0;
    my $schoolid = 0;
    my $where = 0;
    my $and = 0;
    my $funName = '';
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
            ($funName) = $line =~ m/^function +(\w+) *\(/i;
            $funList{$funName}{$file} .= $lineNum;
        }
    }
}
my $totalFiles = 0;
my $totalFunctions = 0;
my $uniqueFunctions = 0;
my %test;
$qfFile = "duplicates_all.qf";
$txtFile = "duplicates_all.txt";
open (my $qf, ">", $qfFile) or die "Can't open $qfFile $!\n";
open (my $txt, ">", $txtFile) or die "Can't open $txtFile $!\n";
foreach my $funName (keys %funList) {
    my $fileCount = scalar(keys $funList{$funName});
    if($fileCount > 1) {
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
close $qf;
close $txt;
print "Found $uniqueFunctions duplicate PHP functions($totalFunctions total) in $totalFiles files\n";
print "Information stored in $qfFile(vim quickfix) and $txtFile.\n";
