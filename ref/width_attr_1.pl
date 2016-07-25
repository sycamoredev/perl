#!/usr/bin/perl
my @files = glob "/usr/local/apache/htdocs/jon/ss/*.php";
push @files, glob "/usr/local/apache/htdocs/jon/ss/*.inc";
push @files, glob "/usr/local/apache/htdocs/jon/ss/*.tab";
push @files, glob "/usr/local/apache/htdocs/jon/ss/admissions/*.php";
push @files, glob "/usr/local/apache/htdocs/jon/ss/admissions/*.inc";
push @files, glob "/usr/local/apache/htdocs/jon/ss/admissions/*.tab";
push @files, glob "/usr/local/apache/htdocs/jon/ss/Reports/0/*.php";
push @files, glob "/usr/local/apache/htdocs/jon/ss/Reports/0/*.inc";
push @files, glob "/usr/local/apache/htdocs/jon/ss/Reports/0/*.tab";
#for (0..$#files){
      #$files[$_] =~ s/\.txt$//;
  #}
#my @files = glob "$dir
my $count = 0;
foreach $file(@files){
    my $flag = 0;
    if($count >= 200) {
        last;
    }


#Open the file and read data
#Die with grace if it fails
    open (FILE, "<$file") or die "Can't open $file: $!\n";
    @lines = <FILE>;
    close FILE;
#Open same file for writing, reusing STDOUT
    open (STDOUT, ">$file") or die "Can't open $file: $!\n";

    my $style = 0;
    for ( @lines ) {
        if($_ =~ /width=/) {
            $flag = 1;
            s/(\<tr.*)width=[1-9][0-9]{0,2}%/$1/i;
            if($_ =~ /^[^>]*style=/) {
                my ($width) = $_ =~ m/width=["']?([\$a-zA-Z0-9%\-\_]+)/i;
                s/width=(["']?)([\$a-zA-Z0-9%\-\_]+)\1//i;
                s/(.*print.*\".*\<(?:td|table).*)style=(["'])([^\2]+\2)/$1style=$2width:$width;$3/i;
            }else{
                s/(.*print.*\".*\<(?:td|table).*)width=(["']?)([\$a-zA-Z0-9%\-\_]+)\2/$1style='width:$3;'/i
            }
        }
        print;
    }
#Finish up
    close STDOUT;
    if($flag == 1) {
        $count++;
    }
}
