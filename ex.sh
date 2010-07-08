#!/bin/sh


true=":"
false="/bin/false"
success=0
failure=1

EX="ex -N -u NORC --noplugin -"



usage() {
    progname=`basename $0`

    cat <<EOM
    Usage
        $progname [{options}] [--] [{file} [{script}]]

    Options
        -h
            Show help.
EOM

    exit 1
}

decho() {
    $verbose && echo "debug:" "$@" >&2
}

main() {
    [ $# = 0 -o "$1" = - ] && decho "Input file:"

    # 「cat "$1"」だと空だった場合「''」を開こうとするのでまずい
    # 「cat $1」だとファイル名が空白を持っていた場合に2つのファイルと認識されるのでまずい
    tempfile=`tempfile`
    if [ $0 = 0 ]; then
    else
        cat_file="cat '$1'"
    fi
    $cat_file >"$tempfile" || exit $?

    [ $# = 0 -o "$1" = - ] && decho "Input file - end."

    [ $# -le 1 -o "$2" = - ] && decho "Input script:"

    {
        # 同上
        cat `echo "$2"`
        $auto_write && echo "write"
        $auto_quit  && echo "quit"
        [ $# -le 1 -o "$2" = - ] && decho "Input script - end."
    } | $EX "$tempfile"
    cat "$tempfile"
}


verbose="$false"
auto_write="$true"
auto_quit="$true"


while getopts hvVwWqQ opt; do
    case $opt in
        v) verbose="$true" ;;
        V) verbose="$false" ;;
        w) auto_write="$true" ;;
        W) auto_write="$false" ;;
        q) auto_quit="$true" ;;
        Q) auto_quit="$false" ;;
        h) usage ;;
        ?) usage ;;
    esac
done
shift `expr $OPTIND - 1`


main "$@"