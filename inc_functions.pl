#!/usr/bin/perl

sub uniq {
    my %seen;
    grep !$seen{$_}++, @_ 
}
# Receive arguments from .sh script
my $file = $ARGV[0];
my $type = $ARGV[1];
     

# Open target file($file) into $phpInput buffer
open my $phpInput, '<', $file or die "can't open $file: $!\n";
my @incFiles;

# Skip inc files with no 'mysql' queries
# Add more if necessary
my @skipFiles = ('pdo.inc','crumb.inc','tab.inc', 'array.inc', 'alphabetbar.inc', 'simpleimage.inc', 'phone.inc' );

# Loop over each line in $file
while (<$phpInput>) {
    chomp;
    # Add required filenames to @incFiles array
    # example: require_once('classes.inc');
    if(/require_once\(["'] *([A-Za-z\._0-9\/-]+\.inc) *["']\);/g) {
        # $1-$9 are automatically populated by regex groups in matching operations
        push @incFiles, $1;
    }
}
# Get length of file.
# "$." contains the current line number of the last filehandle accessed
$totalLines = $.;
close $phpInput;

# skip specific files
my %h;

# Initialise the hash using a slice
@h{@skipFiles} = undef;

# rewrite @incFiles with @skipFiles removed
@incFiles = grep {not exists $h{$_}} @incFiles;

my @incFunctions;



# "$|" forces the STDOUT buffer to flush before receiving a newline character
# This effectively allows us to edit the terminal output even after it appears on screen
local $| = 1;
my $totalInc = scalar @incFiles;
print "Searching $totalInc '.inc' files...0/$totalInc";

my $count = 0;
foreach(@incFiles) {
    # Move cursor back correct number of characters
    print ("\b" x (length($count) + 1 + length($totalInc)));

    # Print updated numbers
    $count++;
    print (($count)."/$totalInc");

    # Open current .inc file
    open my $incInput, '<', $_ or die "\nCan't open $_ $!\n";
    while (<$incInput>) {
        chomp;

        # find function declarations
        if(/function +([A-Za-z_0-9-]+)\b/g) {
            push @incFunctions, $1;
        }
    }
    close $incInput;
}
$| = 0;
print "\n";

# Skip specific functions that are commonly used,
# add more if necessary.
my @skipFunctions = ('Display', 'htmlQuotes');

# clear out hash
%h = undef;

# Initialise the hash using a slice
@h{@skipFunctions} = undef;

# remove duplicate function names
@incFunctions = uniq(@incFunctions);
# rewrite @incFunctions with @skipFunctions removed
@incFunctions = grep {not exists $h{$_}} @incFunctions;


print "Found ".scalar @incFunctions." unique function names.\n";

$| = 1;
print "Searching $file for matches...0/$totalLines";

# foundFunctions will contain the line numbers and function names of any
# .inc functions that are matched in the .php file
my @foundFunctions;

# open target file again
open my $phpInput2, '<', $file or die "can't open $file: $!";
while (<$phpInput2>) {
    chomp;
    # current line of file
    $line = $_;

    # "$." is the current line number
    print ("\b" x (length($.-1) + 1 + length($totalLines)));
    print (($.)."/$totalLines");

    # check current line against each inc function(case insensitive)
    foreach(@incFunctions) {
        # Example: current function name =  getData
        # Matches:
        #   getData(
        #   getdata(
        # Doesn't match:
        #   getData (
        #   nowGetData(
        #   getData2(
        if($line =~ /\b$_\(/i) {
            if($type eq 'txt') {
                push @foundFunctions, "$.: $_";
            }else{
                push @foundFunctions, "$file:$.:$_";
            }
        }
    }
}
close $phpInput2;

print "\n";
$| = 0;

print "Found ".scalar @foundFunctions." matches.\n";

# Write to qfx or txt file
open(my $output, '>', "inc_functions.$type") or die "Could not open file 'inc_functions.$type' $!\n";
my $foundNames = join "\n", @foundFunctions;
print $output $foundNames;
close $output;
