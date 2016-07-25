# !/bin/bash


inc_functions() {
    # if no arguments are passed
    if [ $# -eq 0 ]; then
        echo "No file name found \n"
        exit 1
    else 
        # FILE = 1st arg
        FILE="$1"
        # TYPE = optional 2nd arg
        if [ -z "$2" ]; then
            TYPE="txt"
        else
            TYPE="$2"
        fi

        ## Handle symlinks

        SOURCE="${BASH_SOURCE[0]}"

        # while current script location is a symlink
        while [ -h "$SOURCE" ]; do 
            DIR="$( cd "$( dirname "$SOURCE" )" && pwd )"
            SOURCE="$(readlink "$SOURCE")"
            # if $SOURCE was a relative symlink, we need to resolve it 
            # relative to the path where the symlink file was located
            [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" 
        done

        DIR="$( cd "$( dirname "$SOURCE" )" && pwd )"

        ##

        if [ $TYPE == 'txt' ]; then
            # cat file and echo blank line for aesthetics
            perl "$DIR/inc_functions.pl" $FILE txt && cat inc_functions.txt && echo ""
        else
            # open vim and run vim commands to open quickfix window and select quickfix file
            perl "$DIR/inc_functions.pl" $FILE qfx && vim $FILE +"copen | cfile inc_functions.qfx"
        fi

    fi
}
