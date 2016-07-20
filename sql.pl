#!/usr/bin/perl
#my @files = glob "/usr/local/apache/htdocs/jon/ss/classhome.php";
#my @files = glob "/usr/local/apache/htdocs/jon/ss/*.php";
#my @files = glob "*.php";
push @files, glob "*.inc";
#push @files, glob "Reports/0/*.php";
push @files, glob "Reports/0/*.inc";
#push @files, glob "admissions/*.php";
push @files, glob "admissions/*.inc";
#for (0..$#files){
      #$files[$_] =~ s/\.txt$//;
  #}
#my @files = glob "$dir
my $output = 'perlsqlverbose.txt';
my $pattern = '.*(EntityColumn|SchoolID)';
foreach $file(@files){


#Open the file and read data
#Die with grace if it fails
    open (FILE, "<$file") or die "Can't open $file: $!\n";
    @lines = <FILE>;
    close FILE;
#Open same file for writing, reusing STDOUT
    open (STDOUT, ">>$output") or die "Can't open $output $!\n";

    my $sql = 0;
    my $schoolid = 0;
    my $where = 0;
    my $whereStr = '';
    my $and = 0;
    for my $i (0...$#lines ) {
        $line = $lines[$i];
        $lineNum = $i + 1;
        if($line =~ /.*(sql|select).*select/i) {
            $sql = 1;
        }
        if($line =~ /mysql_query/i) {
            if($sql == 1 && $schoolid == 0) {
                print "$file: $lineNum\n";
                #(my $new = $line) =~ s/^[ \s\t]*/    /;
                #print "$whereStr".$new."\n";
            }
            $sql = 0;
            $schoolid = 0;
            $where = 0;
            $and = 0;
            $whereStr = '';
        }
        if($sql == 1) {
            if($line =~ /order/i) {
                $where = 0;
            }
            if($line =~ /where/i) {
                $where = 1;
            }
            if($where == 1) {
                (my $new = $line) =~ s/^[ \s\t]*/    /;
                $whereStr = "$whereStr" . $new;
                if($line =~ /$pattern/i) {
                    $schoolid = 1;
                }
            }
        }
    }
#Finish up
    close STDOUT;
}
