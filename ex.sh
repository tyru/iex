#!/bin/bash


true=":"
false="/bin/false"
success=0
failure=1



usage() {
    local progname=`basename $0`

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

all_tempfiles=()
add_tempfiles() {
    [ $# = 0 ] && return
    register_remove_all_tempfiles
    for f in "$@"; do
        all_tempfiles=($all_tempfiles "$f")
    done
}

is_registered_remove_all_tempfiles="$false"
register_remove_all_tempfiles() {
    $is_registered_remove_all_tempfiles || {
        trap 'remove_all_tempfiles' HUP INT QUIT TERM
        is_registered_remove_all_tempfiles="$true"
    }
}

remove_all_tempfiles() {
    local x=$?
    $is_registered_remove_all_tempfiles && {
        for t in "$all_tempfiles"; do
            decho "cleaning up $f..."
            rm -f "$t"
        done
    }
    exit $x
}

get_clone_tempfile() {
    local tempfile=`tempfile`
    add_tempfiles "$tempfile"

    if [ $# = 0 ]; then
        cat
    else
        cat "$@"
    fi >"$tempfile" || exit $?
    echo "$tempfile"
}

get_tempfile() {
    local tempfile=`tempfile`
    add_tempfiles "$tempfile"

    echo "$tempfile"
}

get_script() {
    cat "$@" || exit $?
    $auto_write && echo "write"
    $auto_quit  && echo "quit!"
}

run_file() {
    [ $# -ge 2 ] || die "invalid args"

    local script="$1"
    shift
    decho "script: [$script]"

    local f
    for f in "$@"; do
        local t=`get_clone_tempfile "$f"`
        decho "tempfile: [$t]"
        echo "$script" | $EX "$t"
        cat "$t"
    done
}

eval_code() {
    local files=()
    local f
    for f in "$@"; do
        files=($files "$f")
    done
    [ ${#files[*]} = 0 ] && {
        local t=`get_tempfile`
        cat >"$t"
        files=($t)
    }
    local script=$(
        for e in $eval_sources; do
            echo "$e"
        done
        $auto_write && echo "write"
        $auto_quit && echo "quit!"
    )
    run_file "$script" "$files"
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
    if [ ${#eval_sources[*]} != 0 ]; then
        eval_code "$@"
        return 0
    fi
    case $# in
        0) quiet="$false"; build_ex_command; exec $EX ;;
        1) get_script "$1" | $EX ;;
        *) local out=`get_script "$1"`; shift; run_file "$out" "$@" ;;
    esac
}


verbose="$false"
auto_write="$true"
auto_quit="$true"
compatible="$true"
load_conf="$false"
quiet="$false"
eval_sources=()


while getopts hvWQclqe: opt; do
    case $opt in
        v) verbose="$true" ;;
        W) auto_write="$false" ;;
        Q) auto_quit="$false" ;;
        C) compatible="$false" ;;
        l) load_conf="$true" ;;
        q) quiet="$true" ;;
        e) eval_sources=($eval_sources "$OPTARG") ;;
        h) usage ;;
        ?) usage ;;
    esac
done
shift `expr $OPTIND - 1`


main "$@"