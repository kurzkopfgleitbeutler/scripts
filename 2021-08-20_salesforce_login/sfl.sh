#!/bin/sh
scope ()
(

    # ---------- VARIABLES -----------

    # use $1, $2 etc after ARGPARSE under ARGUMENTS

    script_path="$(dirname "$(readlink -e -- "$0")")"
    script_name="$(basename "$0")"
    num_args=1
    usage="$script_name [-q] [-l] ORGALIAS"
    tagline="automatically open an sfdx authenticated org in browser"
    logfile_name=/dev/null
    unset quiet

    browser="chromium chromium-browser firefox-wayland firefox"

    # -------- FLAG PARSING ----------

    while getopts 'lq' c
    do
	case $c in
	    l) logfile_name="log_${script_name%.*}.txt"; shift ;;
	    q) quiet=1; shift ;;
	    --) shift; break ;;
	    *) printf "%b\n" "[ERROR] unsupported flag: $1\n$usage"; exit ;;
	esac
    done
    if [ "$#" -ne "$num_args" ]
    then
	echo "[ERROR] wrong number of arguments: should be $num_args\n$usage"
	exit
    fi

    # ---------- ARGUMENTS -----------



    # ---------- FUNCTIONS -----------

    hello () {
	printf "%b\n" ""	# newline between log entries
	printf "%b\n" "[BEGIN]\n$(date -Iseconds)\n$usage\n$script_path/$script_name\n$usage"
	printf "%b\n" "$tagline"
    }
    log () {
	if [ -n "$quiet" ]
	then
	    "$@" >> $logfile_name
	else
	    "$@" | tee -a $logfile_name
	fi
    }

    # ---------- MAIN ----------------

    main () {
	hello

	(
	    f=$(sfdx force:org:open -r -u "$1")
	    url=${f#*URL: }

	    log printf "%b\n" "$url"

	    for app in $browser
	    do
		if [ -n "$(which $app)" ]
		then
		    $app "$url"
		    break
		fi
	    done
	) >/dev/null 2>&1 &

    }
    log main $@
)
scope $@

# ---------- COMMENTS ------------
