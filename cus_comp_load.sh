_comp_load ()
{
    local flag_fallback_default="" IFS=' 	
';
    local OPTIND=1 OPTARG="" OPTERR=0 opt;
    while getopts ':D' opt "$@"; do
        case $opt in 
            D)
                flag_fallback_default=set
            ;;
            *)
                echo "bash_completion: $FUNCNAME: usage error" 1>&2;
                return 2
            ;;
        esac;
    done;
    shift "$((OPTIND - 1))";
    local cmd=$1 cmdname=${1##*/} dir compfile;
    local -a paths;
    [[ -n $cmdname ]] || return 1;
    local backslash=;
    if [[ $cmd == \\* ]]; then
        cmd=${cmd:1};
        $(complete -p -- "$cmd" 2> /dev/null || echo false) "\\$cmd" && return 0;
        backslash=\\;
    fi;
    local REPLY pathcmd origcmd=$cmd;
    if pathcmd=$(type -P -- "$cmd"); then
        _comp_abspath "$pathcmd";
        cmd=$REPLY;
    fi;
    local -a dirs=();
	_comp_split -F : paths "$ZSH_BASH_COMPLETIONS_FALLBACK_PATH" && dirs+=("${paths[@]}");
    local IFS=' 	
';
    shift;
    local i prefix compspec;
    for prefix in "" _;
    do
        for i in ${!dirs[*]};
        do
            dir=${dirs[i]};
            if [[ ! -d $dir ]]; then
                unset -v 'dirs[i]';
                continue;
            fi;
            for compfile in "$prefix$cmdname" "$prefix$cmdname.bash";
            do
                compfile="$dir/$compfile";
                if [[ -d $compfile ]]; then
                    [[ $compfile == */.?(.) ]] || echo "bash_completion: $compfile: is a directory" 1>&2;
                else
                    if [[ -e $compfile ]] && . "$compfile" "$cmd" "$@"; then
                        if compspec=$(complete -p -- "$cmd" 2> /dev/null); then
                            [[ -n $backslash ]] && eval "$compspec \"\$backslash\$cmd\"";
                            [[ $origcmd != */* ]] && ! complete -p -- "$origcmd" &> /dev/null && eval "$compspec \"\$origcmd\"";
                            return 0;
                        fi;
                        if [[ $cmdname != "$cmd" ]] && compspec=$(complete -p -- "$cmdname" 2> /dev/null); then
                            [[ $cmd == /* ]] && eval "$compspec \"\$cmd\"";
                            return 0;
                        fi;
                    fi;
                fi;
            done;
        done;
    done;
    [[ -v _comp_xspecs[$cmdname] || -v _xspecs[$cmdname] ]] && complete -F _comp_complete_filedir_xspec "$cmdname" "$backslash$cmdname" && return 0;
    if [[ -n $flag_fallback_default ]]; then
        complete -F _comp_complete_minimal -- "$origcmd" && return 0;
    fi;
    return 1
}
