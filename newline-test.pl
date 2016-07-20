#!/usr/bin/perl
#use warnings;
use Tie::File;
use Scalar::Util qw(looks_like_number);

#my $start = 200;
#my $stop = 240;
#my $path = 'Reports/0/dailyfamilytransactions.php';
my $path;
my $start = 0;
my $stop = 0;
my $count = 0;
my $file;
my @lines;
my $width = '';

if(looks_like_number($ARGV[0])) {
    $start = $ARGV[0];
    $stop = $ARGV[1];
    my $file = $ARGV[2];
    fix_files($file);
}else{
    foreach $file (@ARGV) {
        fix_files($file);
    }
}

sub fix_files {
    my $header = 0;
    my $tableRow = 0;
    my $class;
    $path = $_[0];
    tie @array, 'Tie::File', $path or die "Can't open $path: $!\n";

    for (@array) {
        $count++;
        if($_ =~ /header_open/) {
            $header = 1;
        }
        if($start > 0 && $stop > $start) {
            if($count <  $start || $count > $stop) {
                next;
            }
        }
        s/(^[\s\t]*print\(".*)\\n("\);)/$1$2/;
        if($header == 1) {                                                                              
            # empty hrefs + return false
            s/(<A[^\>]*)href=(["'])\s*\2\s(.*onClick[^;]*;)(?:return\sfalse;)/$1$3/i; 

            #popwin
            s/^([\t\s\/]*)(?:[^\<]*)window\.open\(([^,]+,[^,]+),.*width=([0-9]+).*height=([0-9]+).*(\).*)/$1popwin\($3,$4,$2$5/; 
            s/if\(\!.*\.opener\)[\s\n\r]*.*\.opener\s*=\s*self;.*$//; 

            # gray background colors on TRs and <B> tags contained within the TR
            if($_ =~ /print.*\".*tr[^>]+(background-color:#cfcfcf|bgcolor=#cfcfcf)/i) {
                $tableRow = 1;
                if($_ =~ /tr[^>]+se-bold/i) {
                    $class = 'se-bg-gray';
                }else{
                    $class = 'se-bg-gray se-bold';
                }
                s/(background-color:#cfcfcf;?|bgcolor=#cfcfcf)//i;
                s/style=''//i;
                s/style=\s//i;
                if($_ =~ /tr[^>]+class=/i) {
                    s/(?<=tr[^>])class=(?:'([^']*)'|([^'][^\s]*))/class='$class $1$2' /i;
                }else{
                    s/(?<=tr\s)/$1class='$class' /i;
                }
            }
            if($_ =~ /\<\/tr\>/i) {
                $tableRow = 0;
            }
            if($tableRow == 1) {
                s/<b>//i;
                s/<\/\s?b>//i;
            }
            if($_ =~ /print.*\".*tr[^>]+(background-color:\$titlecolor|bgcolor=\$titlecolor)/i) {
                $class = 'se-bg';
                s/(background-color:\$titlecolor;?|bgcolor=\$titlecolor)//i;
                s/style=''//i;
                s/style=\s//i;
                if($_ =~ /tr[^>]+class=/i) {
                    s/(?<=tr[^>])class=(?:'([^']*)'|([^'][^\s]*))/class='$class $1$2' /i;
                }else{
                    s/(?<=tr\s)/$1class='$class' /i;
                }
            }
        }          

        # width attributes
        s/(\<tr.*)width=[1-9][0-9]{0,2}%/$1/i;
        if($_ =~ /width=/) {                                                                            
            if($_ =~ /^[^>]*style=/) {
                my ($width) = $_ =~ m/width=["']?([\$a-zA-Z0-9%\-\_]+)/i;
                s/width=(["']?)([\$a-zA-Z0-9%\-\_]+)\1//i;
                s/(.*print.*\".*\<(?:td|table).*)style=(["'])([^\2]+\2)/$1style=$2width:$width;$3/i;
            }else{
                s/(.*print.*\".*\<(?:td|table).*)width=(["']?)([\$a-zA-Z0-9%\-\_]+)\2/$1style='width:$3;'/i
            }
        }

        # align attr
        if($_ =~ /print\(\".*align=(center|right)/i && $_ !~ /<img/i) {
            if($_ =~ /align=center/i) {
                $class = 'center';
            }else{ 
                $class = 'right';
            }
            my ($tag) = $_ =~ m/<\K([^\s>]*)(?=[^>]*align=$class)/i;
            s/align=(center|right)//i;
            if($_ =~ /($tag)[^>]*class=/i) {
                s/$tag\[^>]*\Kclass=(?:'([^']*)'|([^'][^\s]*))/class='se-$class $1' /i;
            }else{
                s/$tag\K/ class='se-$class' /i;
            }
        }
    }
#Finish up
    untie @array;
}
