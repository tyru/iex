#!/bin/sh


true=":"
false="/bin/false"
success=0
failure=1



usage() {
    progname=`basename $0`

    cat <<EOM
    Usage
        $progname [{options}] [--] [{script} [{file}]]

    Options
        -h
            Show help.
EOM

    exit 1
}

die() {
    echo "$@" >&2
    exit 1
}

decho() {
    $verbose && echo "debug:" "$@" >&2
}

add_tempfiles() {
    [ $# = 0 ] && return
    register_remove_all_tempfiles
    for f in "$@"; do
        all_tempfiles="$all_tempfiles '$f'"
    done
}

is_registered_remove_all_tempfiles="$false"
register_remove_all_tempfiles() {
    $is_registered_remove_all_tempfiles || {
        trap 'remove_all_tempfiles' 0 HUP INT QUIT TERM
        is_registered_remove_all_tempfiles="$true"
    }
}

remove_all_tempfiles() {
    x=$?
    $is_registered_remove_all_tempfiles && {
        for t in "$all_tempfiles"; do
            decho "cleaning up $f..."
            rm -f "$t"
        done
    }
    exit $x
}

get_clone_tempfile() {
    tempfile=`tempfile`
    add_tempfiles "$tempfile"

    if [ $# = 0 ]; then
        cat
    else
        cat "$@"
    fi >"$tempfile" || exit $?
    echo "$tempfile"
}

get_script() {
    cat "$@" || exit $?
    $auto_write && echo "write"
    $auto_quit  && echo "quit!"
}

run_file() {
    [ $# -ge 2 ] || die "invalid args"

    script="$1"
    shift
    decho "script: [$script]"

    for f in "$@"; do
        t=`get_clone_tempfile "$f"`
        echo "$script" | $EX "$t"
        cat "$t"
    done
}

build_ex_command() {
    EX="ex"
    if $compatible; then
        EX="$EX -N"
    fi
    if ! $load_conf; then
        EX="$EX -u NORC --noplugin"
    fi
    if $quiet; then
        EX="$EX -"
    fi
}

main() {
    build_ex_command
    case $# in
        0) quiet="$false"; build_ex_command; exec $EX ;;
        1) get_script "$1" | $EX ;;
        *) out=`get_script "$1"`; shift; run_file "$out" "$@" ;;
    esac
}


verbose="$false"
auto_write="$true"
auto_quit="$true"
compatible="$true"
load_conf="$false"
quiet="$false"


while getopts hvWQclq opt; do
    case $opt in
        v) verbose="$true" ;;
        W) auto_write="$false" ;;
        Q) auto_quit="$false" ;;
        C) compatible="$false" ;;
        l) load_conf="$true" ;;
        q) quiet="$true" ;;
        h) usage ;;
        ?) usage ;;
    esac
done
shift `expr $OPTIND - 1`


main "$@"